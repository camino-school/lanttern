defmodule Lanttern.Personalization do
  @moduledoc """
  The Personalization context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Personalization.ProfileSettings

  @doc """
  Get profile settings.

  Returns `nil` if profile has no settings.

  ## Examples

      iex> get_profile_settings(profile_id)
      %ProfileSettings{}

      iex> get_profile_settings(profile_id)
      nil

  """
  def get_profile_settings(profile_id),
    do: Repo.get_by(ProfileSettings, profile_id: profile_id)
end
