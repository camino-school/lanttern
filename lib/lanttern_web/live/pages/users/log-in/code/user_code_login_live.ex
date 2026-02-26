defmodule LantternWeb.UserCodeLoginLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity

  def render(assigns) do
    ~H"""
    <div class="ltrn-bg-main">
      <div class="mx-auto max-w-sm px-10 sm:px-0 py-20">
        <h1 class="font-display font-black text-5xl text-ltrn-darkest leading-tight">
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
          phx-click="resend_code"
          icon_name={if !@timer_active, do: "hero-arrow-path-mini"}
          class="mt-10"
          disabled={@timer_active}
        >
          <%= if @timer_active do %>
            {gettext("Resend code in %{seconds} seconds", seconds: @countdown_seconds)}
          <% else %>
            {gettext("Resend code")}
          <% end %>
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
        |> assign(:countdown_seconds, 0)
        |> assign(:timer_active, false)
        |> assign(:timer_ref, nil)
        |> check_existing_rate_limit()
      else
        socket
        |> put_flash(:error, gettext("Invalid access to this page."))
        |> push_navigate(to: ~p"/users/log-in")
      end

    {:ok, socket}
  end

  def handle_event("resend_code", _params, socket) do
    email = socket.assigns.email

    socket =
      case Identity.request_login_code(email) do
        {:ok, :sent} ->
          socket
          |> put_flash(:info, gettext("New code sent to your email."))
          |> start_rate_limit_timer()

        {:error, :rate_limited} ->
          case Identity.get_rate_limit_remaining(email) do
            {:ok, remaining_seconds} when is_integer(remaining_seconds) ->
              socket
              |> put_flash(
                :error,
                gettext("Please wait %{seconds} seconds before requesting another code.",
                  seconds: remaining_seconds
                )
              )
              |> assign(:countdown_seconds, remaining_seconds)
              |> assign(:timer_active, true)
              |> start_countdown_timer()

            _ ->
              socket
              |> put_flash(:error, gettext("Please wait before requesting another login code."))
          end

        {:error, _reason} ->
          socket
          |> put_flash(:error, gettext("Failed to send code. Please try again."))
      end

    {:noreply, socket}
  end

  def handle_info(:countdown_tick, socket) do
    countdown_seconds = socket.assigns.countdown_seconds

    if countdown_seconds > 1 do
      socket =
        socket
        |> assign(:countdown_seconds, countdown_seconds - 1)
        |> schedule_countdown_tick()

      {:noreply, socket}
    else
      socket =
        socket
        |> assign(:countdown_seconds, 0)
        |> assign(:timer_active, false)
        |> cancel_timer()

      {:noreply, socket}
    end
  end

  defp start_rate_limit_timer(socket) do
    email = socket.assigns.email

    case Identity.get_rate_limit_remaining(email) do
      {:ok, remaining_seconds} when is_integer(remaining_seconds) and remaining_seconds > 0 ->
        socket
        |> assign(:countdown_seconds, remaining_seconds)
        |> assign(:timer_active, true)
        |> start_countdown_timer()

      _ ->
        socket
    end
  end

  defp start_countdown_timer(socket) do
    timer_ref = Process.send_after(self(), :countdown_tick, 1000)
    assign(socket, :timer_ref, timer_ref)
  end

  defp schedule_countdown_tick(socket) do
    timer_ref = Process.send_after(self(), :countdown_tick, 1000)
    assign(socket, :timer_ref, timer_ref)
  end

  defp cancel_timer(socket) do
    if timer_ref = socket.assigns.timer_ref do
      Process.cancel_timer(timer_ref)
    end

    assign(socket, :timer_ref, nil)
  end

  defp check_existing_rate_limit(socket) do
    email = socket.assigns.email

    case Identity.get_rate_limit_remaining(email) do
      {:ok, remaining_seconds} when is_integer(remaining_seconds) and remaining_seconds > 0 ->
        socket
        |> assign(:countdown_seconds, remaining_seconds)
        |> assign(:timer_active, true)
        |> start_countdown_timer()

      _ ->
        socket
    end
  end
end
