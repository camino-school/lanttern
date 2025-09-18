defmodule LantternWeb.UserCodeLoginLive do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm py-20">
      <h1 class="font-display font-black text-5xl leading-tight">
        Lanttern<br />sign in
      </h1>
      <p class="mt-10 text-lg">
        {gettext(
          "We've sent a sign-in link to %{email}.",
          email: @email
        )}
      </p>
      <p class="mt-4 text-base text-ltrn-subtle">
        {gettext(
          "Don't see it? Check your spam folder and ensure there's a Lanttern account for the provided email."
        )}
      </p>
      <p class="mt-10">
        <a href={~p"/users/log-in"} class="underline hover:text-ltrn-subtle">
          {gettext("Sign in using a different method")}
        </a>
      </p>
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

    {:ok, assign(socket, :email, email)}
  end
end
