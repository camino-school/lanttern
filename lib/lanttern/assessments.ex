defmodule Lanttern.Assessments do
  @moduledoc """
  The Assessments context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPoint

  @doc """
  Returns the list of assessment points.

  ## Examples

      iex> list_assessment_points()
      [%AssessmentPoint{}, ...]

  """
  def list_assessment_points do
    Repo.all(AssessmentPoint)
  end

  @doc """
  Gets a single assessment point.

  Raises `Ecto.NoResultsError` if the AssessmentPoint does not exist.

  ## Examples

      iex> get_assessment_point!(123)
      %AssessmentPoint{}

      iex> get_assessment_point!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point!(id), do: Repo.get!(AssessmentPoint, id)

  @doc """
  Creates an assessment point.

  ## Examples

      iex> create_assessment_point(%{field: value})
      {:ok, %AssessmentPoint{}}

      iex> create_assessment_point(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point(attrs \\ %{}) do
    %AssessmentPoint{}
    |> AssessmentPoint.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a assessment point.

  ## Examples

      iex> update_assessment_point(assessment_point, %{field: new_value})
      {:ok, %AssessmentPoint{}}

      iex> update_assessment_point(assessment_point, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_point(%AssessmentPoint{} = assessment_point, attrs) do
    assessment_point
    |> AssessmentPoint.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assessment point.

  ## Examples

      iex> delete_assessment_point(assessment_point)
      {:ok, %AssessmentPoint{}}

      iex> delete_assessment_point(assessment_point)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment_point(%AssessmentPoint{} = assessment_point) do
    Repo.delete(assessment_point)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assessment point changes.

  ## Examples

      iex> change_assessment_point(assessment_point)
      %Ecto.Changeset{data: %AssessmentPoint{}}

  """
  def change_assessment_point(%AssessmentPoint{} = assessment_point, attrs \\ %{}) do
    AssessmentPoint.changeset(assessment_point, attrs)
  end

  alias Lanttern.Assessments.AssessmentPointEntry

  @doc """
  Returns the list of assessment_point_entries.

  ## Examples

      iex> list_assessment_point_entries()
      [%AssessmentPointEntry{}, ...]

  """
  def list_assessment_point_entries do
    Repo.all(AssessmentPointEntry)
  end

  @doc """
  Gets a single assessment_point_entry.

  Raises `Ecto.NoResultsError` if the Assessment point entry does not exist.

  ## Examples

      iex> get_assessment_point_entry!(123)
      %AssessmentPointEntry{}

      iex> get_assessment_point_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point_entry!(id), do: Repo.get!(AssessmentPointEntry, id)

  @doc """
  Creates a assessment_point_entry.

  ## Examples

      iex> create_assessment_point_entry(%{field: value})
      {:ok, %AssessmentPointEntry{}}

      iex> create_assessment_point_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_entry(attrs \\ %{}) do
    %AssessmentPointEntry{}
    |> AssessmentPointEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a assessment_point_entry.

  ## Examples

      iex> update_assessment_point_entry(assessment_point_entry, %{field: new_value})
      {:ok, %AssessmentPointEntry{}}

      iex> update_assessment_point_entry(assessment_point_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_point_entry(%AssessmentPointEntry{} = assessment_point_entry, attrs) do
    assessment_point_entry
    |> AssessmentPointEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a assessment_point_entry.

  ## Examples

      iex> delete_assessment_point_entry(assessment_point_entry)
      {:ok, %AssessmentPointEntry{}}

      iex> delete_assessment_point_entry(assessment_point_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment_point_entry(%AssessmentPointEntry{} = assessment_point_entry) do
    Repo.delete(assessment_point_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assessment_point_entry changes.

  ## Examples

      iex> change_assessment_point_entry(assessment_point_entry)
      %Ecto.Changeset{data: %AssessmentPointEntry{}}

  """
  def change_assessment_point_entry(%AssessmentPointEntry{} = assessment_point_entry, attrs \\ %{}) do
    AssessmentPointEntry.changeset(assessment_point_entry, attrs)
  end
end
