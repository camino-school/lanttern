defmodule Lanttern.Personalization do
  @moduledoc """
  The Personalization context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Personalization.ProfileSettings
  alias Lanttern.Personalization.ProfileView

  @doc """
  Returns the list of profile_views.

  ## Options

      - `:preloads` – preloads associated data
      - `:profile_id` – filter views by provided assessment point id

  ## Examples

      iex> list_profile_views()
      [%ProfileView{}, ...]

  """
  def list_profile_views(opts \\ []) do
    ProfileView
    |> filter_list_profile_views(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp filter_list_profile_views(queryable, opts) when is_list(opts),
    do: Enum.reduce(opts, queryable, &filter_list_profile_views/2)

  defp filter_list_profile_views({:profile_id, profile_id}, queryable) do
    from v in queryable,
      join: p in assoc(v, :profile),
      where: p.id == ^profile_id
  end

  defp filter_list_profile_views(_, queryable),
    do: queryable

  @doc """
  Gets a single profile_view.

  Raises `Ecto.NoResultsError` if the profile view does not exist.

  ## Options

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_profile_view!(123)
      %ProfileView{}

      iex> get_profile_view!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile_view!(id, opts \\ []) do
    Repo.get!(ProfileView, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a profile_view.

  ## Examples

      iex> create_profile_view(%{field: value})
      {:ok, %ProfileView{}}

      iex> create_profile_view(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile_view(attrs \\ %{}) do
    # add classes and subjects to force return with preloaded classes/subjects
    %ProfileView{classes: [], subjects: []}
    |> ProfileView.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile_view.

  ## Examples

      iex> update_profile_view(profile_view, %{field: new_value})
      {:ok, %ProfileView{}}

      iex> update_profile_view(profile_view, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile_view(
        %ProfileView{} = profile_view,
        attrs
      ) do
    profile_view
    |> ProfileView.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a profile_view.

  ## Examples

      iex> delete_profile_view(profile_view)
      {:ok, %ProfileView{}}

      iex> delete_profile_view(profile_view)
      {:error, %Ecto.Changeset{}}

  """
  def delete_profile_view(%ProfileView{} = profile_view) do
    Repo.delete(profile_view)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking profile_view changes.

  ## Examples

      iex> change_profile_view(profile_view)
      %Ecto.Changeset{data: %ProfileView{}}

  """
  def change_profile_view(
        %ProfileView{} = profile_view,
        attrs \\ %{}
      ) do
    ProfileView.changeset(profile_view, attrs)
  end

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
