defmodule Lanttern.Explorer do
  @moduledoc """
  The Explorer context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Explorer.AssessmentPointsFilterView

  @doc """
  Returns the list of assessment_points_filter_views.

  ## Options

      - `:preloads` – preloads associated data
      - `:profile_id` – filter views by provided assessment point id

  ## Examples

      iex> list_assessment_points_filter_views()
      [%AssessmentPointsFilterView{}, ...]

  """
  def list_assessment_points_filter_views(opts \\ []) do
    AssessmentPointsFilterView
    |> filter_list_assessment_points_filter_views(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp filter_list_assessment_points_filter_views(queryable, opts) when is_list(opts),
    do: Enum.reduce(opts, queryable, &filter_list_assessment_points_filter_views/2)

  defp filter_list_assessment_points_filter_views({:profile_id, profile_id}, queryable) do
    from v in queryable,
      join: p in assoc(v, :profile),
      where: p.id == ^profile_id
  end

  defp filter_list_assessment_points_filter_views(_, queryable),
    do: queryable

  @doc """
  Gets a single assessment_points_filter_view.

  Raises `Ecto.NoResultsError` if the Assessment points filter view does not exist.

  ## Options

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_assessment_points_filter_view!(123)
      %AssessmentPointsFilterView{}

      iex> get_assessment_points_filter_view!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_points_filter_view!(id, opts \\ []) do
    Repo.get!(AssessmentPointsFilterView, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates an assessment_points_filter_view.

  ## Examples

      iex> create_assessment_points_filter_view(%{field: value})
      {:ok, %AssessmentPointsFilterView{}}

      iex> create_assessment_points_filter_view(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_points_filter_view(attrs \\ %{}) do
    # add classes and subjects to force return with preloaded classes/subjects
    %AssessmentPointsFilterView{classes: [], subjects: []}
    |> AssessmentPointsFilterView.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a assessment_points_filter_view.

  ## Examples

      iex> update_assessment_points_filter_view(assessment_points_filter_view, %{field: new_value})
      {:ok, %AssessmentPointsFilterView{}}

      iex> update_assessment_points_filter_view(assessment_points_filter_view, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_points_filter_view(
        %AssessmentPointsFilterView{} = assessment_points_filter_view,
        attrs
      ) do
    assessment_points_filter_view
    |> AssessmentPointsFilterView.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assessment_points_filter_view.

  ## Examples

      iex> delete_assessment_points_filter_view(assessment_points_filter_view)
      {:ok, %AssessmentPointsFilterView{}}

      iex> delete_assessment_points_filter_view(assessment_points_filter_view)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment_points_filter_view(
        %AssessmentPointsFilterView{} = assessment_points_filter_view
      ) do
    Repo.delete(assessment_points_filter_view)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assessment_points_filter_view changes.

  ## Examples

      iex> change_assessment_points_filter_view(assessment_points_filter_view)
      %Ecto.Changeset{data: %AssessmentPointsFilterView{}}

  """
  def change_assessment_points_filter_view(
        %AssessmentPointsFilterView{} = assessment_points_filter_view,
        attrs \\ %{}
      ) do
    AssessmentPointsFilterView.changeset(assessment_points_filter_view, attrs)
  end
end
