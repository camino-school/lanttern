defmodule Lanttern.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Grading.GradeComponent

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of report cards.

  Report cards are ordered by cycle end date (desc) and name (asc)

  ## Options:

  - `:preloads` – preloads associated data
  - `:strands_ids` – filter report cards by strands
  - `:cycles_ids` - filter report cards by cycles
  - `:years_ids` - filter report cards by year

  ## Examples

      iex> list_report_cards()
      [%ReportCard{}, ...]

  """
  def list_report_cards(opts \\ []) do
    from(rc in ReportCard,
      join: sc in assoc(rc, :school_cycle),
      order_by: [desc: sc.end_at, asc: sc.start_at, asc: rc.name]
    )
    |> apply_list_report_cards_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_report_cards_opts(queryable, []), do: queryable

  defp apply_list_report_cards_opts(queryable, [{:strands_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      rc in queryable,
      join: sr in assoc(rc, :strand_reports),
      join: s in assoc(sr, :strand),
      where: s.id in ^ids
    )
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:cycles_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(rc in queryable, where: rc.school_cycle_id in ^ids)
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:years_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(rc in queryable, where: rc.year_id in ^ids)
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [_ | opts]),
    do: apply_list_report_cards_opts(queryable, opts)

  @doc """
  Returns the list of report cards, grouped by cycle.

  Cycles are ordered by end date (desc), and report cards
  in each group ordered by name (asc) — it's the same order
  returned by `list_report_cards/1`, which is used internally.

  See `list_report_cards/1` for options.

  ## Examples

      iex> list_report_cards_by_cycle()
      [{%Cycle{}, [%ReportCard{}, ...]}, ...]

  """

  @spec list_report_cards_by_cycle(Keyword.t()) :: [
          {Cycle.t(), [ReportCard.t()]}
        ]
  def list_report_cards_by_cycle(opts \\ []) do
    report_cards_by_cycle_map =
      list_report_cards(opts)
      |> Enum.group_by(& &1.school_cycle_id)

    Schools.list_cycles(order_by: [desc: :end_at])
    |> Enum.map(&{&1, Map.get(report_cards_by_cycle_map, &1.id)})
    |> Enum.filter(fn {_cycle, report_cards} -> not is_nil(report_cards) end)
  end

  @doc """
  Gets a single report_card.

  Raises `Ecto.NoResultsError` if the Report card does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_report_card!(123)
      %ReportCard{}

      iex> get_report_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_report_card!(id, opts \\ []) do
    ReportCard
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a report_card.

  ## Examples

      iex> create_report_card(%{field: value})
      {:ok, %ReportCard{}}

      iex> create_report_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report_card(attrs \\ %{}) do
    %ReportCard{}
    |> ReportCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a report_card.

  ## Examples

      iex> update_report_card(report_card, %{field: new_value})
      {:ok, %ReportCard{}}

      iex> update_report_card(report_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report_card(%ReportCard{} = report_card, attrs) do
    report_card
    |> ReportCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a report_card.

  ## Examples

      iex> delete_report_card(report_card)
      {:ok, %ReportCard{}}

      iex> delete_report_card(report_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report_card(%ReportCard{} = report_card) do
    Repo.delete(report_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report_card changes.

  ## Examples

      iex> change_report_card(report_card)
      %Ecto.Changeset{data: %ReportCard{}}

  """
  def change_report_card(%ReportCard{} = report_card, attrs \\ %{}) do
    ReportCard.changeset(report_card, attrs)
  end

  @doc """
  Returns the list of strand reports.

  Reports are ordered by position.

  ## Options

      - `:preloads` – preloads associated data
      - `:report_card_id` - filter strand reports by report card

  ## Examples

      iex> list_strands_reports()
      [%StrandReport{}, ...]

  """
  @spec list_strands_reports(Keyword.t()) :: [StrandReport.t()]

  def list_strands_reports(opts \\ []) do
    from(sr in StrandReport,
      order_by: sr.position
    )
    |> apply_list_strands_reports_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_strands_reports_opts(queryable, []), do: queryable

  defp apply_list_strands_reports_opts(queryable, [{:report_card_id, report_card_id} | opts]) do
    from(
      sr in queryable,
      where: sr.report_card_id == ^report_card_id
    )
    |> apply_list_strands_reports_opts(opts)
  end

  defp apply_list_strands_reports_opts(queryable, [_opt | opts]),
    do: apply_list_strands_reports_opts(queryable, opts)

  @doc """
  Gets a single strand_report.

  Returns `nil` if the Strand report does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_strand_report(123)
      %StrandReport{}

      iex> get_strand_report(456)
      nil

  """
  def get_strand_report(id, opts \\ []) do
    StrandReport
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single strand_report.

  Same as `get_strand_report/2`, but raises `Ecto.NoResultsError` if the Strand report does not exist.
  """
  def get_strand_report!(id, opts \\ []) do
    StrandReport
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a strand_report.

  ## Examples

      iex> create_strand_report(%{field: value})
      {:ok, %StrandReport{}}

      iex> create_strand_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_report(attrs \\ %{}) do
    %StrandReport{}
    |> StrandReport.changeset(attrs)
    |> set_strand_report_position()
    |> Repo.insert()
  end

  # skip if not valid
  defp set_strand_report_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_strand_report_position(%Ecto.Changeset{changes: %{position: _position}} = changeset),
    do: changeset

  defp set_strand_report_position(%Ecto.Changeset{} = changeset) do
    report_card_id =
      Ecto.Changeset.get_field(changeset, :report_card_id)

    position =
      from(
        sr in StrandReport,
        where: sr.report_card_id == ^report_card_id,
        select: sr.position,
        order_by: [desc: sr.position],
        limit: 1
      )
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    changeset
    |> Ecto.Changeset.put_change(:position, position)
  end

  @doc """
  Updates a strand_report.

  ## Examples

      iex> update_strand_report(strand_report, %{field: new_value})
      {:ok, %StrandReport{}}

      iex> update_strand_report(strand_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_report(%StrandReport{} = strand_report, attrs) do
    strand_report
    |> StrandReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update strands reports positions based on ids list order.

  ## Examples

      iex> update_strands_reports_positions([3, 2, 1])
      :ok

  """
  @spec update_strands_reports_positions([integer()]) :: :ok | {:error, String.t()}
  def update_strands_reports_positions(strands_reports_ids),
    do: update_positions(StrandReport, strands_reports_ids)

  @doc """
  Deletes a strand_report.

  ## Examples

      iex> delete_strand_report(strand_report)
      {:ok, %StrandReport{}}

      iex> delete_strand_report(strand_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand_report(%StrandReport{} = strand_report) do
    Repo.delete(strand_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand_report changes.

  ## Examples

      iex> change_strand_report(strand_report)
      %Ecto.Changeset{data: %StrandReport{}}

  """
  def change_strand_report(%StrandReport{} = strand_report, attrs \\ %{}) do
    StrandReport.changeset(strand_report, attrs)
  end

  @doc """
  Returns the list of student_report_cards.

  ## Options

  - `:student_id` - filter results by student
  - `:ids` - filter results by given ids
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_student_report_cards()
      [%StudentReportCard{}, ...]

  """
  def list_student_report_cards(opts \\ []) do
    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: c in assoc(rc, :school_cycle),
      order_by: [desc: c.end_at, asc: c.start_at]
    )
    |> apply_list_student_report_cards_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, []), do: queryable

  defp apply_list_student_report_cards_opts(queryable, [{:student_id, student_id} | opts]) do
    from(
      src in queryable,
      where: src.student_id == ^student_id
    )
    |> apply_list_student_report_cards_opts(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, [{:ids, ids} | opts]) do
    from(
      src in queryable,
      where: src.id in ^ids
    )
    |> apply_list_student_report_cards_opts(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, [_ | opts]),
    do: apply_list_student_report_cards_opts(queryable, opts)

  @doc """
  Returns the list of all students and their report cards linked to the
  given base report card.

  Results are ordered by class name, and them by student name.

  ## Options

  - `:classes_ids` - filter results by given classes

  ## Examples

      iex> list_students_with_report_card()
      [{%Student{}, %StudentReportCard{}}, ...]

  """
  @spec list_students_with_report_card(report_card_id :: pos_integer(), Keyword.t()) :: [
          {Student.t(), StudentReportCard.t()}
        ]
  def list_students_with_report_card(report_card_id, opts \\ []) do
    from(
      s in Student,
      left_join: c in assoc(s, :classes),
      as: :classes,
      join: sr in StudentReportCard,
      on: sr.student_id == s.id and sr.report_card_id == ^report_card_id,
      select: {s, sr},
      preload: [classes: c],
      order_by: [asc: c.name, asc: s.name]
    )
    |> apply_list_students_with_report_card_opts(opts)
    |> Repo.all()
  end

  defp apply_list_students_with_report_card_opts(queryable, []), do: queryable

  defp apply_list_students_with_report_card_opts(queryable, [{:classes_ids, classes_ids} | opts])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      [s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_students_with_report_card_opts(opts)
  end

  defp apply_list_students_with_report_card_opts(queryable, [_opt | opts]),
    do: apply_list_students_with_report_card_opts(queryable, opts)

  @doc """
  Returns the list of all students not linked to
  given base report card.

  Results are ordered by class name, and them by student name.

  ## Options

  - `:classes_ids` - filter results by given classes

  ## Examples

      iex> list_students_without_report_card()
      [%Student{}, ...]

  """
  @spec list_students_without_report_card(report_card_id :: pos_integer(), Keyword.t()) :: [
          Student.t()
        ]
  def list_students_without_report_card(report_card_id, opts \\ []) do
    from(
      s in Student,
      left_join: c in assoc(s, :classes),
      as: :classes,
      left_join: sr in StudentReportCard,
      on: sr.student_id == s.id and sr.report_card_id == ^report_card_id,
      preload: [classes: c],
      order_by: [asc: c.name, asc: s.name],
      where: is_nil(sr)
    )
    |> apply_list_students_without_report_card_opts(opts)
    |> Repo.all()
  end

  defp apply_list_students_without_report_card_opts(queryable, []), do: queryable

  defp apply_list_students_without_report_card_opts(queryable, [
         {:classes_ids, classes_ids} | opts
       ])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      [s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_students_without_report_card_opts(opts)
  end

  defp apply_list_students_without_report_card_opts(queryable, [_opt | opts]),
    do: apply_list_students_without_report_card_opts(queryable, opts)

  @doc """
  Gets a single student report card.

  Returns `nil` if the Student report card does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_report_card!(123)
      %StudentReportCard{}

      iex> get_student_report_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_report_card(id, opts \\ []) do
    StudentReportCard
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student report card.

  Same as `get_student_report_card/2`, but raises `Ecto.NoResultsError` if the student report card does not exist.
  """
  def get_student_report_card!(id, opts \\ []) do
    StudentReportCard
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student report card by student and report card id.

  Returns `nil` if the Student report card does not exist.

  ## Examples

      iex> get_student_report_card_by_student_and_parent_report(123, 123)
      %StudentReportCard{}

      iex> get_student_report_card_by_student_and_parent_report(456, 456)
      nil

  """
  @spec get_student_report_card_by_student_and_parent_report(
          student_id :: non_neg_integer(),
          report_card_id :: non_neg_integer()
        ) :: StudentReportCard.t() | nil
  def get_student_report_card_by_student_and_parent_report(student_id, report_card_id) do
    StudentReportCard
    |> Repo.get_by(student_id: student_id, report_card_id: report_card_id)
  end

  @doc """
  Creates a student_report_card.

  ## Examples

      iex> create_student_report_card(%{field: value})
      {:ok, %StudentReportCard{}}

      iex> create_student_report_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_report_card(attrs \\ %{}) do
    %StudentReportCard{}
    |> StudentReportCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_report_card.

  ## Examples

      iex> update_student_report_card(student_report_card, %{field: new_value})
      {:ok, %StudentReportCard{}}

      iex> update_student_report_card(student_report_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_report_card(%StudentReportCard{} = student_report_card, attrs) do
    student_report_card
    |> StudentReportCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates multiple student report cards.

  ## Examples

      iex> batch_update_student_report_card([student_report_card], %{field: new_value})
      {:ok, %{"1" => %StudentReportCard{}}}

      iex> batch_update_student_report_card([student_report_card], %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec batch_update_student_report_card([StudentReportCard.t()], map()) ::
          {:ok, %{pos_integer() => StudentReportCard.t()}} | Ecto.Multi.failure()
  def batch_update_student_report_card(student_report_cards, attrs) do
    Enum.reduce(student_report_cards, Ecto.Multi.new(), fn src, multi ->
      multi
      |> Ecto.Multi.update(
        src.id,
        StudentReportCard.changeset(src, attrs)
      )
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a student_report_card.

  ## Examples

      iex> delete_student_report_card(student_report_card)
      {:ok, %StudentReportCard{}}

      iex> delete_student_report_card(student_report_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_report_card(%StudentReportCard{} = student_report_card) do
    Repo.delete(student_report_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_report_card changes.

  ## Examples

      iex> change_student_report_card(student_report_card)
      %Ecto.Changeset{data: %StudentReportCard{}}

  """
  def change_student_report_card(%StudentReportCard{} = student_report_card, attrs \\ %{}) do
    StudentReportCard.changeset(student_report_card, attrs)
  end

  @doc """
  Returns the list of strand reports linked to the report card, with assessment entries.

  **Preloaded data:**

  - strand reports: strand with subjects and years
  - assessment entries: assessment point, scale, and ordinal value

  ## Examples

      iex> list_student_report_card_strand_reports_and_entries(student_report_card)
      [{%StrandReport{}, [%AssessmentPointEntry{}, ...]}, ...]

  """
  @spec list_student_report_card_strand_reports_and_entries(StudentReportCard.t()) :: [
          {StrandReport.t(), [AssessmentPointEntry.t()]}
        ]

  def list_student_report_card_strand_reports_and_entries(
        %StudentReportCard{} = student_report_card
      ) do
    %{
      report_card_id: report_card_id,
      student_id: student_id
    } = student_report_card

    strand_reports =
      from(sr in StrandReport,
        join: s in assoc(sr, :strand),
        left_join: sub in assoc(s, :subjects),
        left_join: y in assoc(s, :years),
        where: sr.report_card_id == ^report_card_id,
        order_by: sr.position,
        preload: [strand: {s, [subjects: sub, years: y]}]
      )
      |> Repo.all()

    ast_entries_map =
      from(e in AssessmentPointEntry,
        join: sc in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        join: ap in assoc(e, :assessment_point),
        join: s in assoc(ap, :strand),
        join: sr in assoc(s, :strand_reports),
        where: sr.report_card_id == ^report_card_id and e.student_id == ^student_id,
        order_by: ap.position,
        preload: [scale: sc, ordinal_value: ov],
        select: {sr.id, e}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {strand_report_id, _} -> strand_report_id end,
        fn {_, entry} -> entry end
      )

    strand_reports
    |> Enum.map(&{&1, Map.get(ast_entries_map, &1.id, [])})
    |> Enum.filter(fn {_strand_report, entries} -> entries != [] end)
  end

  @doc """
  Returns a list of all assessment points linked to the report card.

  Results are ordered by strand report card and strand goals position.

  Preloads `:strand` and `curriculum_item: :curriculum_component`.

  ## Examples

      iex> list_report_card_assessment_points(report_card_id)
      [%AssessmentPoint{}, ...]

  """
  @spec list_report_card_assessment_points(integer()) :: [AssessmentPoint.t()]
  def list_report_card_assessment_points(report_card_id) do
    from(ap in AssessmentPoint,
      join: s in assoc(ap, :strand),
      join: sr in assoc(s, :strand_reports),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: sr.report_card_id == ^report_card_id,
      order_by: [asc: sr.position, asc: ap.position],
      preload: [strand: s, curriculum_item: {ci, curriculum_component: cc}]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of all grade components that are linked
  to the given subject and report card.

  Results are ordered by grade component position.

  Preloads `assessment_point: [:strand, curriculum_item: :curriculum_component]`.

  ## Examples

      iex> list_report_card_subject_grade_composition(report_card_id, subject_id)
      [%GradeComponent{}, ...]

  """
  @spec list_report_card_subject_grade_composition(
          report_card_id :: integer(),
          subject_id :: integer()
        ) :: [GradeComponent.t()]
  def list_report_card_subject_grade_composition(report_card_id, subject_id) do
    from(gc in GradeComponent,
      join: ap in assoc(gc, :assessment_point),
      join: s in assoc(ap, :strand),
      join: sr in assoc(s, :strand_reports),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: sr.report_card_id == ^report_card_id and gc.subject_id == ^subject_id,
      order_by: gc.position,
      preload: [
        assessment_point: {ap, strand: s, curriculum_item: {ci, curriculum_component: cc}}
      ]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of all classes from students linked to given report card.

  Useful for building report card linked students class filter.

  ## Examples

      iex> list_report_card_linked_students_classes(report_card_id)
      [%Class{}, ...]

  """
  @spec list_report_card_linked_students_classes(report_card_id :: integer()) :: [Class.t()]
  def list_report_card_linked_students_classes(report_card_id) do
    from(c in Class,
      left_join: y in assoc(c, :years),
      join: s in assoc(c, :students),
      join: src in assoc(s, :student_report_cards),
      where: src.report_card_id == ^report_card_id,
      group_by: c.id,
      order_by: [asc: min(y.id), asc: c.name]
    )
    |> Repo.all()
  end
end
