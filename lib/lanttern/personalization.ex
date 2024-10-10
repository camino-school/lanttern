defmodule Lanttern.Personalization do
  @moduledoc """
  The Personalization context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Personalization.ProfileSettings

  @valid_permissions ["wcd"]

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

  @doc """
  Set current profile permissions.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_permissions(profile_id, permissions)
      {:ok, %ProfileSettings{}}

      iex> set_profile_permissions(profile_id, ["bad permission"])
      {:error, %Ecto.Changeset{}}

  """
  @spec set_profile_permissions(profile_id :: pos_integer(), permissions :: [binary()]) ::
          {:ok, ProfileSettings.t()} | {:error, Ecto.Changeset.t()}
  def set_profile_permissions(profile_id, permissions),
    do:
      insert_settings_or_update_permissions(
        get_profile_settings(profile_id),
        profile_id,
        permissions
      )

  defp insert_settings_or_update_permissions(nil, profile_id, permissions) do
    %ProfileSettings{}
    |> ProfileSettings.changeset(%{
      profile_id: profile_id,
      permissions: permissions
    })
    |> Repo.insert()
  end

  defp insert_settings_or_update_permissions(profile_settings, _, permissions) do
    profile_settings
    |> ProfileSettings.changeset(%{permissions: permissions})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile settings changes.

  ## Examples

      iex> change_profile_settings(note)
      %Ecto.Changeset{data: %ProfileSettings{}}

  """
  def change_profile_settings(%ProfileSettings{} = profile_settings, attrs \\ %{}) do
    ProfileSettings.changeset(profile_settings, attrs)
  end

  @doc """
  Get list of valid permissions.

  ## Examples

      iex> list_valid_permissions()
      ["permission 1", ...]

  """
  @spec list_valid_permissions() :: [binary()]
  def list_valid_permissions(), do: @valid_permissions
end
