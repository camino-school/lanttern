defmodule LantternWeb.UserLoginLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center ltrn-bg-main">
      <div class="max-w-sm px-10 sm:px-0 py-20">
        <h1 class="font-display font-black text-5xl text-ltrn-darkest leading-tight">
          Lanttern<br />sign in
        </h1>
        <p class="mt-10 text-lg">
          Check if your school is using
          <a href={~p"/"} class="font-display font-bold underline hover:text-ltrn-subtle">Lanttern</a>
          and your email is registered before signing in.
        </p>
        <.form
          for={@form}
          id="login_form_access_code"
          phx-update="ignore"
          phx-submit="submit_access_code"
          class="flex gap-2 mt-10"
        >
          <.input field={@form[:email]} type="email" label={gettext("Email")} required class="flex-1" />
          <.icon_button
            type="submit"
            name="hero-arrow-right-mini"
            sr_text="Sign in"
            rounded
            theme="ghost"
            class="mt-7"
          />
          <%!-- <div class="flex justify-end mt-6">
          <.action type="submit" theme="primary" size="md" icon_name="hero-arrow-right">
            {gettext("Send login code")}
          </.action>
        </div> --%>
        </.form>
        <div class="flex items-center gap-2 my-10">
          <hr class="flex-1 border-ltrn-light" />
          {gettext("or")}
          <hr class="flex-1 border-ltrn-light" />
        </div>
        <div id="g_id_signin_container" phx-update="ignore">
          <script src="https://accounts.google.com/gsi/client" async>
          </script>
          <div
            id="g_id_onload"
            data-client_id={@google_client_id}
            data-context="signin"
            data-ux_mode="popup"
            data-login_uri={"#{LantternWeb.Endpoint.static_url()}/users/google_sign_in"}
            data-nonce=""
            data-auto_prompt="false"
          >
          </div>
          <div
            class="g_id_signin"
            data-type="standard"
            data-shape="pill"
            data-theme="outline"
            data-text="signin_with"
            data-size="large"
            data-logo_alignment="left"
          >
          </div>
        </div>
      </div>
      <div class="pb-10">
        <.logo size="md" />
      </div>
    </div>
    <LantternWeb.Layouts.flash_group flash={@flash} />
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    google_client_id =
      Application.fetch_env!(:lanttern, LantternWeb.UserAuth)
      |> Keyword.get(:google_client_id)

    socket =
      socket
      |> assign(form: form)
      |> assign(google_client_id: google_client_id)

    {:ok, socket, temporary_assigns: [form: form]}
  end

  def handle_event("submit_access_code", %{"user" => %{"email" => email}}, socket) do
    socket =
      case Identity.request_login_code(email) do
        {:ok, :sent} ->
          socket
          |> push_navigate(to: ~p"/users/log-in/code?email=#{URI.encode(email)}")

        {:error, :rate_limited} ->
          socket
          |> put_flash(:error, gettext("Please wait before requesting another login code."))

        {:error, _reason} ->
          socket
          |> put_flash(:error, gettext("An error occurred. Please try again."))
      end

    {:noreply, socket}
  end
end
