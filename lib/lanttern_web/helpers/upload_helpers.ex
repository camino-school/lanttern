defmodule LantternWeb.UploadHelpers do
  @moduledoc """
  Helpers for file upload configuration.

  Returns `allow_upload/3` option keyword lists read from application config
  (`:lanttern, :uploads`), with safe hard-coded defaults as fallback.

  Supported env vars and defaults are documented in `config/config.exs`.
  """

  @spec profile_picture() :: keyword()
  def profile_picture, do: get_config(:profile_picture, default_profile_picture())

  @spec cover() :: keyword()
  def cover, do: get_config(:cover, default_cover())

  @spec attachment() :: keyword()
  def attachment, do: get_config(:attachment, default_attachment())

  defp get_config(key, default) do
    :lanttern
    |> Application.get_env(:uploads, [])
    |> Keyword.get(key, default)
  end

  defp default_profile_picture,
    do: [max_file_size: 3_000_000, accept: ~w(.jpg .jpeg .png .webp)]

  defp default_cover,
    do: [max_file_size: 5_000_000, accept: ~w(.jpg .jpeg .png .webp)]

  defp default_attachment,
    do: [max_file_size: 5_000_000, accept: :any]
end
