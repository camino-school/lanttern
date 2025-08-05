defmodule LantternWeb.UserAuth do
  @moduledoc """
  User authentication and authorization helpers.
  """
  use LantternWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  use Gettext, backend: Lanttern.Gettext
  alias Lanttern.Identity
  alias Lanttern.Identity.User

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_lanttern_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.

  For the specific case when there's no profile
  linked to the user, we log the user out.
  """
  def log_in_user(conn, user, params \\ %{}) do
    case check_current_profile(user) do
      {:ok, user} ->
        token = Identity.generate_user_session_token(user)
        user_return_to = get_session(conn, :user_return_to)

        conn
        |> renew_session()
        |> put_token_in_session(token)
        |> maybe_write_remember_me_cookie(token, params)
        |> redirect(to: user_return_to || signed_in_path(conn))

      _ ->
        conn
        |> put_flash(
          :error,
          "There's no profile linked to your user. Check with your Lanttern admin."
        )
        |> log_out_user()
    end
  end

  defp check_current_profile(%{current_profile_id: nil, is_root_admin: is_root_admin} = user) do
    # if there's no current_profile_id, list profiles and use first result
    case {Identity.list_profiles(user_id: user.id, only_active: true), is_root_admin} do
      {[profile | _rest], _} ->
        Identity.update_user_current_profile_id(user, profile.id)

      {[], true} ->
        # if user does not have a profile but is root admin, allow login anyway
        # (user can use the admin area to create and link profiles)
        {:ok, user}

      {[], false} ->
        :error
    end
  end

  defp check_current_profile(user), do: {:ok, user}

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Identity.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      LantternWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)

    case user_token && Identity.get_user_by_session_token(user_token) do
      # when user current profile is a deactivated staff member,
      # remove it from user before moving forward
      %User{current_profile: %{type: "staff", deactivated_at: %DateTime{}}} =
          user ->
        {:ok, user} = Identity.update_user_current_profile_id(user, nil)
        Map.put(user, :current_profile, nil)

      user ->
        user
    end
    |> case do
      # if for some reason we reach this point
      # without a user profile, log out
      %User{current_profile: nil, is_root_admin: false} ->
        conn
        |> log_out_user()

      # if for some reason we reach this point
      # without a current school cycle, log out
      %User{current_profile: %{current_school_cycle: nil}, is_root_admin: false} ->
        conn
        |> log_out_user()

      user ->
        assign(conn, :current_user, user)
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  defmodule InvalidGoogleCSRFTokenError do
    @moduledoc "Error raised when Google CSRF token is invalid."

    defexception [:message, :plug_status]

    @impl true
    def exception(message, plug_status \\ 403) do
      %InvalidGoogleCSRFTokenError{message: message, plug_status: plug_status}
    end
  end

  @doc """
  Verify Google's CSRF token.
  Reference: https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
  """
  def verify_google_csrf_token(conn, _opts) do
    csrf_token_cookie = conn.req_cookies |> Map.get("g_csrf_token", nil)

    if is_nil(csrf_token_cookie) do
      raise InvalidGoogleCSRFTokenError, "No CSRF token in Cookie."
    end

    csrf_token_body = conn.params |> Map.get("g_csrf_token", nil)

    if is_nil(csrf_token_cookie) do
      raise InvalidGoogleCSRFTokenError, "No CSRF token in post body."
    end

    if csrf_token_cookie != csrf_token_body do
      raise InvalidGoogleCSRFTokenError, "Failed to verify double submit cookie."
    end

    conn
  end

  @doc """
  Disconnects existing sockets for the given tokens.
  """
  def disconnect_sessions(tokens) do
    Enum.each(tokens, fn %{token: token} ->
      LantternWeb.Endpoint.broadcast(user_session_topic(token), "disconnect", %{})
    end)
  end

  defp user_session_topic(token), do: "users_sessions:#{Base.url_encode64(token)}"

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated_` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule LantternWeb.PageLive do
        use LantternWeb, :live_view

        on_mount {LantternWeb.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{LantternWeb.UserAuth, :ensure_authenticated_staff_member}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket
    |> mount_current_user(session)
    |> ensure_authenticated()
  end

  def on_mount(:ensure_authenticated_staff_member, _params, session, socket) do
    socket
    |> mount_current_user(session)
    |> ensure_authenticated("staff")
  end

  def on_mount(:ensure_authenticated_student, _params, session, socket) do
    socket
    |> mount_current_user(session)
    |> ensure_authenticated("student")
  end

  def on_mount(:ensure_authenticated_guardian, _params, session, socket) do
    socket
    |> mount_current_user(session)
    |> ensure_authenticated("guardian")
  end

  def on_mount(:ensure_authenticated_student_or_guardian, _params, session, socket) do
    socket
    |> mount_current_user(session)
    |> ensure_authenticated(["student", "guardian"])
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Identity.get_user_by_session_token(user_token)
      end
    end)
  end

  defp ensure_authenticated(socket) do
    case socket.assigns.current_user do
      %User{} ->
        {:cont, socket}

      _ ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, gettext("You must log in to access this page."))
          |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

        {:halt, socket}
    end
  end

  defp ensure_authenticated(socket, profile_types) when is_list(profile_types) do
    case socket.assigns.current_user do
      %User{current_profile: %{type: profile_type}} ->
        if profile_type in profile_types do
          {:cont, socket}
        else
          ensure_authenticated_redirect(socket)
        end

      _ ->
        ensure_authenticated_redirect(socket)
    end
  end

  defp ensure_authenticated(socket, profile_type) do
    case socket.assigns.current_user do
      %User{current_profile: %{type: ^profile_type}} ->
        {:cont, socket}

      _ ->
        ensure_authenticated_redirect(socket)
    end
  end

  defp ensure_authenticated_redirect(socket) do
    case socket.assigns.current_user do
      %User{current_profile: %{type: "staff"}} ->
        socket =
          socket
          |> Phoenix.LiveView.redirect(to: ~p"/dashboard")

        {:halt, socket}

      %User{current_profile: %{type: "student"}} ->
        socket =
          socket
          |> Phoenix.LiveView.redirect(to: ~p"/student")

        {:halt, socket}

      %User{current_profile: %{type: "guardian"}} ->
        socket =
          socket
          |> Phoenix.LiveView.redirect(to: ~p"/guardian")

        {:halt, socket}

      _ ->
        socket =
          socket
          |> Phoenix.LiveView.put_flash(:error, gettext("You must log in to access this page."))
          |> Phoenix.LiveView.redirect(to: ~p"/users/log-in")

        {:halt, socket}
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log-in")
      |> halt()
    end
  end

  @doc """
  Used for routes that require the user to have accepted the privacy policy.

  Use after `require_authenticated_user/2` (`current_user` assign is expected).
  """

  def require_privacy_policy_accepted(%{assigns: %{current_user: user}} = conn, _opts) do
    if user_privacy_policy_accepted_valid?(user) do
      conn
    else
      conn
      |> maybe_store_return_to()
      |> redirect(to: ~p"/accept_privacy_policy")
      |> halt()
    end
  end

  @doc """
  Used for routes that require the user to not to have accepted the privacy policy.
  """
  def redirect_if_privacy_policy_accepted(%{assigns: %{current_user: user}} = conn, _opts) do
    if user_privacy_policy_accepted_valid?(user) do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @current_privacy_policy_date ~U[2024-04-03 00:00:00.00Z]

  defp user_privacy_policy_accepted_valid?(
         %{privacy_policy_accepted_at: %DateTime{} = accepted_at} = %User{}
       ) do
    if DateTime.compare(accepted_at, @current_privacy_policy_date) == :gt, do: true, else: false
  end

  defp user_privacy_policy_accepted_valid?(_user), do: false

  @doc """
  Used for routes that require root admin permissions.
  Must be used after `require_authenticated_user/2` (current_user required)
  """
  def require_root_admin(%{assigns: %{current_user: current_user}} = conn, _opts) do
    if current_user.is_root_admin do
      conn
    else
      conn
      |> put_flash(:error, "You must have root admin privileges to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/dashboard"
end
