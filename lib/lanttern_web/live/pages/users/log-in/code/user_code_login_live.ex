defmodule LantternWeb.UserCodeLoginLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm py-20">
      <h1 class="font-display font-black text-5xl leading-tight">
        Lanttern<br />sign in
      </h1>
      <p class="mt-10 text-base">
        {gettext("Enter the 6-digit code sent to %{email}", email: @email)}
      </p>
      <.form
        for={@form}
        id="code_form"
        phx-mounted={JS.focus_first()}
        action={~p"/users/log-in"}
        class="mt-10"
      >
        <.input
          field={@form[:email]}
          type="hidden"
          value={@form[:email].value}
        />
        <.input
          field={@form[:code]}
          type="access_code"
          required
          maxlength="6"
          pattern="[0-9]{6}"
          placeholder="______"
        />
        <div class="flex items-center gap-2 mt-2">
          <.input
            field={@form[:remember_me]}
            type="checkbox"
            label={gettext("Keep me signed in")}
            class="flex-1"
          />
          <.icon_button
            type="submit"
            name="hero-arrow-right-mini"
            sr_text="Sign in"
            rounded
            theme="ghost"
          />
        </div>
      </.form>
      <p class="mt-10 text-base text-ltrn-subtle">
        {gettext(
          "Can't find the code? Check your spam folder and ensure there's a Lanttern account for the provided email."
        )}
      </p>
      <.action
        type="button"
        theme="subtle"
        phx-click="resend_code"
        icon_name="hero-arrow-path-mini"
        class="mt-10"
      >
        {gettext("Resend code")}
      </.action>
      <.action
        type="link"
        theme="subtle"
        href={~p"/users/log-in"}
        icon_name="hero-arrow-uturn-left-mini"
        class="mt-10"
      >
        {gettext("Sign in using a different email")}
      </.action>
      <LantternWeb.Layouts.flash_group flash={@flash} />
    </div>
    """
  end

  def mount(params, _session, socket) do
    email =
      case Map.get(params, "email") do
        "" -> nil
        email when is_binary(email) -> URI.decode(email)
        _ -> nil
      end

    socket =
      if email do
        form =
          to_form(%{"email" => email, "code" => "", "remember_me" => false}, as: "access_code")

        socket
        |> assign(:email, email)
        |> assign(:form, form)
      else
        socket
        |> put_flash(:error, gettext("Invalid access to this page."))
        |> push_navigate(to: ~p"/users/log-in")
      end

    {:ok, socket}
  end

  def handle_event("resend_code", _params, socket) do
    if user = Identity.get_user_by_email(socket.assigns.email) do
      case Identity.deliver_login_instructions(user) do
        {:ok, _} ->
          {:noreply, put_flash(socket, :info, gettext("New code sent to your email."))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to send code. Please try again."))}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, gettext("User not found."))
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end
end
