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
  alias Lanttern.Conversation.Comment
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of assessment points.

  ### Options:

  `:preloads` – preloads associated data
  `:assessment_points_ids` – filter result by provided assessment points ids
  `:activities_ids` – filter result by provided activities ids
  `:activities_from_strand_id` – filter result by activities from provided strand id
  `:strand_id` – filter result by provided strand id

  ## Examples

      iex> list_assessment_points()
      [%AssessmentPoint{}, ...]

  """
  def list_assessment_points(opts \\ []) do
    AssessmentPoint
    |> filter_assessment_points(opts)
    |> order_assessment_points(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp filter_assessment_points(queryable, opts) do
    Enum.reduce(opts, queryable, &apply_assessment_points_filter/2)
  end

  defp apply_assessment_points_filter({:assessment_points_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.id in ^ids)

  defp apply_assessment_points_filter({:activities_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.activity_id in ^ids)

  defp apply_assessment_points_filter({:activities_from_strand_id, id}, queryable) do
    from(
      ap in queryable,
      join: a in assoc(ap, :activity),
      as: :activity,
      where: a.strand_id == ^id
    )
  end

  defp apply_assessment_points_filter({:strands_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.strand_id in ^ids)

  defp apply_assessment_points_filter(_, queryable), do: queryable

  defp order_assessment_points(queryable, opts) do
    activities_ids = Keyword.get(opts, :activities_ids)
    strand_id = Keyword.get(opts, :activities_from_strand_id)

    cond do
      activities_ids ->
        from(
          ap in queryable,
          join: a in assoc(ap, :activity),
          order_by: [a.position, ap.position]
        )

      strand_id ->
        from(
          [ap, activity: a] in queryable,
          order_by: [a.position, ap.position]
        )

      true ->
        from(
          ap in queryable,
          order_by: ap.position
        )
    end
  end

  @doc """
  Gets a single assessment point.

  Returns nil if the AssessmentPoint does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_assessment_point!(123)
      %AssessmentPoint{}

      iex> get_assessment_point!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point(id, opts \\ []) do
    AssessmentPoint
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single assessment point.

  Same as `get_assessment_point/2`, but raises `Ecto.NoResultsError` if the AssessmentPoint does not exist.
  """
  def get_assessment_point!(id, opts \\ []) do
    AssessmentPoint
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates an assessment point.

  ## Options

      - `activity_id` - creates an assessment point in an activity context
      - `strand_id` - creates an assessment point in a strand context

  ## Examples

      iex> create_assessment_point(%{field: value})
      {:ok, %AssessmentPoint{}}

      iex> create_assessment_point(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point(attrs \\ %{}, opts \\ [])

  def create_assessment_point(attrs, [] = _opts) do
    %AssessmentPoint{}
    |> AssessmentPoint.creation_changeset(attrs)
    |> Repo.insert()
  end

  def create_assessment_point(attrs, opts) do
    position =
      from(
        ap in AssessmentPoint,
        select: ap.position,
        order_by: [desc: ap.position],
        limit: 1
      )
      |> filter_assessment_points_by_context(opts)
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    {context_field_id, context_id} =
      case opts do
        [activity_id: id] -> {:activity_id, id}
        [strand_id: id] -> {:strand_id, id}
      end

    attrs =
      case Map.keys(attrs) |> hd() do
        key when is_atom(key) ->
          attrs
          |> Map.put(:position, position)
          |> Map.put(context_field_id, context_id)

        _ ->
          attrs
          |> Map.put("position", position)
          |> Map.put(Atom.to_string(context_field_id), context_id)
      end

    %AssessmentPoint{}
    |> AssessmentPoint.changeset(attrs)
    |> Repo.insert()
  end

  defp filter_assessment_points_by_context(query, activity_id: activity_id),
    do: from(q in query, where: q.activity_id == ^activity_id)

  defp filter_assessment_points_by_context(query, strand_id: strand_id),
    do: from(q in query, where: q.strand_id == ^strand_id)

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
    assessment_point
    |> AssessmentPoint.delete_changeset()
    |> Repo.delete()
  end

  @doc """
  Deletes an assessment point and related entries.

  ## Examples

      iex> delete_assessment_point_and_entries(assessment_point)
      {:ok, %AssessmentPoint{}}

      iex> delete_assessment_point_and_entries(assessment_point)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment_point_and_entries(%AssessmentPoint{} = assessment_point) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(
      :delete_entries,
      from(
        e in AssessmentPointEntry,
        where: e.assessment_point_id == ^assessment_point.id
      )
    )
    |> Ecto.Multi.delete(:delete_assessment_point, assessment_point)
    |> Repo.transaction()
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
          left_join: c in Comment,
          on: f.completion_comment_id == c.id,
          preload: [feedback: {f, completion_comment: c}]
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
  Creates an assessment_point_entry.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_assessment_point_entry(%{field: value})
      {:ok, %AssessmentPointEntry{}}

      iex> create_assessment_point_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_entry(attrs \\ %{}, opts \\ []) do
    %AssessmentPointEntry{}
    |> AssessmentPointEntry.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
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

  ## Options:

    - `:filters` – accepts `:classes_ids`, `:subjects_ids`

  ### Filtering by `:classes_ids`

  We expect the function to return all assessment points that happened in the context of the classes,
  which can include entries from students that are not currently in the class (ex: student moved to another class)

  ### Filtering by `:subjects_ids`

  Inferred from related `curriculum_item`

  ## Examples

      iex> list_students_assessment_points_grid()
      %{assessment_points: [%AssessmentPoint{}, ...], students_and_entries: [{%Student{}, [%AssessmentPointEntry{}, ...]}, ...]}
  """
  def list_students_assessment_points_grid(opts \\ []) do
    all =
      from(ast in AssessmentPoint,
        join: ent in assoc(ast, :entries),
        as: :entry,
        join: std in assoc(ent, :student),
        as: :student
      )
      |> apply_grid_filters(opts)
      |> order_and_select()
      |> Repo.all()

    assessment_points =
      all
      |> Enum.map(fn {ast, _ent, _std} -> ast end)
      |> Enum.uniq()

    entries =
      all
      |> Enum.map(fn {_ast, ent, _std} -> ent end)
      |> Enum.uniq()

    students_and_entries =
      all
      |> Enum.map(fn {_ast, _ent, std} -> std end)
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)
      |> Enum.map(fn std ->
        {
          std,
          assessment_points
          |> Enum.map(fn ast ->
            Enum.find(entries, fn entry ->
              entry.assessment_point_id == ast.id and entry.student_id == std.id
            end)
          end)
        }
      end)

    %{
      assessment_points: assessment_points,
      students_and_entries: students_and_entries
    }
  end

  defp apply_grid_filters(query, opts),
    do: Enum.reduce(opts, query, &filter_grid/2)

  defp filter_grid({:classes_ids, ids}, query) when is_list(ids) and ids != [] do
    from ast in query,
      join: c in assoc(ast, :classes),
      where: c.id in ^ids
  end

  defp filter_grid({:subjects_ids, ids}, query) when is_list(ids) and ids != [] do
    from ast in query,
      join: ci in assoc(ast, :curriculum_item),
      join: sub in assoc(ci, :subjects),
      where: sub.id in ^ids
  end

  defp filter_grid(_opt, query), do: query

  defp order_and_select(query) do
    from [ast, entry: ent, student: std] in query,
      order_by: ast.datetime,
      select: {ast, ent, std}
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

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> create_feedback(%{field: value})
      {:ok, %Feedback{}}

      iex> create_feedback(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feedback(attrs \\ %{}, opts \\ []) do
    %Feedback{}
    |> Feedback.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Updates a feedback.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> update_feedback(feedback, %{field: new_value})
      {:ok, %Feedback{}}

      iex> update_feedback(feedback, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feedback(%Feedback{} = feedback, attrs, opts \\ []) do
    feedback
    |> Feedback.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
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

  @doc """
  Returns the list of the assessment point entries for every student in the given strand.

  Entries are ordered by `Activity` and `AssessmentPoint` positions,
  which is the same order used by `list_strand_assessment_points/1` with `order_by_activities = true` opt.

  ## Options:

      - `:classes_ids` – filter entries by classes
  """

  @spec list_strand_students_entries(integer(), Keyword.t()) :: [
          {Student.t(), [AssessmentPointEntry.t()]}
        ]

  def list_strand_students_entries(strand_id, opts \\ []) do
    students_query =
      case Keyword.get(opts, :classes_ids) do
        nil ->
          from(s in Student)

        classes_ids ->
          from(
            s in Student,
            join: c in assoc(s, :classes),
            where: c.id in ^classes_ids
          )
      end

    results =
      from(
        ap in AssessmentPoint,
        join: a in assoc(ap, :activity),
        join: s in subquery(students_query),
        on: true,
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        where: a.strand_id == ^strand_id,
        order_by: [s.name, a.position, ap.position],
        select: {s, e}
      )
      |> Repo.all()

    grouped_entries =
      results
      |> Enum.group_by(fn {s, _e} -> s.id end)
      |> Enum.map(fn {s_id, list} ->
        {
          s_id,
          list |> Enum.map(fn {_s, e} -> e end)
        }
      end)
      |> Enum.into(%{})

    results
    |> Enum.map(fn {s, _} -> s end)
    |> Enum.uniq()
    |> Enum.map(&{&1, grouped_entries[&1.id]})
  end

  @doc """
  Returns the list of the assessment point entries for every student in the given activity.

  Entries are ordered by `AssessmentPoint` position,
  which is the same order used by `list_assessment_points/1`.

  ## Options:

      - `:classes_ids` – filter entries by classes
  """

  @spec list_activity_students_entries(integer(), Keyword.t()) :: [
          {Student.t(), [AssessmentPointEntry.t()]}
        ]

  def list_activity_students_entries(activity_id, opts \\ []) do
    students_query =
      case Keyword.get(opts, :classes_ids) do
        nil ->
          from(s in Student)

        classes_ids ->
          from(
            s in Student,
            join: c in assoc(s, :classes),
            where: c.id in ^classes_ids
          )
      end

    results =
      from(
        ap in AssessmentPoint,
        join: s in subquery(students_query),
        on: true,
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        where: ap.activity_id == ^activity_id,
        order_by: [s.name, ap.position],
        select: {s, e}
      )
      |> Repo.all()

    grouped_entries =
      results
      |> Enum.group_by(fn {s, _e} -> s.id end)
      |> Enum.map(fn {s_id, list} ->
        {
          s_id,
          list |> Enum.map(fn {_s, e} -> e end)
        }
      end)
      |> Enum.into(%{})

    results
    |> Enum.map(fn {s, _} -> s end)
    |> Enum.uniq()
    |> Enum.map(&{&1, grouped_entries[&1.id]})
  end

  @doc """
  Update assessment points positions based on ids list order.

  ## Examples

      iex> update_assessment_points_positions([3, 2, 1])
      {:ok, [%AssessmentPoint{}, ...]}

  """
  def update_assessment_points_positions(assessment_points_ids) do
    assessment_points_ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            ap in AssessmentPoint,
            where: ap.id == ^id
          ),
          set: [position: i]
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, list_assessment_points(assessment_points_ids: assessment_points_ids)}

      _ ->
        {:error, "Something went wrong"}
    end
  end
end
