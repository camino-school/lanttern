defmodule Lanttern.Assessments do
  @moduledoc """
  The Assessments context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.AssessmentPointEntryEvidence
  alias Lanttern.Assessments.Feedback
  alias Lanttern.AssessmentsLog
  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.Conversation.Comment
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Rubrics
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of assessment points.

  ### Options:

  - `:preloads` – preloads associated data
  - `:preload_full_rubrics` – boolean, preloads full associated rubrics using `Rubrics.full_rubric_query/0`
  - `:assessment_points_ids` – filter result by provided assessment points ids
  - `:moments_ids` – filter result by provided moments ids
  - `:moments_from_strand_id` – filter result by moments from provided strand id
  - `:strand_id` – filter result by provided strand id

  ## Examples

      iex> list_assessment_points()
      [%AssessmentPoint{}, ...]

  """
  def list_assessment_points(opts \\ []) do
    AssessmentPoint
    |> maybe_preload_full_rubrics(Keyword.get(opts, :preload_full_rubrics))
    |> filter_assessment_points(opts)
    |> order_assessment_points(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_preload_full_rubrics(queryable, true) do
    from(
      ap in queryable,
      preload: [rubric: ^Rubrics.full_rubric_query()]
    )
  end

  defp maybe_preload_full_rubrics(queryable, nil), do: queryable

  defp filter_assessment_points(queryable, opts) do
    Enum.reduce(opts, queryable, &apply_assessment_points_filter/2)
  end

  defp apply_assessment_points_filter({:assessment_points_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.id in ^ids)

  defp apply_assessment_points_filter({:moments_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.moment_id in ^ids)

  defp apply_assessment_points_filter({:moments_from_strand_id, id}, queryable) do
    from(
      ap in queryable,
      join: m in assoc(ap, :moment),
      as: :moment,
      where: m.strand_id == ^id
    )
  end

  defp apply_assessment_points_filter({:strand_id, id}, queryable),
    do: from(ap in queryable, where: ap.strand_id == ^id)

  defp apply_assessment_points_filter(_, queryable), do: queryable

  defp order_assessment_points(queryable, opts) do
    moments_ids = Keyword.get(opts, :moments_ids)
    strand_id = Keyword.get(opts, :moments_from_strand_id)

    cond do
      moments_ids ->
        from(
          ap in queryable,
          join: m in assoc(ap, :moment),
          order_by: [m.position, ap.position]
        )

      strand_id ->
        from(
          [ap, moment: m] in queryable,
          order_by: [m.position, ap.position]
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

  The function handles the position field based on the learning context (moment or strand),
  appending (position = greater position in context + 1) the assessment point to the context.

  ## Examples

      iex> create_assessment_point(%{field: value})
      {:ok, %AssessmentPoint{}}

      iex> create_assessment_point(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point(attrs \\ %{}) do
    attrs =
      AssessmentPoint
      |> filter_assessment_points_by_context(attrs)
      |> set_position_in_attrs(attrs)

    %AssessmentPoint{}
    |> AssessmentPoint.changeset(attrs)
    |> Repo.insert()
  end

  defp filter_assessment_points_by_context(queryable, %{moment_id: moment_id})
       when not is_nil(moment_id) and moment_id != "",
       do: from(q in queryable, where: q.moment_id == ^moment_id)

  defp filter_assessment_points_by_context(queryable, %{"moment_id" => moment_id})
       when not is_nil(moment_id) and moment_id != "",
       do: from(q in queryable, where: q.moment_id == ^moment_id)

  defp filter_assessment_points_by_context(queryable, %{strand_id: strand_id})
       when not is_nil(strand_id) and strand_id != "",
       do: from(q in queryable, where: q.strand_id == ^strand_id)

  defp filter_assessment_points_by_context(queryable, %{"strand_id" => strand_id})
       when not is_nil(strand_id) and strand_id != "",
       do: from(q in queryable, where: q.strand_id == ^strand_id)

  defp filter_assessment_points_by_context(queryable, _),
    do: from(q in queryable, where: false)

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

  Returns `nil` if the Assessment point entry does not exist.

  ## Examples

      iex> get_assessment_point_entry(123)
      %AssessmentPointEntry{}

      iex> get_assessment_point_entry(456)
      nil

  """
  def get_assessment_point_entry(id), do: Repo.get(AssessmentPointEntry, id)

  @doc """
  Gets a single assessment_point_entry.

  Same as `get_assessment_point_entry/1`, but raises `Ecto.NoResultsError` if the Assessment point entry does not exist.

  ## Examples

      iex> get_assessment_point_entry!(123)
      %AssessmentPointEntry{}

      iex> get_assessment_point_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point_entry!(id), do: Repo.get!(AssessmentPointEntry, id)

  @doc """
  Creates an assessment_point_entry.

  ## Options:

  - `:preloads` – preloads associated data
  - `:log_profile_id` - logs the operation, linked to given profile

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
    |> AssessmentsLog.maybe_create_assessment_point_entry_log("CREATE", opts)
  end

  @doc """
  Updates a assessment_point_entry.

  ## Options:

  - `:preloads` – preloads associated data
  - `:force_preloads` - force preload. useful for update actions
  - `:log_profile_id` - logs the operation, linked to given profile

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
    |> AssessmentsLog.maybe_create_assessment_point_entry_log("UPDATE", opts)
  end

  @doc """
  Deletes an assessment point entry.

  Before deleting the entry, this function tries to delete all linked attachments.
  After the whole operation, in case of success, we trigger a request for deleting
  the attachments from the cloud (if they are internal).

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> delete_assessment_point_entry(assessment_point_entry)
      {:ok, %AssessmentPointEntry{}}

      iex> delete_assessment_point_entry(assessment_point_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_assessment_point_entry(%AssessmentPointEntry{} = assessment_point_entry, opts \\ []) do
    entry_attachments_query =
      from(
        a in Attachment,
        join: apee in assoc(a, :assessment_point_entry_evidence),
        where: apee.assessment_point_entry_id == ^assessment_point_entry.id,
        select: a
      )

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:delete_attachments, entry_attachments_query)
    |> Ecto.Multi.delete(:delete_entry, assessment_point_entry)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_entry: entry, delete_attachments: {_qty, attachments}}} ->
        # if attachment is internal (Supabase),
        # delete from cloud in an async task (fire and forget)
        Enum.each(attachments, &Attachments.maybe_delete_attachment_from_cloud(&1))

        # maybe log
        AssessmentsLog.maybe_create_assessment_point_entry_log({:ok, entry}, "DELETE", opts)

      {:error, _name, value, _changes_so_far} ->
        {:error, value}
    end
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
  Returns the list of assessment points for the given strand.

  The results are always a list of tuples, with the first item being
  some meta information about the assessment point grouping and the second
  the list of the assessment points (view below for more info).

  ### `:group_by`

  - `nil` (default) - When `:group_by` is `nil`, will return a list with one tuple, with a
  `%Strand{}` as the first item and the list of the strand assessment points
  (no moments assessment points), ordered by position.
  Preloads `curriculum_item` and `curriculum_component`.

  - `"curriculum"` - will return a list of tuples where the first item
  is a `%CurriculumItem{}` and the second is a list of `%AssessmentPoint{}`s.
  The tuples are ordered by the strand assessment point
  curriculum items position, and the assessment points are ordered by moment
  and assessment point position, with the strand assessment point at the end.
  Assessment points preloads `moment`, and curriculum items preloads curricumum component.
  Curriculum `is_differentiation` is set based on strand assessment point.

  - `"moment"` - will return a list of tuples where the first item
  is a `%Moment{}` or a `%Strand{}` and the second is a list of
  `%AssessmentPoint{}`s ordered by position.
  Preloads `curriculum_item` and `curriculum_component`.

  ## Examples

      iex> list_strand_assessment_points(strand_id)
      [
        {%Strand{}, [%AssessmentPoint{}, ...]}
      ]

      iex> list_strand_assessment_points(strand_id, group_by: "moment")
      [
        {%Moment{}, [%AssessmentPoint{}, ...]},
        ...,
        {%Strand{}, [%AssessmentPoint{}, ...]}
      ]

      iex> list_strand_assessment_points(strand_id, group_by: "curriculum")
      [
        {%CurriculumItem{}, [%AssessmentPoint{}, ...]},
        ...
      ]

  """
  @spec list_strand_assessment_points(pos_integer(), String.t() | nil) :: [
          {CurriculumItem.t() | Moment.t() | Strand.t(), [AssessmentPoint.t()]}
        ]
  def list_strand_assessment_points(strand_id, group_by \\ nil)

  def list_strand_assessment_points(strand_id, "curriculum") do
    # base query handles where and order_by
    base_query = strand_assessment_points_base_query(strand_id, "curriculum")

    assessment_points_map =
      from(
        [ap, moment: m] in base_query,
        preload: [moment: m]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.curriculum_item_id)

    from(
      ci in CurriculumItem,
      join: cc in assoc(ci, :curriculum_component),
      join: ap in assoc(ci, :assessment_points),
      where: ap.strand_id == ^strand_id,
      order_by: ap.position,
      select: %{ci | is_differentiation: ap.is_differentiation},
      preload: [curriculum_component: cc]
    )
    |> Repo.all()
    |> Enum.map(&{&1, assessment_points_map[&1.id]})
  end

  def list_strand_assessment_points(strand_id, "moment") do
    # base query handles where and order_by
    base_query = strand_assessment_points_base_query(strand_id, "moment")

    assessment_points_map =
      from(
        ap in base_query,
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        preload: [curriculum_item: {ci, curriculum_component: cc}]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.moment_id)

    moments_assessment_points =
      from(
        m in Moment,
        join: ap in assoc(m, :assessment_points),
        where: m.strand_id == ^strand_id,
        order_by: m.position,
        distinct: true
      )
      |> Repo.all()
      |> Enum.map(&{&1, assessment_points_map[&1.id]})

    strand = Repo.get(Strand, strand_id)
    strand_assessment_points = {strand, assessment_points_map[nil]}

    moments_assessment_points ++ [strand_assessment_points]
  end

  def list_strand_assessment_points(strand_id, nil) do
    # base query handles where and order_by
    base_query = strand_assessment_points_base_query(strand_id, nil)

    assessment_points =
      from(
        ap in base_query,
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        preload: [curriculum_item: {ci, curriculum_component: cc}]
      )
      |> Repo.all()

    strand = Repo.get(Strand, strand_id)

    [{strand, assessment_points}]
  end

  defp strand_assessment_points_base_query(strand_id, group_by)

  defp strand_assessment_points_base_query(strand_id, "curriculum") do
    from(
      ap in AssessmentPoint,
      left_join: m in assoc(ap, :moment),
      as: :moment,
      join: ci_ap in AssessmentPoint,
      on: ci_ap.curriculum_item_id == ap.curriculum_item_id and ci_ap.strand_id == ^strand_id,
      where: ap.strand_id == ^strand_id or m.strand_id == ^strand_id,
      order_by: [asc: ci_ap.position, asc: m.position, asc: ap.position]
    )
  end

  defp strand_assessment_points_base_query(strand_id, "moment") do
    from(
      ap in AssessmentPoint,
      left_join: m in assoc(ap, :moment),
      where: ap.strand_id == ^strand_id or m.strand_id == ^strand_id,
      order_by: [asc: m.position, asc: ap.position]
    )
  end

  defp strand_assessment_points_base_query(strand_id, nil) do
    from(
      ap in AssessmentPoint,
      where: ap.strand_id == ^strand_id,
      order_by: [asc: ap.position]
    )
  end

  @doc """
  Returns the list of assessment point entries for every student in the given strand.

  The list is comprised of tuples with `Student` as the first item, and the list of
  `AssessmentPointEntry`s as the second. When there's no entry for the given student
  and assessment point, this function handles the empty `%AssessmentPointEntry{}` creation.

  The order and quantity of the entries are aligned with `list_strand_assessment_points/2`.

  ### Options:

  - `:group_by` – `"curriculum"`, `"moment"`, or `nil` (details below)
  - `:classes_ids` – filter entries by classes
  - `:check_if_has_evidences` – (boolean) calculate virtual `has_evidences` field

  #### Order of entries when grouped by

  - `"curriculum"` - ordered by strand assessment points position, then by moments
  position, then by moments assessment points position, with the strand entry
  (the "final assessment") at the end.

  - `"moment"` - ordered by moments position, then by moments assessment points
  position, with the strand assessment points entries (ordered by assessment
  points position) at the end.

  - `nil` (only strands) - ordered by strand assessment points position.

  """

  @spec list_strand_students_entries(pos_integer(), String.t() | nil, Keyword.t()) ::
          [{Student.t(), [AssessmentPointEntry.t()]}]
  def list_strand_students_entries(strand_id, group_by, opts \\ []) do
    assessment_points_query =
      strand_assessment_points_base_query(strand_id, group_by)

    students_query =
      from(
        s in Student,
        left_join: c in assoc(s, :classes),
        as: :classes,
        order_by: [c.name, s.name]
      )
      |> apply_list_strand_students_entries_opts(opts)

    students_entries =
      from(
        ap in assessment_points_query,
        join: sc in assoc(ap, :scale),
        cross_join: s in subquery(students_query),
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        # even if we wouldn't use the assessment point,
        # we need to select something from ap to get entry `nil`s
        select: {s, ap.id, e, sc, not is_nil(ap.strand_id)}
      )
      |> Repo.all()
      |> maybe_calculate_has_evidences(Keyword.get(opts, :check_if_has_evidences))

    entries_by_student_map =
      students_entries
      |> Enum.map(&maybe_build_empty_entry/1)
      |> Enum.map(&put_is_strand_entry/1)
      |> Enum.group_by(
        fn {s, _ap_id, _e, _sc, _is_strand} -> s.id end,
        fn {_s, _ap_id, e, _sc, _is_strand} -> e end
      )
      |> Enum.into(%{})

    from(
      [s, classes: c] in students_query,
      preload: [classes: c]
    )
    |> Repo.all()
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{&1, entries_by_student_map[&1.id]})
  end

  defp apply_list_strand_students_entries_opts(queryable, []), do: queryable

  defp apply_list_strand_students_entries_opts(queryable, [
         {:classes_ids, classes_ids} | opts
       ]) do
    from(
      [_s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_strand_students_entries_opts(opts)
  end

  defp apply_list_strand_students_entries_opts(queryable, [_ | opts]),
    do: apply_list_strand_students_entries_opts(queryable, opts)

  defp maybe_build_empty_entry({s, ap_id, nil, sc, is_strand}) do
    empty_entry =
      %AssessmentPointEntry{
        student_id: s.id,
        assessment_point_id: ap_id,
        scale_id: sc.id,
        scale_type: sc.type
      }

    {s, ap_id, empty_entry, sc, is_strand}
  end

  defp maybe_build_empty_entry(select_tuple), do: select_tuple

  defp put_is_strand_entry({s, ap_id, e, sc, is_strand}) do
    e = %{e | is_strand_entry: is_strand}
    {s, ap_id, e, sc, is_strand}
  end

  # @doc """
  # Returns the list of the assessment point entries for every student in the given strand.

  # Entries are ordered by `Moment` and `AssessmentPoint` positions.

  # ## Options:

  #     - `:classes_ids` – filter entries by classes
  # """

  # @spec list_strand_students_entries(integer(), Keyword.t()) :: [
  #         {Student.t(), [AssessmentPointEntry.t()]}
  #       ]

  # def list_strand_students_entries(strand_id, opts \\ []) do
  #   # build a %{student_id => entries} map
  #   students_entries_map =
  #     from(
  #       ap in AssessmentPoint,
  #       join: m in assoc(ap, :moment),
  #       join: s in subquery(distinct_students_query(opts)),
  #       on: true,
  #       left_join: e in AssessmentPointEntry,
  #       on: e.student_id == s.id and e.assessment_point_id == ap.id,
  #       where: m.strand_id == ^strand_id,
  #       order_by: [s.name, m.position, ap.position],
  #       select: {s, e}
  #     )
  #     |> Repo.all()
  #     |> Enum.group_by(
  #       fn {s, _e} -> s.id end,
  #       fn {_s, e} -> e end
  #     )

  #   # list students in correct order and with classes preloads
  #   # then map it with its entries
  #   list_students_with_classes(opts)
  #   |> Enum.map(&{&1, students_entries_map[&1.id]})
  # end

  # defp distinct_students_query(opts) do
  #   # use this subquery to prevent duplicated students,
  #   # which can be caused by classes join
  #   case Keyword.get(opts, :classes_ids) do
  #     nil ->
  #       from(s in Student)

  #     classes_ids ->
  #       from(
  #         s in Student,
  #         join: c in assoc(s, :classes),
  #         where: c.id in ^classes_ids,
  #         distinct: s.id
  #       )
  #   end
  # end

  # defp list_students_with_classes(opts) do
  #   # list students ordered by class then by student
  #   # and preload classes (only classes from opts)
  #   case Keyword.get(opts, :classes_ids) do
  #     nil ->
  #       from(
  #         s in Student,
  #         order_by: [s.name]
  #       )

  #     classes_ids ->
  #       from(
  #         s in Student,
  #         join: c in assoc(s, :classes),
  #         where: c.id in ^classes_ids,
  #         order_by: [c.name, s.name],
  #         preload: [classes: c]
  #       )
  #   end
  #   |> Repo.all()
  # end

  @doc """
  Returns the list of entries for every student according to given opts.

  Students have preloaded classes, and are ordered by class name then by student name.

  Entries are ordered by `AssessmentPoint` positions.

  ### Options:

  - `:strand_id` – filter entries related to given strand goals
  - `:moment_id` – filter entries related to given moment assessment points
  - `:classes_ids` – filter entries by classes
  - `:check_if_has_evidences` – (boolean) calculate virtual `has_evidences` field

  """

  @spec list_students_with_entries(Keyword.t()) :: [
          {Student.t(), [AssessmentPointEntry.t()]}
        ]

  def list_students_with_entries(opts \\ []) do
    students_entries =
      from(
        s in Student,
        cross_join: ap in AssessmentPoint,
        as: :assessment_points,
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        left_join: c in assoc(s, :classes),
        as: :classes,
        order_by: [c.name, s.name, ap.position],
        preload: [classes: c],
        # although we don't need it, we need to select
        # something from ap to get the "nil"s correctly
        select: {s, ap.id, e}
      )
      |> apply_list_students_with_entries_opts(opts)
      |> Repo.all()
      |> maybe_calculate_has_evidences(Keyword.get(opts, :check_if_has_evidences))

    entries_by_student_map =
      students_entries
      |> Enum.group_by(
        fn {s, _ap_id, _e} -> s.id end,
        fn {_s, _ap_id, e} -> e end
      )
      |> Enum.into(%{})

    students_entries
    |> Enum.map(fn {s, _ap_id, _e} -> s end)
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{&1, entries_by_student_map[&1.id]})
  end

  defp apply_list_students_with_entries_opts(queryable, []), do: queryable

  defp apply_list_students_with_entries_opts(queryable, [
         {:strand_id, strand_id} | opts
       ]) do
    from(
      [_s, assessment_points: ap] in queryable,
      where: ap.strand_id == ^strand_id
    )
    |> apply_list_students_with_entries_opts(opts)
  end

  defp apply_list_students_with_entries_opts(queryable, [
         {:moment_id, moment_id} | opts
       ]) do
    from(
      [_s, assessment_points: ap] in queryable,
      where: ap.moment_id == ^moment_id
    )
    |> apply_list_students_with_entries_opts(opts)
  end

  defp apply_list_students_with_entries_opts(queryable, [
         {:classes_ids, classes_ids} | opts
       ]) do
    from(
      [_s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_students_with_entries_opts(opts)
  end

  defp apply_list_students_with_entries_opts(queryable, [_ | opts]),
    do: apply_list_students_with_entries_opts(queryable, opts)

  defp maybe_calculate_has_evidences(students_entries, true) do
    entries_ids =
      students_entries
      |> Enum.map(fn
        {_s, _ap_id, e} -> e && e.id
        {_s, _ap_id, e, _sc, _is_strand} -> e && e.id
      end)
      |> Enum.filter(& &1)

    entries_ids_with_has_evidences_map =
      from(
        e in AssessmentPointEntry,
        left_join: apee in assoc(e, :assessment_point_entry_evidences),
        where: e.id in ^entries_ids,
        select: {e.id, count(apee) > 0},
        group_by: e.id
      )
      |> Repo.all()
      |> Enum.into(%{})

    # return updated students_entries
    students_entries
    |> Enum.map(fn
      {s, ap_id, e} ->
        {
          s,
          ap_id,
          e && %{e | has_evidences: entries_ids_with_has_evidences_map[e.id]}
        }

      {s, ap_id, e, sc} ->
        {
          s,
          ap_id,
          e && e.id && %{e | has_evidences: entries_ids_with_has_evidences_map[e.id]},
          sc
        }
    end)
  end

  defp maybe_calculate_has_evidences(students_entries, _), do: students_entries

  @doc """
  Returns the list of strand goals and entries for the given student and strand.

  Assessment points without entries are ignored.

  Ordered by `AssessmentPoint` positions.

  Assessment point preloads:
  - scale with ordinal values
  - rubric with descriptors and differentiation rubric linked to the given student
  - curriculum item with curriculum component, subjects, and years
  """

  @spec list_strand_goals_student_entries(integer(), integer()) :: [
          {AssessmentPoint.t(), AssessmentPointEntry.t()}
        ]

  def list_strand_goals_student_entries(student_id, strand_id) do
    from(
      ap in AssessmentPoint,
      join: s in assoc(ap, :scale),
      left_join: ov in assoc(s, :ordinal_values),
      left_join: r in assoc(ap, :rubric),
      left_join: rd in assoc(r, :descriptors),
      left_join: rdov in assoc(rd, :ordinal_value),
      left_join: diff_r_s in "differentiation_rubrics_students",
      on: diff_r_s.student_id == ^student_id,
      left_join: diff_r in Rubrics.Rubric,
      on: diff_r.id == diff_r_s.rubric_id and diff_r.diff_for_rubric_id == r.id,
      left_join: diff_rd in assoc(diff_r, :descriptors),
      left_join: diff_rdov in assoc(diff_rd, :ordinal_value),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      join: e in AssessmentPointEntry,
      on: e.assessment_point_id == ap.id and e.student_id == ^student_id,
      left_join: sub in assoc(ci, :subjects),
      left_join: y in assoc(ci, :years),
      where: ap.strand_id == ^strand_id,
      order_by: [
        asc: ap.position,
        asc: ov.normalized_value,
        asc: rdov.normalized_value,
        asc: diff_rdov.normalized_value
      ],
      select: {ap, e},
      preload: [
        scale: {s, ordinal_values: ov},
        rubric: {r, descriptors: rd, differentiation_rubrics: {diff_r, descriptors: diff_rd}},
        curriculum_item: {ci, curriculum_component: cc, subjects: sub, years: y}
      ]
    )
    |> Repo.all()
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

  @doc """
  Creates a rubric and link it to the given assessment point.

  It's a wrapper around `Rubrics.create_rubric/2` with an assessment point update
  in the same transaction (avoiding "orphans" rubrics).

  If some error happens during rubric creation, it returns a tuple with `:error` and rubric
  error changeset. If the error happens elsewhere, it returns a tuple with `:error` and a message.

  ## Options

      - View `Rubrics.create_rubric/2`

  ## Examples

      iex> create_assessment_point_rubric(1, %{field: value})
      {:ok, %AssessmentPointEntry{}}

      iex> create_assessment_point_rubric(2, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_assessment_point_rubric(999, %{field: value})
      {:ok, "Assessment point not found"}

  """
  def create_assessment_point_rubric(assessment_point_id, attrs \\ %{}, opts \\ []) do
    Repo.transaction(fn ->
      rubric =
        case Rubrics.create_rubric(attrs, opts) do
          {:ok, rubric} -> rubric
          {:error, error_changeset} -> Repo.rollback(error_changeset)
        end

      assessment_point =
        case get_assessment_point(assessment_point_id) do
          nil -> Repo.rollback("Assessment point not found")
          assessment_point -> assessment_point
        end

      case update_assessment_point(assessment_point, %{rubric_id: rubric.id}) do
        {:ok, _assessment_point} ->
          :ok

        {:error, _error_changeset} ->
          Repo.rollback("Error linking rubric to the assessment point")
      end

      rubric
    end)
  end

  @doc """
  Creates an evidence (attachment) and links it to an existing assessment point entry in a single transaction.

  ## Examples

      iex> create_assessment_point_entry_evidence(user, 1, %{field: value})
      {:ok, %Attachment{}}

      iex> create_assessment_point_entry_evidence(user, 1, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_assessment_point_entry_evidence(
          User.t(),
          assessment_point_entry_id :: pos_integer(),
          attrs :: map()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def create_assessment_point_entry_evidence(
        %{current_profile: profile},
        assessment_point_entry_id,
        attrs \\ %{}
      ) do
    insert_query =
      %Attachment{}
      |> Attachment.changeset(Map.put(attrs, "owner_id", profile && profile.id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_evidence, insert_query)
    |> Ecto.Multi.run(
      :link_assessment_point_entry,
      fn _repo, %{insert_evidence: attachment} ->
        attrs =
          from(
            apee in AssessmentPointEntryEvidence,
            where: apee.assessment_point_entry_id == ^assessment_point_entry_id
          )
          |> set_position_in_attrs(%{
            assessment_point_entry_id: assessment_point_entry_id,
            attachment_id: attachment.id,
            owner_id: profile.id
          })

        %AssessmentPointEntryEvidence{}
        |> AssessmentPointEntryEvidence.changeset(attrs)
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{insert_evidence: attachment}} -> {:ok, attachment}
    end
  end

  @doc """
  Update assessment point entry evidences positions based on ids list order.

  ## Examples

  iex> update_assessment_point_entry_evidences_positions([3, 2, 1])
  :ok

  """
  @spec update_assessment_point_entry_evidences_positions(attachments_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_assessment_point_entry_evidences_positions(attachments_ids),
    do: update_positions(AssessmentPointEntryEvidence, attachments_ids, id_field: :attachment_id)
end
