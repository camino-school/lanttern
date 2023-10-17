defmodule LantternWeb.UserLoginLive do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Sign in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/users/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>

      <div id="g_id_signin_container" class="flex justify-center mt-10" phx-update="ignore">
        <script src="https://accounts.google.com/gsi/client" async>
        </script>
        <div
          id="g_id_onload"
          data-client_id={@google_client_id}
          data-context="signin"
          data-ux_mode="popup"
          data-login_uri={~p"/users/google_sign_in"}
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
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
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
end
