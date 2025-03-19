defmodule Lanttern.Personalization do
  @moduledoc """
  The Personalization context.

  ### Permissions info

  - `students_records_full_access` - full students records management access
  - `school_management` - control access to classes, students, and staff management
  - `content_management` - control content related configurations
  - `communication_management` - allows school message board management
  - `ilp_management` - allows ILP template management and students ILP sharing
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Personalization.ProfileSettings

  @valid_permissions [
    "students_records_full_access",
    "school_management",
    "content_management",
    "communication_management",
    "ilp_management"
  ]

  @doc """
  Get profile settings.

  Returns `nil` if profile has no settings.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_profile_settings(profile_id)
      %ProfileSettings{}

      iex> get_profile_settings(profile_id)
      nil

  """
  def get_profile_settings(profile_id, opts \\ []) do
    ProfileSettings
    |> Repo.get_by(profile_id: profile_id)
    |> maybe_preload(opts)
  end

  @doc """
  Set current profile settings.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_settings(profile_id, settings)
      {:ok, %ProfileSettings{}}

      iex> set_profile_settings(profile_id, "bad settings"])
      {:error, %Ecto.Changeset{}}

  """
  @spec set_profile_settings(profile_id :: pos_integer(), settings :: map()) ::
          {:ok, ProfileSettings.t()} | {:error, Ecto.Changeset.t()}
  def set_profile_settings(profile_id, settings),
    do:
      insert_or_update_settings(
        get_profile_settings(profile_id),
        profile_id,
        settings
      )

  defp insert_or_update_settings(nil, profile_id, settings) do
    settings = Map.put(settings, :profile_id, profile_id)

    %ProfileSettings{}
    |> ProfileSettings.changeset(settings)
    |> Repo.insert()
  end

  defp insert_or_update_settings(profile_settings, _, settings) do
    profile_settings
    |> ProfileSettings.changeset(settings)
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
