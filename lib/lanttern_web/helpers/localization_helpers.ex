defmodule LantternWeb.LocalizationHelpers do
  @moduledoc """
  Set of reusable helpers for localization
  """

  @doc """
  Plug for restoring user location for controller views.

  1. If `"locale"` is present in params, we use this
  2. If not, we check for `current_user`
  3. Else, just skip it (use default locale)

  """
  def put_locale(%{params: %{"locale" => locale}} = conn, _opts) do
    Gettext.put_locale(Lanttern.Gettext, locale)
    conn
  end

  def put_locale(
        %{
          assigns: %{
            current_user: %{
              current_profile: %Lanttern.Identity.Profile{current_locale: locale}
            }
          }
        } = conn,
        _opts
      ) do
    Gettext.put_locale(Lanttern.Gettext, locale)
    conn
  end

  def put_locale(conn, _opts), do: conn

  @doc """
  Live view hooks for restoring user location.

  1. If `"locale"` is present in params, we use this
  2. If not, we check for `current_user`
  3. Else, just skip it (use default locale)

  """
  def on_mount(:default, %{"locale" => locale}, _session, socket) do
    Gettext.put_locale(Lanttern.Gettext, locale)
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
    Gettext.put_locale(Lanttern.Gettext, locale)
    {:cont, socket}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket),
    do: {:cont, socket}

  @doc """
  Translate dynamic, domain generate lists (e.g. list of subjects, list of years).

  ## Options:

      - `reorder` - boolean. (Re)orders the list based on translated fields
  """
  def translate_struct_list(list, domain, field \\ :name, opts \\ []) do
    Enum.map(list, fn item ->
      Map.put(
        item,
        field,
        Gettext.dgettext(Lanttern.Gettext, domain, Map.get(item, field))
      )
    end)
    |> reorder(field, opts)
  end

  defp reorder(list, field, reorder: true),
    do: Enum.sort_by(list, &Map.get(&1, field))

  defp reorder(list, _field, _opts), do: list

  @doc """
  Get backend locale and format it to use in `lang` HTML attr.

  ## Example

      iex> get_html_lang()
      "pt-br"
  """
  def get_html_lang() do
    Gettext.get_locale(Lanttern.Gettext)
    |> String.downcase()
    |> String.replace("_", "-")
  end
end
