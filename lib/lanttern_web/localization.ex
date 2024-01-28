defmodule LantternWeb.Localization do
  @moduledoc """
  Live view hooks for restoring user location.

  1. If `"locale"` is present in params, we use this
  2. If not, we check for `current_user`
  3. Else, just skip it (use default locale)

  """

  def on_mount(:default, %{"locale" => locale}, _session, socket) do
    Gettext.put_locale(LantternWeb.Gettext, locale)
    {:cont, socket}
  end

  def on_mount(
        :default,
        _params,
        _session,
        %{
          assigns: %{
            current_user: %{
              current_profile: %Lanttern.Identity.Profile{current_locale: locale}
            }
          }
        } =
          socket
      )
      when is_binary(locale) do
    Gettext.put_locale(LantternWeb.Gettext, locale)
    {:cont, socket}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket),
    do: {:cont, socket}
end
