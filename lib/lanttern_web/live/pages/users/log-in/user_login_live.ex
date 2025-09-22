defmodule LantternWeb.UserLoginLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm py-20">
      <h1 class="font-display font-black text-5xl leading-tight">
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
      <%!-- <.header class="text-center">
        Sign in to account
        <:subtitle>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log-in"} phx-update="ignore">
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
       --%>
      <LantternWeb.Layouts.flash_group flash={@flash} />
    </div>
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
