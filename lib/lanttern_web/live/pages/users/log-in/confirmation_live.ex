defmodule LantternWeb.UserLoginLive.Confirmation do
  use LantternWeb, :live_view

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm py-20">
      <h1 class="font-display font-black text-5xl leading-tight">
        Lanttern<br />sign in
      </h1>
      <p class="my-10 text-base">
        {gettext("Hello %{email}!", email: @user.email)}
      </p>

      <%!-- <.form
        :if={!@user.confirmed_at}
        for={@form}
        id="confirmation_form"
        phx-mounted={JS.focus_first()}
        phx-submit="submit"
        action={~p"/users/log-in?_action=confirmed"}
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
        <.card_base class="flex flex-col items-center gap-4 p-6">
          <.action
            type="submit"
            name={@form[:remember_me].name}
            value="true"
            phx-disable-with={gettext("Signing in...")}
            size="md"
            theme="primary"
            icon_name="hero-computer-desktop"
          >
            {gettext("Keep me signed in on this device")}
          </.action>
          <div>{gettext("or")}</div>
          <.action
            type="submit"
            phx-disable-with={gettext("Signing in...")}
            size="md"
            theme="primary"
            icon_name="hero-clock"
          >
            {gettext("Sign in only this time")}
          </.action>
        </.card_base>
      </.form> --%>

      <.form
        for={@form}
        id="login_form"
        phx-submit="submit"
        phx-mounted={JS.focus_first()}
        action={
          if @user.confirmed_at,
            do: ~p"/users/log-in",
            else: ~p"/users/log-in?_action=confirmed"
        }
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
        <%= if @current_user do %>
          <.button phx-disable-with="Signing in..." class="btn btn-primary w-full">
            Log in
          </.button>
        <% else %>
          <.card_base class="flex flex-col items-center gap-4 p-6">
            <.action
              type="submit"
              name={@form[:remember_me].name}
              value="true"
              phx-disable-with="Signing in..."
              size="md"
              theme="primary"
              icon_name="hero-computer-desktop"
            >
              {gettext("Keep me signed in on this device")}
            </.action>
            <div>{gettext("or")}</div>
            <.action
              type="submit"
              phx-disable-with="Signing in..."
              size="md"
              theme="primary"
              icon_name="hero-clock"
            >
              {gettext("Sign in only this time")}
            </.action>
          </.card_base>
        <% end %>
      </.form>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    if user = Identity.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("Sign in link is invalid or it has expired."))
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
