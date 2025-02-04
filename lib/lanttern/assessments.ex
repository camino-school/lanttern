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

  defp apply_assessment_points_filter({:strand_id, id}, queryable),
    do: from(ap in queryable, where: ap.strand_id == ^id)

  defp apply_assessment_points_filter(_, queryable), do: queryable

  defp order_assessment_points(queryable, opts) do
    if Keyword.get(opts, :moments_ids) do
      from(
        ap in queryable,
        join: m in assoc(ap, :moment),
        order_by: [m.position, ap.position]
      )
    else
      from(
        ap in queryable,
        order_by: ap.position
      )
    end
  end

  @doc """
  Gets a single assessment point.

  Returns nil if the AssessmentPoint does not exist.

  ## Options:

  - `:preload_full_rubrics` – boolean, preloads full associated rubric using `Rubrics.full_rubric_query/0`
  - `:preloads` – preloads associated data

  ## Examples

      iex> get_assessment_point!(123)
      %AssessmentPoint{}

      iex> get_assessment_point!(456)
      ** (Ecto.NoResultsError)

  """
  def get_assessment_point(id, opts \\ []) do
    AssessmentPoint
    |> maybe_preload_full_rubrics(Keyword.get(opts, :preload_full_rubrics))
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single assessment point.

  Same as `get_assessment_point/2`, but raises `Ecto.NoResultsError` if the AssessmentPoint does not exist.
  """
  def get_assessment_point!(id, opts \\ []) do
    AssessmentPoint
    |> maybe_preload_full_rubrics(Keyword.get(opts, :preload_full_rubrics))
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
  Gets a single assessment_point_entry for the given assessment point and student.

  Returns `nil` if the Assessment point entry does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_assessment_point_student_entry(123, 1)
      %AssessmentPointEntry{}

      iex> get_assessment_point_student_entry(456, 1)
      nil

  """
  @spec get_assessment_point_student_entry(
          assessment_point_id :: pos_integer(),
          student_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: AssessmentPointEntry.t() | nil
  def get_assessment_point_student_entry(assessment_point_id, student_id, opts \\ []) do
    AssessmentPointEntry
    |> Repo.get_by(assessment_point_id: assessment_point_id, student_id: student_id)
    |> maybe_preload(opts)
  end

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

  The return format is comprised of a tuple with two lists:
  1. a list of "headers", a tuple with the group by struct and a count of assessment points
  2. the list of assessment points (view below for more info).

  ### `:group_by`

  - `nil` (default) - When `:group_by` is `nil`, there will be only one header
  (the `%Strand{}`) and the list of the strand assessment points (no moments
  assessment points) will be ordered by position.
  Assesment points preloads `curriculum_item` and `curriculum_component`.

  - `"curriculum"` - will return a list of `%CurriculumItem{}`s as headers,
  ordered by the strand assessment point curriculum items position,
  and the assessment points will be ordered by moment and assessment point position,
  with the strand assessment points at the end.
  Assessment points preloads `moment`, and curriculum items preloads curricumum component.
  Curriculum `is_differentiation` is set based on strand assessment point.

  - `"moment"` - will return a list of `%Moment{}`s in the header, with
  a `%Strand{}` at the end. Assessment points are ordered by moment and
  assessment point position, with strand assessment points at the end.
  Assessment points preloads `curriculum_item` and `curriculum_component`.

  ## Examples

      iex> list_strand_assessment_points(strand_id)
      {
        [%Strand{}, 10],
        [%AssessmentPoint{}, ...]
      }

      iex> list_strand_assessment_points(strand_id, group_by: "curriculum")
      {
        [{%CurriculumItem{}, 5}, ...],
        [%AssessmentPoint{}, ...]
      }

      iex> list_strand_assessment_points(strand_id, group_by: "moment")
      {
        [{%Moment{}, 5}, ..., {%Strand{}, 10}],
        [%AssessmentPoint{}, ...]
      }

  """
  @spec list_strand_assessment_points(pos_integer(), String.t() | nil) :: {
          [{CurriculumItem.t() | Moment.t() | Strand.t(), non_neg_integer()}],
          [AssessmentPoint.t()]
        }
  def list_strand_assessment_points(strand_id, group_by \\ nil)

  def list_strand_assessment_points(strand_id, "curriculum") do
    # base query handles where and order_by
    base_query = strand_assessment_points_base_query(strand_id, "curriculum")

    assessment_points =
      from(
        [ap, moment: m] in base_query,
        preload: [moment: m]
      )
      |> Repo.all()

    curriculum_items_ap_count_map =
      assessment_points
      |> Enum.group_by(& &1.curriculum_item_id)
      |> Enum.map(fn {curriculum_item_id, assessment_points} ->
        {curriculum_item_id, length(assessment_points)}
      end)
      |> Enum.into(%{})

    headers =
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
      |> Enum.map(&{&1, curriculum_items_ap_count_map[&1.id]})

    {headers, assessment_points}
  end

  def list_strand_assessment_points(strand_id, "moment") do
    # base query handles where and order_by
    base_query = strand_assessment_points_base_query(strand_id, "moment")

    assessment_points =
      from(
        ap in base_query,
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        preload: [curriculum_item: {ci, curriculum_component: cc}]
      )
      |> Repo.all()

    assessment_points_count_map =
      assessment_points
      |> Enum.group_by(& &1.moment_id)
      |> Enum.map(fn {moment_id, assessment_points} -> {moment_id, length(assessment_points)} end)
      |> Enum.into(%{})

    moments_headers =
      from(
        m in Moment,
        join: ap in assoc(m, :assessment_points),
        where: m.strand_id == ^strand_id,
        order_by: m.position,
        distinct: true
      )
      |> Repo.all()
      |> Enum.map(&{&1, assessment_points_count_map[&1.id]})

    strand = Repo.get(Strand, strand_id)
    strand_header = {strand, assessment_points_count_map[nil]}

    {moments_headers ++ [strand_header], assessment_points}
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

    {[{strand, length(assessment_points)}], assessment_points}
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
  - `:active_students_only` – (boolean) remove deactivated students from results
  - `:check_if_has_evidences` – (boolean) calculate virtual `has_evidences` field

  #### Order of entries when grouped by

  View `list_strand_assessment_points/2`.

  """

  @spec list_strand_students_entries(pos_integer(), String.t() | nil, Keyword.t()) ::
          [{Student.t(), [AssessmentPointEntry.t()]}]
  def list_strand_students_entries(strand_id, group_by, opts \\ []) do
    assessment_points_query =
      strand_assessment_points_base_query(strand_id, group_by)

    students_entries =
      from(
        ap in assessment_points_query,
        join: sc in assoc(ap, :scale),
        cross_join: s in subquery(list_entries_students_query(opts)),
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        # even if we wouldn't use the assessment point,
        # we need to select something from ap to get entry `nil`s
        select: {s, ap.id, e, sc, not is_nil(ap.strand_id)}
      )
      |> Repo.all()
      |> Enum.uniq_by(fn {s, ap_id, _e, _sc, _is_strand} -> "#{s.id}_#{ap_id}" end)
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
      [s, classes: c] in list_entries_students_query(opts),
      preload: [classes: c]
    )
    |> Repo.all()
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{&1, entries_by_student_map[&1.id]})
  end

  defp maybe_build_empty_entry({s, ap_id, nil, sc, is_strand}),
    do: {s, ap_id, build_empty_entry(s, ap_id, sc), sc, is_strand}

  defp maybe_build_empty_entry({s, ap_id, nil, sc}),
    do: {s, ap_id, build_empty_entry(s, ap_id, sc), sc}

  defp maybe_build_empty_entry(select_tuple), do: select_tuple

  defp build_empty_entry(student, assessment_point_id, scale) do
    %AssessmentPointEntry{
      student_id: student.id,
      assessment_point_id: assessment_point_id,
      scale_id: scale.id,
      scale_type: scale.type
    }
  end

  defp put_is_strand_entry({s, ap_id, e, sc, is_strand}) do
    e = %{e | is_strand_entry: is_strand}
    {s, ap_id, e, sc, is_strand}
  end

  @doc """
  Returns the list of assessment point entries for every student in the given moment.

  The list is comprised of tuples with `Student` as the first item, and the list of
  `AssessmentPointEntry`s as the second. When there's no entry for the given student
  and assessment point, this function handles the empty `%AssessmentPointEntry{}` creation.

  Entries are ordered by assessment point position.

  ### Options:

  - `:classes_ids` – filter entries by classes
  - `:active_students_only` – (boolean) remove deactivated students from results
  - `:check_if_has_evidences` – (boolean) calculate virtual `has_evidences` field

  """

  @spec list_moment_students_entries(pos_integer(), Keyword.t()) ::
          [{Student.t(), [AssessmentPointEntry.t()]}]
  def list_moment_students_entries(moment_id, opts \\ []) do
    students_entries =
      from(
        ap in AssessmentPoint,
        join: sc in assoc(ap, :scale),
        cross_join: s in subquery(list_entries_students_query(opts)),
        left_join: e in AssessmentPointEntry,
        on: e.student_id == s.id and e.assessment_point_id == ap.id,
        where: ap.moment_id == ^moment_id,
        order_by: [asc: ap.position],
        # even if we wouldn't use the assessment point,
        # we need to select something from ap to get entry `nil`s
        select: {s, ap.id, e, sc}
      )
      |> Repo.all()
      |> Enum.uniq_by(fn {s, ap_id, _e, _sc} -> "#{s.id}_#{ap_id}" end)
      |> maybe_calculate_has_evidences(Keyword.get(opts, :check_if_has_evidences))

    entries_by_student_map =
      students_entries
      |> Enum.map(&maybe_build_empty_entry/1)
      |> Enum.group_by(
        fn {s, _ap_id, _e, _sc} -> s.id end,
        fn {_s, _ap_id, e, _sc} -> e end
      )
      |> Enum.into(%{})

    from(
      [s, classes: c] in list_entries_students_query(opts),
      preload: [classes: c]
    )
    |> Repo.all()
    |> Enum.uniq_by(& &1.id)
    |> Enum.map(&{&1, entries_by_student_map[&1.id]})
  end

  defp list_entries_students_query(opts) do
    from(
      s in Student,
      left_join: c in assoc(s, :classes),
      as: :classes,
      order_by: [c.name, s.name]
    )
    |> apply_list_entries_students_query_opts(opts)
  end

  defp apply_list_entries_students_query_opts(queryable, []), do: queryable

  defp apply_list_entries_students_query_opts(queryable, [
         {:classes_ids, classes_ids} | opts
       ]) do
    from(
      [_s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_entries_students_query_opts(opts)
  end

  defp apply_list_entries_students_query_opts(queryable, [
         {:active_students_only, true} | opts
       ]) do
    from(
      s in queryable,
      where: is_nil(s.deactivated_at)
    )
    |> apply_list_entries_students_query_opts(opts)
  end

  defp apply_list_entries_students_query_opts(queryable, [_ | opts]),
    do: apply_list_entries_students_query_opts(queryable, opts)

  defp maybe_calculate_has_evidences(students_entries, true) do
    entries_ids =
      students_entries
      |> Enum.map(fn
        {_s, _ap_id, e, _sc} -> e && e.id
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
      {s, ap_id, e, sc} ->
        {
          s,
          ap_id,
          e && e.id && %{e | has_evidences: entries_ids_with_has_evidences_map[e.id]},
          sc
        }

      {s, ap_id, e, sc, is_strand} ->
        {
          s,
          ap_id,
          e && e.id && %{e | has_evidences: entries_ids_with_has_evidences_map[e.id]},
          sc,
          is_strand
        }
    end)
  end

  defp maybe_calculate_has_evidences(students_entries, _), do: students_entries

  @doc """
  Returns the list of strand goals, goal entries, and related moment entries for the given student and strand.

  Assessment points without entries will return `nil`.

  Moments without entries are ignored.

  Ordered by `AssessmentPoint` positions.

  Assessment point fields and preloads:
  - `:has_diff_rubric_for_student` calculated based on student id
  - curriculum item with curriculum component

  """

  @spec list_strand_goals_for_student(student_id :: pos_integer(), strand_id :: pos_integer()) ::
          [
            {AssessmentPoint.t(), AssessmentPointEntry.t() | nil, [AssessmentPointEntry.t()]}
          ]

  def list_strand_goals_for_student(student_id, strand_id) do
    goals =
      from(
        ap in AssessmentPoint,
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        where: ap.strand_id == ^strand_id,
        order_by: ap.position,
        preload: [
          curriculum_item: {ci, curriculum_component: cc}
        ]
      )
      |> Repo.all()

    goals_ids = Enum.map(goals, & &1.id)

    # map goals ids with diff rubrics for the student
    # to set `has_diff_rubric_for_student` later

    goals_ids_with_diff_rubrics_for_student =
      from(
        ap in AssessmentPoint,
        join: r in assoc(ap, :rubric),
        join: diff_r in assoc(r, :differentiation_rubrics),
        join: diff_r_s in "differentiation_rubrics_students",
        on: diff_r_s.student_id == ^student_id and diff_r_s.rubric_id == diff_r.id,
        where: ap.strand_id == ^strand_id,
        select: ap.id
      )
      |> Repo.all()

    goals_and_entries_map =
      from(
        e in AssessmentPointEntry,
        left_join: ov in assoc(e, :ordinal_value),
        left_join: s_ov in assoc(e, :student_ordinal_value),
        where: e.assessment_point_id in ^goals_ids and e.student_id == ^student_id,
        preload: [ordinal_value: ov, student_ordinal_value: s_ov]
      )
      |> Repo.all()
      |> Enum.map(&{&1.assessment_point_id, &1})
      |> Enum.into(%{})

    goals_and_moments_entries_map =
      from(
        ap in AssessmentPoint,
        join: m in assoc(ap, :moment),
        join: e in AssessmentPointEntry,
        on: e.assessment_point_id == ap.id and e.student_id == ^student_id,
        where: m.strand_id == ^strand_id,
        order_by: [asc: m.position, asc: ap.position],
        select: {ap.curriculum_item_id, e}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {ci_id, _e} -> ci_id end,
        fn {_ci_id, e} -> e end
      )

    goals
    |> Enum.map(fn ap ->
      ap = %{ap | has_diff_rubric_for_student: ap.id in goals_ids_with_diff_rubrics_for_student}
      goal_entry = Map.get(goals_and_entries_map, ap.id)
      moments_entries = Map.get(goals_and_moments_entries_map, ap.curriculum_item_id, [])

      {ap, goal_entry, moments_entries}
    end)
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
