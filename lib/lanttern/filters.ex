defmodule Lanttern.Filters do
  @moduledoc """
  The Filters context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Filters.ProfileStrandFilter
  alias Lanttern.Identity.User
  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileSettings

  @doc """
  Set current profile filters.

  If there's no profile setting, this function creates one.

  ## Examples

      iex> set_profile_current_filters(user, %{classes_ids: [1], subjects_ids: [2]})
      {:ok, %ProfileSettings{}}

      iex> set_profile_current_filters(user, %{classes_ids: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec set_profile_current_filters(User.t(), attrs :: map()) ::
          {:ok, ProfileSettings.t()} | {:error, Ecto.Changeset.t()}
  def set_profile_current_filters(%{current_profile: %{id: profile_id}}, attrs \\ %{}),
    do:
      insert_settings_or_update_filters(
        Personalization.get_profile_settings(profile_id),
        profile_id,
        attrs
      )

  defp insert_settings_or_update_filters(nil, profile_id, attrs) do
    %ProfileSettings{}
    |> ProfileSettings.changeset(%{
      profile_id: profile_id,
      current_filters: attrs
    })
    |> Repo.insert()
  end

  defp insert_settings_or_update_filters(profile_settings, _, attrs) do
    profile_settings
    |> ProfileSettings.changeset(%{
      current_filters:
        case profile_settings.current_filters do
          nil -> attrs
          current_filters -> Map.from_struct(current_filters) |> Map.merge(attrs)
        end
    })
    |> Repo.update()
  end

  @doc """
  Returns the list of profile_strand_filters.

  ## Examples

      iex> list_profile_strand_filters()
      [%ProfileStrandFilter{}, ...]

  """
  def list_profile_strand_filters do
    Repo.all(ProfileStrandFilter)
  end

  @doc """
  Returns the list of current classes ids filters for the given strand and profile.

  ## Examples

      iex> list_profile_strand_filters_classes_ids(1, 1)
      [1, 2, ...]

  """
  @spec list_profile_strand_filters_classes_ids(pos_integer(), pos_integer()) :: [pos_integer()]
  def list_profile_strand_filters_classes_ids(profile_id, strand_id) do
    from(
      psf in ProfileStrandFilter,
      where: psf.profile_id == ^profile_id,
      where: psf.strand_id == ^strand_id,
      select: psf.class_id
    )
    |> Repo.all()
  end

  @doc """
  Gets a single profile_strand_filter.

  Raises `Ecto.NoResultsError` if the Profile strand filter does not exist.

  ## Examples

      iex> get_profile_strand_filter!(123)
      %ProfileStrandFilter{}

      iex> get_profile_strand_filter!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile_strand_filter!(id), do: Repo.get!(ProfileStrandFilter, id)

  @doc """
  Set profile strand filters.

  ## Examples

      iex> set_profile_strand_filters(user, 1, %{classes_ids: [1]})
      :ok

      iex> set_profile_strand_filters(user, 1, %{classes_ids: bad_value})
      {:error, message}

  """
  @spec set_profile_strand_filters(User.t(), pos_integer(), map()) ::
          {:ok, any()}
          | {:error, any()}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def set_profile_strand_filters(%{current_profile: %{id: profile_id}}, strand_id, %{
        classes_ids: classes_ids
      })
      when is_list(classes_ids) do
    # delete existing entries for given profile/strand
    from(
      psf in ProfileStrandFilter,
      where: psf.profile_id == ^profile_id,
      where: psf.strand_id == ^strand_id
    )
    |> Repo.delete_all()

    # and insert the new values
    base_profile_strand_filter =
      %ProfileStrandFilter{
        profile_id: profile_id,
        strand_id: strand_id
      }

    Ecto.Multi.new()
    |> multi_insert_profile_strand_filter(
      base_profile_strand_filter,
      classes_ids
    )
    |> Repo.transaction()
  end

  defp multi_insert_profile_strand_filter(multi, _base_profile_strand_filter, []), do: multi

  defp multi_insert_profile_strand_filter(multi, base_profile_strand_filter, [
         class_id | classes_ids
       ]) do
    %{
      profile_id: profile_id,
      strand_id: strand_id
    } = base_profile_strand_filter

    name = "#{profile_id}_#{strand_id}_#{class_id}"

    changeset =
      change_profile_strand_filter(
        base_profile_strand_filter,
        %{class_id: class_id}
      )

    multi
    |> Ecto.Multi.insert(name, changeset)
    |> multi_insert_profile_strand_filter(
      base_profile_strand_filter,
      classes_ids
    )
  end

  @doc """
  Creates a profile_strand_filter.

  ## Examples

      iex> create_profile_strand_filter(%{field: value})
      {:ok, %ProfileStrandFilter{}}

      iex> create_profile_strand_filter(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile_strand_filter(attrs \\ %{}) do
    %ProfileStrandFilter{}
    |> ProfileStrandFilter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile_strand_filter.

  ## Examples

      iex> update_profile_strand_filter(profile_strand_filter, %{field: new_value})
      {:ok, %ProfileStrandFilter{}}

      iex> update_profile_strand_filter(profile_strand_filter, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter, attrs) do
    profile_strand_filter
    |> ProfileStrandFilter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile_strand_filter.

  ## Examples

      iex> delete_profile_strand_filter(profile_strand_filter)
      {:ok, %ProfileStrandFilter{}}

      iex> delete_profile_strand_filter(profile_strand_filter)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter) do
    Repo.delete(profile_strand_filter)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile_strand_filter changes.

  ## Examples

      iex> change_profile_strand_filter(profile_strand_filter)
      %Ecto.Changeset{data: %ProfileStrandFilter{}}

  """
  def change_profile_strand_filter(%ProfileStrandFilter{} = profile_strand_filter, attrs \\ %{}) do
    ProfileStrandFilter.changeset(profile_strand_filter, attrs)
  end

end
