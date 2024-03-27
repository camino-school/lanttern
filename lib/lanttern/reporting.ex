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
  alias Lanttern.Reporting.GradesReport
  alias Lanttern.Reporting.GradesReportSubject
  alias Lanttern.Reporting.GradesReportCycle
  alias Lanttern.Reporting.GradeComponent

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Schools
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
  - `:preloads` – preloads associated data

  ## Examples

      iex> list_student_report_cards()
      [%StudentReportCard{}, ...]

  """
  def list_student_report_cards(opts \\ []) do
    StudentReportCard
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

  defp apply_list_student_report_cards_opts(queryable, [_ | opts]),
    do: apply_list_student_report_cards_opts(queryable, opts)

  @doc """
  Returns the list of all students and their report cards linked to the
  given base report card.

  Results are ordered by class name, and them by student name.

  ## Options

      - `:classes_ids` - filter results by given classes

  ## Examples

      iex> list_students_for_report_card()
      [{%Student{}, %StudentReportCard{}}, ...]

  """
  @spec list_students_for_report_card(integer(), Keyword.t()) :: [
          {Student.t(), StudentReportCard.t() | nil}
        ]
  def list_students_for_report_card(report_card_id, opts \\ []) do
    from(
      s in Student,
      left_join: c in assoc(s, :classes),
      as: :class,
      left_join: sr in StudentReportCard,
      on: sr.student_id == s.id and sr.report_card_id == ^report_card_id,
      select: {s, sr},
      preload: [classes: c],
      order_by: [asc: c.name, asc: s.name]
    )
    |> apply_list_students_for_report_card_opts(opts)
    |> Repo.all()
  end

  defp apply_list_students_for_report_card_opts(queryable, []), do: queryable

  defp apply_list_students_for_report_card_opts(queryable, [{:classes_ids, classes_ids} | opts])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      [s, class: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_students_for_report_card_opts(opts)
  end

  defp apply_list_students_for_report_card_opts(queryable, [_opt | opts]),
    do: apply_list_students_for_report_card_opts(queryable, opts)

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
  end

  @doc """
  Returns the list of grade reports.

  ## Options

  - `:preloads` – preloads associated data
  - `:load_grid` – (bool) preloads school cycle and grades report cycles/subjects (with school cycle/subject preloaded)

  ## Examples

      iex> list_grades_reports()
      [%GradesReport{}, ...]

  """
  def list_grades_reports(opts \\ []) do
    GradesReport
    |> apply_list_grades_reports_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_grades_reports_opts(queryable, []), do: queryable

  defp apply_list_grades_reports_opts(queryable, [{:load_grid, true} | opts]),
    do: apply_list_grades_reports_opts(grid_query(queryable), opts)

  defp apply_list_grades_reports_opts(queryable, [_ | opts]),
    do: apply_list_grades_reports_opts(queryable, opts)

  defp grid_query(queryable) do
    from(
      gr in queryable,
      join: sc in assoc(gr, :school_cycle),
      left_join: grc in assoc(gr, :grades_report_cycles),
      left_join: grc_sc in assoc(grc, :school_cycle),
      left_join: grs in assoc(gr, :grades_report_subjects),
      left_join: grs_s in assoc(grs, :subject),
      order_by: [asc: grc_sc.end_at, desc: grc_sc.start_at, asc: grs.position],
      preload: [
        school_cycle: sc,
        grades_report_cycles: {grc, [school_cycle: grc_sc]},
        grades_report_subjects: {grs, [subject: grs_s]}
      ]
    )
  end

  @doc """
  Gets a single grade report.

  Returns `nil` if the grade report does not exist.

  ## Options:

  - `:preloads` – preloads associated data
  - `:load_grid` – (bool) preloads school cycle and grades report cycles/subjects (with school cycle/subject preloaded)

  ## Examples

      iex> get_grades_report!(123)
      %GradesReport{}

      iex> get_grades_report!(456)
      nil

  """
  def get_grades_report(id, opts \\ []) do
    GradesReport
    |> apply_get_grades_report_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_get_grades_report_opts(queryable, []), do: queryable

  defp apply_get_grades_report_opts(queryable, [{:load_grid, true} | opts]),
    do: apply_get_grades_report_opts(grid_query(queryable), opts)

  defp apply_get_grades_report_opts(queryable, [_ | opts]),
    do: apply_get_grades_report_opts(queryable, opts)

  @doc """
  Gets a single grade report.

  Same as `get_grades_report/2`, but raises `Ecto.NoResultsError` if the grade report does not exist.

  ## Examples

      iex> get_grades_report!(123)
      %GradesReport{}

      iex> get_grades_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_grades_report!(id, opts \\ []) do
    GradesReport
    |> apply_get_grades_report_opts(opts)
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a grade report.

  ## Examples

      iex> create_grades_report(%{field: value})
      {:ok, %GradesReport{}}

      iex> create_grades_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_grades_report(attrs \\ %{}) do
    %GradesReport{}
    |> GradesReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grade report.

  ## Examples

      iex> update_grades_report(grades_report, %{field: new_value})
      {:ok, %ReportCard{}}

      iex> update_grades_report(grades_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_grades_report(%GradesReport{} = grades_report, attrs) do
    grades_report
    |> GradesReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a grade report.

  ## Examples

      iex> delete_grades_report(grades_report)
      {:ok, %ReportCard{}}

      iex> delete_grades_report(grades_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_grades_report(%GradesReport{} = grades_report) do
    Repo.delete(grades_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking grade report changes.

  ## Examples

      iex> change_grades_report(grades_report)
      %Ecto.Changeset{data: %ReportCard{}}

  """
  def change_grades_report(%GradesReport{} = grades_report, attrs \\ %{}) do
    GradesReport.changeset(grades_report, attrs)
  end

  @doc """
  Returns the list of grades report subjects.

  Results are ordered by position and preloaded subjects.

  ## Examples

      iex> list_grades_report_subjects(1)
      [%GradesReportSubject{}, ...]

  """
  @spec list_grades_report_subjects(grades_report_id :: integer()) :: [
          GradesReportSubject.t()
        ]

  def list_grades_report_subjects(grades_report_id) do
    from(grs in GradesReportSubject,
      order_by: grs.position,
      join: s in assoc(grs, :subject),
      preload: [subject: s],
      where: grs.grades_report_id == ^grades_report_id
    )
    |> Repo.all()
  end

  @doc """
  Add a subject to a grades report.

  Result has subject preloaded.

  ## Examples

      iex> add_subject_to_grades_report(%{field: value})
      {:ok, %GradesReportSubject{}}

      iex> add_subject_to_grades_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """

  @spec add_subject_to_grades_report(map()) ::
          {:ok, GradesReportSubject.t()} | {:error, Ecto.Changeset.t()}

  def add_subject_to_grades_report(attrs \\ %{}) do
    %GradesReportSubject{}
    |> GradesReportSubject.changeset(attrs)
    |> set_grades_report_subject_position()
    |> Repo.insert()
    |> maybe_preload(preloads: :subject)
  end

  # skip if not valid
  defp set_grades_report_subject_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_grades_report_subject_position(
         %Ecto.Changeset{changes: %{position: _position}} = changeset
       ),
       do: changeset

  defp set_grades_report_subject_position(%Ecto.Changeset{} = changeset) do
    grades_report_id =
      Ecto.Changeset.get_field(changeset, :grades_report_id)

    position =
      from(
        grs in GradesReportSubject,
        where: grs.grades_report_id == ^grades_report_id,
        select: grs.position,
        order_by: [desc: grs.position],
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
  Update grades report subjects positions based on ids list order.

  ## Examples

  iex> update_grades_report_subjects_positions([3, 2, 1])
  :ok

  """
  @spec update_grades_report_subjects_positions([integer()]) :: :ok | {:error, String.t()}
  def update_grades_report_subjects_positions(grades_report_subjects_ids),
    do: update_positions(GradesReportSubject, grades_report_subjects_ids)

  @doc """
  Deletes a grades report subject.

  ## Examples

      iex> delete_grades_report_subject(grades_report_subject)
      {:ok, %GradesReportSubject{}}

      iex> delete_grades_report_subject(grades_report_subject)
      {:error, %Ecto.Changeset{}}

  """
  def delete_grades_report_subject(%GradesReportSubject{} = grades_report_subject),
    do: Repo.delete(grades_report_subject)

  @doc """
  Returns the list of grades report cycles.

  Results are ordered asc by cycle `end_at` and desc by cycle `start_at`, and have preloaded school cycles.

  ## Examples

  iex> list_grades_report_cycles(1)
  [%GradesReportCycle{}, ...]

  """
  @spec list_grades_report_cycles(grades_report_id :: integer()) :: [
          GradesReportCycle.t()
        ]

  def list_grades_report_cycles(grades_report_id) do
    from(grc in GradesReportCycle,
      join: sc in assoc(grc, :school_cycle),
      preload: [school_cycle: sc],
      where: grc.grades_report_id == ^grades_report_id,
      order_by: [asc: sc.end_at, desc: sc.start_at]
    )
    |> Repo.all()
  end

  @doc """
  Add a cycle to a grades report.

  ## Examples

    iex> add_cycle_to_grades_report(%{field: value})
    {:ok, %GradesReportCycle{}}

    iex> add_cycle_to_grades_report(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """

  @spec add_cycle_to_grades_report(map()) ::
          {:ok, GradesReportCycle.t()} | {:error, Ecto.Changeset.t()}

  def add_cycle_to_grades_report(attrs \\ %{}) do
    %GradesReportCycle{}
    |> GradesReportCycle.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grades_report_cycle.

  ## Examples

      iex> update_grades_report_cycle(grades_report_cycle, %{field: new_value})
      {:ok, %GradesReportCycle{}}

      iex> update_grades_report_cycle(grades_report_cycle, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_grades_report_cycle(%GradesReportCycle{} = grades_report_cycle, attrs) do
    grades_report_cycle
    |> GradesReportCycle.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a grades report cycle.

  ## Examples

    iex> delete_grades_report_cycle(grades_report_cycle)
    {:ok, %GradesReportCycle{}}

    iex> delete_grades_report_cycle(grades_report_cycle)
    {:error, %Ecto.Changeset{}}

  """
  def delete_grades_report_cycle(%GradesReportCycle{} = grades_report_cycle),
    do: Repo.delete(grades_report_cycle)

  @doc """
  Returns the list of grade_components.

  ## Examples

      iex> list_grade_components()
      [%GradeComponent{}, ...]

  """
  def list_grade_components do
    Repo.all(GradeComponent)
  end

  @doc """
  Gets a single grade_component.

  Raises `Ecto.NoResultsError` if the Grade component does not exist.

  ## Examples

      iex> get_grade_component!(123)
      %GradeComponent{}

      iex> get_grade_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_grade_component!(id), do: Repo.get!(GradeComponent, id)

  @doc """
  Creates a grade_component.

  ## Examples

      iex> create_grade_component(%{field: value})
      {:ok, %GradeComponent{}}

      iex> create_grade_component(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_grade_component(attrs \\ %{}) do
    queryable =
      case attrs do
        %{report_card_id: report_card_id, subject_id: subject_id} ->
          from(gc in GradeComponent,
            where: gc.report_card_id == ^report_card_id and gc.subject_id == ^subject_id
          )

        %{"report_card_id" => report_card_id, "subject_id" => subject_id} ->
          from(gc in GradeComponent,
            where: gc.report_card_id == ^report_card_id and gc.subject_id == ^subject_id
          )

        _ ->
          GradeComponent
      end

    attrs = set_position_in_attrs(queryable, attrs)

    %GradeComponent{}
    |> GradeComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grade_component.

  ## Examples

      iex> update_grade_component(grade_component, %{field: new_value})
      {:ok, %GradeComponent{}}

      iex> update_grade_component(grade_component, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_grade_component(%GradeComponent{} = grade_component, attrs) do
    grade_component
    |> GradeComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update grade components positions based on ids list order.

  ## Examples

      iex> update_grade_components_positions([3, 2, 1])
      :ok

  """
  @spec update_grade_components_positions([integer()]) :: :ok | {:error, String.t()}
  def update_grade_components_positions(grade_components_ids),
    do: update_positions(GradeComponent, grade_components_ids)

  @doc """
  Deletes a grade_component.

  ## Examples

      iex> delete_grade_component(grade_component)
      {:ok, %GradeComponent{}}

      iex> delete_grade_component(grade_component)
      {:error, %Ecto.Changeset{}}

  """
  def delete_grade_component(%GradeComponent{} = grade_component) do
    Repo.delete(grade_component)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking grade_component changes.

  ## Examples

      iex> change_grade_component(grade_component)
      %Ecto.Changeset{data: %GradeComponent{}}

  """
  def change_grade_component(%GradeComponent{} = grade_component, attrs \\ %{}) do
    GradeComponent.changeset(grade_component, attrs)
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
end
