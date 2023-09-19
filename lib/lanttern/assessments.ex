defmodule Lanttern.Assessments do
  @moduledoc """
  The Assessments context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.Feedback

  @doc """
  Returns the list of assessment points.

  ### Options:

  `:preloads` – preloads associated data
  `:assessment_points_ids` – filter result by provided assessment points ids

  ## Examples

      iex> list_assessment_points()
      [%AssessmentPoint{}, ...]

  """
  def list_assessment_points(opts \\ []) do
    AssessmentPoint
    |> maybe_filter_by_assessment_points_ids(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_by_assessment_points_ids(assessment_point_query, opts) do
    case Keyword.get(opts, :assessment_points_ids) do
      nil ->
        assessment_point_query

      assessment_points_ids ->
        from(
          a in assessment_point_query,
          where: a.id in ^assessment_points_ids
        )
    end
  end

  @doc """
  Gets a single assessment point.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the AssessmentPoint does not exist.

  ## Examples

      iex> get_assessment_point!(123)
      %AssessmentPoint{}

      iex> get_assessment_point!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point!(id, preloads \\ []) do
    Repo.get!(AssessmentPoint, id)
    |> Repo.preload(preloads)
  end

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
    |> AssessmentPoint.creation_changeset(attrs)
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
  Returns an `%Ecto.Changeset{}` for tracking new assessment point changes.
  Inserts date, hour, and minute virtual fields default values.

  ## Examples

      iex> new_assessment_point_changeset()
      %Ecto.Changeset{data: %AssessmentPoint{}}

  """
  def new_assessment_point_changeset() do
    %AssessmentPoint{datetime: DateTime.utc_now()}
    |> change_assessment_point()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking assessment point changes.
  Extracts date, hour, and minute virtual fields values from source datetime.

  ## Examples

      iex> change_assessment_point(assessment_point)
      %Ecto.Changeset{data: %AssessmentPoint{}}

  """
  def change_assessment_point(%AssessmentPoint{} = assessment_point, attrs \\ %{}) do
    AssessmentPoint.changeset(assessment_point, attrs)
  end

  @doc """
  Returns the list of assessment_point_entries.

  ### Options:

  `:preloads` – preloads associated data
  `:assessment_point_id` – filter entries by provided assessment point id
  `:load_feedback` - "preloads" the virtual feedback field

  ## Examples

      iex> list_assessment_point_entries()
      [%AssessmentPointEntry{}, ...]

  """
  def list_assessment_point_entries(opts \\ []) do
    AssessmentPointEntry
    |> maybe_filter_entries_by_assessment_point(opts)
    |> maybe_load_feedback(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_entries_by_assessment_point(entry_query, opts) do
    case Keyword.get(opts, :assessment_point_id) do
      nil ->
        entry_query

      assessment_point_id ->
        from(
          e in entry_query,
          join: ap in assoc(e, :assessment_point),
          where: ap.id == ^assessment_point_id
        )
    end
  end

  defp maybe_load_feedback(entry_query, opts) do
    case Keyword.get(opts, :load_feedback) do
      true ->
        from(
          e in entry_query,
          left_join: f in Feedback,
          on: e.assessment_point_id == f.assessment_point_id and e.student_id == f.student_id,
          select: %{e | feedback: f}
        )

      _ ->
        entry_query
    end
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

  ### Options:

  `:preloads` – preloads associated data
  `:force_preloads` - force preload. useful for update actions

  ## Examples

      iex> update_assessment_point_entry(assessment_point_entry, %{field: new_value})
      {:ok, %AssessmentPointEntry{}}

      iex> update_assessment_point_entry(assessment_point_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_point_entry(
        %AssessmentPointEntry{} = assessment_point_entry,
        attrs,
        opts \\ []
      ) do
    assessment_point_entry
    |> AssessmentPointEntry.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
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
  def change_assessment_point_entry(
        %AssessmentPointEntry{} = assessment_point_entry,
        attrs \\ %{}
      ) do
    AssessmentPointEntry.simple_changeset(assessment_point_entry, attrs)
  end

  @doc """
  Returns a map with two keys:

  - `:assessment_points`: list of assessment points
  - `:students_and_entries`: list of tuples with student and list of entries

  The entries list for each student have the same order of the assessment points list,
  and all students have the same number of items, using `nil` when the student
  is not linked to the assessment point in that position.

  ## Examples

      iex> list_students_assessment_points_grid()
      %{assessment_points: [%AssessmentPoint{}, ...], students_and_entries: [{%Student{}, [%AssessmentPointEntry{}, ...]}, ...]}
  """
  def list_students_assessment_points_grid() do
    query =
      from std in Lanttern.Schools.Student,
        join: ast in AssessmentPoint,
        on: true,
        left_join: ent in AssessmentPointEntry,
        on: ent.student_id == std.id and ent.assessment_point_id == ast.id,
        order_by: [std.name, ast.datetime],
        select: {std, ast, ent}

    all = Repo.all(query)

    assessment_points =
      all
      |> Enum.map(fn {_std, ast, _ent} -> ast end)
      |> Enum.uniq()

    entries_by_student =
      all
      |> Enum.group_by(
        fn {std, _ast, _ent} -> std.id end,
        fn {_std, _ast, ent} -> ent end
      )

    students_and_entries =
      all
      |> Enum.map(fn {std, _ast, _ent} -> std end)
      |> Enum.uniq()
      |> Enum.map(fn std -> {std, entries_by_student[std.id]} end)

    %{
      assessment_points: assessment_points,
      students_and_entries: students_and_entries
    }
  end

  @doc """
  Returns the list of feedback.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_feedback()
      [%Feedback{}, ...]

  """
  def list_feedback(opts \\ []) do
    Repo.all(Feedback)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single feedback.

  Raises `Ecto.NoResultsError` if the Feedback does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_feedback!(123)
      %Feedback{}

      iex> get_feedback!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feedback!(id, opts \\ []) do
    Repo.get!(Feedback, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a feedback.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_feedback(%{field: value})
      {:ok, %Feedback{}}

      iex> create_feedback(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feedback(attrs \\ %{}) do
    %Feedback{}
    |> Feedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  See `create_feedback/1`.
  """
  def create_feedback(attrs, opts) do
    with {:ok, feedback} <- create_feedback(attrs) do
      feedback =
        feedback
        |> maybe_preload(opts)

      {:ok, feedback}
    end
  end

  @doc """
  Updates a feedback.

  ## Examples

      iex> update_feedback(feedback, %{field: new_value})
      {:ok, %Feedback{}}

      iex> update_feedback(feedback, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feedback(%Feedback{} = feedback, attrs) do
    feedback
    |> Feedback.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a feedback.

  ## Examples

      iex> delete_feedback(feedback)
      {:ok, %Feedback{}}

      iex> delete_feedback(feedback)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feedback(%Feedback{} = feedback) do
    Repo.delete(feedback)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feedback changes.

  ## Examples

      iex> change_feedback(feedback)
      %Ecto.Changeset{data: %Feedback{}}

  """
  def change_feedback(%Feedback{} = feedback, attrs \\ %{}) do
    Feedback.changeset(feedback, attrs)
  end
end
