defmodule Lanttern.GradesReports do
  @moduledoc """
  The GradesReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.GradesReportCycle
  alias Lanttern.GradesReports.GradesReportSubject
  alias Lanttern.GradesReports.StudentGradesReportEntry
  alias Lanttern.GradesReports.StudentGradesReportFinalEntry
  alias Lanttern.Grading
  alias Lanttern.Grading.GradeComponent
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student

  @doc """
  Returns the list of grade reports.

  ## Options

  - `:preloads` – preloads associated data
  - `:load_grid` – (bool) preloads school cycle and grades report cycles/subjects (with school cycle/subject preloaded)
  - `:school_cycle_id` - filter results by given school cycle
  - `:years_ids` - filter results by given years

  ## Examples

      iex> list_grades_reports()
      [%GradesReport{}, ...]

  """
  def list_grades_reports(opts \\ []) do
    from(
      gr in GradesReport,
      order_by: [asc: gr.year_id]
    )
    |> apply_list_grades_reports_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_grades_reports_opts(queryable, []), do: queryable

  defp apply_list_grades_reports_opts(queryable, [{:load_grid, true} | opts]),
    do: apply_list_grades_reports_opts(grid_query(queryable), opts)

  defp apply_list_grades_reports_opts(queryable, [{:school_cycle_id, id} | opts])
       when is_integer(id) do
    from(
      gr in queryable,
      where: gr.school_cycle_id == ^id
    )
    |> apply_list_grades_reports_opts(opts)
  end

  defp apply_list_grades_reports_opts(queryable, [{:years_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      gr in queryable,
      where: gr.year_id in ^ids
    )
    |> apply_list_grades_reports_opts(opts)
  end

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
  Returns the list of grade reports linked to the given student,
  with grid elements preloaded.

  Grades reports links to student through student report cards:

      grades report
      is linked to report card
      linked to student report card
      linked to student

  Results are ordered by grades report cycle desc.

  Preloads school cycle and grades report cycles/subjects (with school cycle/subject preloaded).

  ## Examples

      iex> list_student_grades_reports_grids(student_id)
      [%GradesReport{}, ...]

  """
  @spec list_student_grades_reports_grids(student_id :: pos_integer()) :: [GradesReport.t()]
  def list_student_grades_reports_grids(student_id) do
    grades_reports =
      from(
        gr in GradesReport,
        join: c in assoc(gr, :school_cycle),
        join: rc in assoc(gr, :report_cards),
        join: src in assoc(rc, :students_report_cards),
        where: src.student_id == ^student_id,
        distinct: [desc: c.end_at, asc: c.start_at, asc: gr.id],
        # any order by, just to make distinct order work
        order_by: gr.name,
        preload: [school_cycle: c]
      )
      |> Repo.all()

    grades_reports_ids = Enum.map(grades_reports, & &1.id)

    grades_reports_cycles_map =
      from(
        gr in GradesReport,
        left_join: grc in assoc(gr, :grades_report_cycles),
        left_join: grc_sc in assoc(grc, :school_cycle),
        where: gr.id in ^grades_reports_ids,
        order_by: [asc: grc_sc.end_at, desc: grc_sc.start_at],
        preload: [grades_report_cycles: {grc, [school_cycle: grc_sc]}]
      )
      |> Repo.all()
      |> Enum.map(&{&1.id, &1.grades_report_cycles})
      |> Enum.into(%{})

    grades_reports_subjects_map =
      from(
        gr in GradesReport,
        left_join: grs in assoc(gr, :grades_report_subjects),
        left_join: grs_s in assoc(grs, :subject),
        where: gr.id in ^grades_reports_ids,
        order_by: [asc: grs.position],
        preload: [grades_report_subjects: {grs, [subject: grs_s]}]
      )
      |> Repo.all()
      |> Enum.map(&{&1.id, &1.grades_report_subjects})
      |> Enum.into(%{})

    # "load" grades reports cycles and subjects and return
    grades_reports
    |> Enum.map(
      &%{
        &1
        | grades_report_cycles: Map.get(grades_reports_cycles_map, &1.id, []),
          grades_report_subjects: Map.get(grades_reports_subjects_map, &1.id, [])
      }
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
  Returns the list of student_grade_report_entries.

  ## Examples

      iex> list_student_grade_report_entries()
      [%StudentGradesReportEntry{}, ...]

  """
  def list_student_grade_report_entries do
    Repo.all(StudentGradesReportEntry)
  end

  @doc """
  Gets a single student_grades_report_entry.

  Raises `Ecto.NoResultsError` if the Student grade report entry does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_grades_report_entry!(123)
      %StudentGradesReportEntry{}

      iex> get_student_grades_report_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_grades_report_entry!(id, opts \\ []) do
    Repo.get!(StudentGradesReportEntry, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_grades_report_entry.

  ## Examples

      iex> create_student_grades_report_entry(%{field: value})
      {:ok, %StudentGradesReportEntry{}}

      iex> create_student_grades_report_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_grades_report_entry(attrs \\ %{}) do
    %StudentGradesReportEntry{}
    |> StudentGradesReportEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_grades_report_entry.

  ## Examples

      iex> update_student_grades_report_entry(student_grades_report_entry, %{field: new_value})
      {:ok, %StudentGradesReportEntry{}}

      iex> update_student_grades_report_entry(student_grades_report_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_grades_report_entry(
        %StudentGradesReportEntry{} = student_grades_report_entry,
        attrs
      ) do
    student_grades_report_entry
    |> StudentGradesReportEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_grades_report_entry.

  ## Examples

      iex> delete_student_grades_report_entry(student_grades_report_entry)
      {:ok, %StudentGradesReportEntry{}}

      iex> delete_student_grades_report_entry(student_grades_report_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_grades_report_entry(
        %StudentGradesReportEntry{} = student_grades_report_entry
      ) do
    Repo.delete(student_grades_report_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_grades_report_entry changes.

  ## Examples

      iex> change_student_grades_report_entry(student_grades_report_entry)
      %Ecto.Changeset{data: %StudentGradesReportEntry{}}

  """
  def change_student_grades_report_entry(
        %StudentGradesReportEntry{} = student_grades_report_entry,
        attrs \\ %{}
      ) do
    StudentGradesReportEntry.changeset(student_grades_report_entry, attrs)
  end

  @doc """
  Gets a single student_grades_report_final_entry.

  Raises `Ecto.NoResultsError` if the Student grade report final entry does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_grades_report_final_entry!(123)
      %StudentGradesReportFinalEntry{}

      iex> get_student_grades_report_final_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_grades_report_final_entry!(id, opts \\ []) do
    Repo.get!(StudentGradesReportFinalEntry, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_grades_report_final_entry.

  ## Examples

      iex> create_student_grades_report_final_entry(%{field: value})
      {:ok, %StudentGradesReportFinalEntry{}}

      iex> create_student_grades_report_final_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_grades_report_final_entry(attrs \\ %{}) do
    %StudentGradesReportFinalEntry{}
    |> StudentGradesReportFinalEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_grades_report_final_entry.

  ## Examples

      iex> update_student_grades_report_final_entry(student_grades_report_final_entry, %{field: new_value})
      {:ok, %StudentGradesReportFinalEntry{}}

      iex> update_student_grades_report_final_entry(student_grades_report_final_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_grades_report_final_entry(
        %StudentGradesReportFinalEntry{} = student_grades_report_final_entry,
        attrs
      ) do
    student_grades_report_final_entry
    |> StudentGradesReportFinalEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_grades_report_final_entry.

  ## Examples

      iex> delete_student_grades_report_final_entry(student_grades_report_final_entry)
      {:ok, %StudentGradesReportEntry{}}

      iex> delete_student_grades_report_final_entry(student_grades_report_final_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_grades_report_final_entry(
        %StudentGradesReportFinalEntry{} = student_grades_report_final_entry
      ) do
    Repo.delete(student_grades_report_final_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_grades_report_final_entry changes.

  ## Examples

      iex> change_student_grades_report_final_entry(student_grades_report_final_entry)
      %Ecto.Changeset{data: %StudentGradesReportFinalEntry{}}

  """
  def change_student_grades_report_final_entry(
        %StudentGradesReportFinalEntry{} = student_grades_report_final_entry,
        attrs \\ %{}
      ) do
    StudentGradesReportFinalEntry.changeset(student_grades_report_final_entry, attrs)
  end

  @doc """
  Returns a list of all grade components that are linked
  to the given grades report subject and cycle.

  Results are ordered by grade component position.

  Preloads `assessment_point: [:strand, curriculum_item: :curriculum_component]`.

  ## Examples

      iex> list_grade_composition(grades_report_cycle_id, grades_report_subject_id)
      [%GradeComponent{}, ...]

  """
  @spec list_grade_composition(
          grades_report_cycle_id :: pos_integer(),
          grades_report_subject_id :: pos_integer()
        ) :: [GradeComponent.t()]
  def list_grade_composition(grades_report_cycle_id, grades_report_subject_id) do
    from(gc in GradeComponent,
      join: ap in assoc(gc, :assessment_point),
      join: s in assoc(ap, :strand),
      join: grc in assoc(gc, :grades_report_cycle),
      join: grs in assoc(gc, :grades_report_subject),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: grc.id == ^grades_report_cycle_id and grs.id == ^grades_report_subject_id,
      order_by: gc.position,
      preload: [
        assessment_point: {ap, strand: s, curriculum_item: {ci, curriculum_component: cc}}
      ]
    )
    |> Repo.all()
  end

  @doc """
  Calculate student grade for given grades report cycle and subject.

  Uses a third elemente in the `:ok` returned tuple:
  - `:created` when the `StudentGradesReportEntry` is created
  - `:updated` when the `StudentGradesReportEntry` is updated
  - `:updated_with_manual` when the `StudentGradesReportEntry` is updated, except from manually adjusted `ordinal_value_id` or `score`
  - `:deleted` when the `StudentGradesReportEntry` is deleted (always `nil` in the second element)
  - `:noop` when the nothing is created, updated, or deleted (always `nil` in the second element)

  ### Options

  - `:force_overwrite` - ignore the update with manual rule, and overwrite grade if needed
  """
  @spec calculate_student_grade(
          student_id :: integer(),
          grades_report_id :: integer(),
          grades_report_cycle_id :: integer(),
          grades_report_subject_id :: integer(),
          Keyword.t()
        ) ::
          {:ok, StudentGradesReportEntry.t() | nil,
           :created | :updated | :updated_keep_manual | :deleted | :noop}
          | {:error, Ecto.Changeset.t()}
  def calculate_student_grade(
        student_id,
        grades_report_id,
        grades_report_cycle_id,
        grades_report_subject_id,
        opts \\ []
      ) do
    # get grades report scale
    %{scale: scale} = get_grades_report!(grades_report_id, preloads: :scale)

    from(
      e in AssessmentPointEntry,
      join: s in assoc(e, :scale),
      left_join: ov in assoc(e, :ordinal_value),
      join: ap in assoc(e, :assessment_point),
      join: st in assoc(ap, :strand),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      join: gc in assoc(ap, :grade_components),
      join: gr in assoc(gc, :grades_report),
      join: grc in assoc(gc, :grades_report_cycle),
      join: grs in assoc(gc, :grades_report_subject),
      # exclude empty entries and entries where there are only student self-assessments
      where: e.has_marking,
      where: e.student_id == ^student_id,
      where: gr.id == ^grades_report_id,
      where: grc.id == ^grades_report_cycle_id,
      where: grs.id == ^grades_report_subject_id,
      order_by: gc.position,
      preload: [ordinal_value: ov, scale: s],
      select: {e, gc, %{curriculum_item: ci, curriculum_component: cc, strand: st}}
    )
    |> Repo.all()
    |> handle_student_grades_report_entry_creation(
      student_id,
      grades_report_id,
      grades_report_cycle_id,
      grades_report_subject_id,
      scale,
      opts
    )
  end

  defp handle_student_grades_report_entry_creation(
         entries_and_grade_components,
         student_id,
         grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         scale,
         opts \\ []
       )

  defp handle_student_grades_report_entry_creation(
         [],
         student_id,
         _grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         _scale,
         _opts
       ) do
    # delete existing student grade report entry if needed
    Repo.get_by(StudentGradesReportEntry,
      student_id: student_id,
      grades_report_cycle_id: grades_report_cycle_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> case do
      nil ->
        {:ok, nil, :noop}

      sgre ->
        case delete_student_grades_report_entry(sgre) do
          {:ok, _} -> {:ok, nil, :deleted}
          error_tuple -> error_tuple
        end
    end
  end

  defp handle_student_grades_report_entry_creation(
         entries_and_grade_components,
         student_id,
         grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         scale,
         opts
       ) do
    {normalized_avg, composition} =
      calculate_weighted_avg_and_build_comp_metadata(entries_and_grade_components)

    scale_value = Grading.convert_normalized_value_to_scale_value(normalized_avg, scale)

    # setup student grade report entry attrs
    attrs =
      case scale_value do
        %OrdinalValue{} = ordinal_value ->
          %{
            ordinal_value_id: ordinal_value.id,
            composition_ordinal_value_id: ordinal_value.id
          }

        score ->
          %{
            score: score,
            composition_score: score
          }
      end
      |> Enum.into(%{
        student_id: student_id,
        grades_report_id: grades_report_id,
        grades_report_cycle_id: grades_report_cycle_id,
        grades_report_subject_id: grades_report_subject_id,
        normalized_value: normalized_avg,
        composition: composition,
        composition_normalized_value: normalized_avg,
        composition_datetime: DateTime.utc_now()
      })

    force_overwrite =
      case Keyword.get(opts, :force_overwrite) do
        true -> true
        _ -> false
      end

    # create or update existing student grade report entry
    Repo.get_by(StudentGradesReportEntry,
      student_id: student_id,
      grades_report_cycle_id: grades_report_cycle_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> create_or_update_student_grades_report_entry(attrs, force_overwrite)
  end

  defp create_or_update_student_grades_report_entry(nil, attrs, _) do
    case create_student_grades_report_entry(attrs) do
      {:ok, sgre} -> {:ok, sgre, :created}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_entry(
         %{ordinal_value_id: ov_id, composition_ordinal_value_id: comp_ov_id} = sgre,
         attrs,
         false
       )
       when ov_id != comp_ov_id do
    attrs = Map.drop(attrs, [:ordinal_value_id])

    case update_student_grades_report_entry(sgre, attrs) do
      {:ok, sgre} -> {:ok, sgre, :updated_with_manual}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_entry(
         %{score: score, composition_score: comp_score} = sgre,
         attrs,
         false
       )
       when score != comp_score do
    attrs = Map.drop(attrs, [:score])

    case update_student_grades_report_entry(sgre, attrs) do
      {:ok, sgre} -> {:ok, sgre, :updated_with_manual}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_entry(sgre, attrs, _force_overwrite) do
    case update_student_grades_report_entry(sgre, attrs) do
      {:ok, sgre} -> {:ok, sgre, :updated}
      error_tuple -> error_tuple
    end
  end

  defp calculate_weighted_avg_and_build_comp_metadata(
         entries_and_grade_components,
         sumprod \\ 0,
         sumweight \\ 0,
         composition \\ []
       )

  defp calculate_weighted_avg_and_build_comp_metadata([], sumprod, sumweight, composition) do
    normalized_avg = Float.round(sumprod / sumweight, 5)
    {normalized_avg, composition}
  end

  defp calculate_weighted_avg_and_build_comp_metadata(
         [{e, gc, metadata} | entries_and_grade_components],
         sumprod,
         sumweight,
         composition
       ) do
    entry_normalized_value = get_normalized_value_from_entry(e)

    comp_component =
      build_comp_component(metadata, e, gc, entry_normalized_value)

    sumprod = entry_normalized_value * gc.weight + sumprod
    sumweight = gc.weight + sumweight
    composition = composition ++ [comp_component]

    calculate_weighted_avg_and_build_comp_metadata(
      entries_and_grade_components,
      sumprod,
      sumweight,
      composition
    )
  end

  defp get_normalized_value_from_entry(%AssessmentPointEntry{scale_type: "ordinal"} = entry),
    do: entry.ordinal_value.normalized_value

  defp get_normalized_value_from_entry(%AssessmentPointEntry{scale_type: "numeric"} = entry),
    do: (entry.score - entry.scale.start) / (entry.scale.stop - entry.scale.start)

  defp build_comp_component(
         metadata,
         %AssessmentPointEntry{} = e,
         %GradeComponent{} = gc,
         entry_normalized_value
       ) do
    %{
      strand_id: metadata.strand.id,
      strand_name: metadata.strand.name,
      strand_type: metadata.strand.type,
      curriculum_item_id: metadata.curriculum_item.id,
      curriculum_item_name: metadata.curriculum_item.name,
      curriculum_component_id: metadata.curriculum_component.id,
      curriculum_component_name: metadata.curriculum_component.name,
      ordinal_value_id: if(e.ordinal_value, do: e.ordinal_value.id),
      ordinal_value_name: if(e.ordinal_value, do: e.ordinal_value.name),
      weight: gc.weight,
      score: e.score,
      normalized_value: entry_normalized_value
    }
  end

  @type batch_calculation_results() :: %{
          created: integer(),
          updated: integer(),
          updated_with_manual: integer(),
          deleted: integer(),
          noop: integer()
        }

  @doc """
  Calculate student grades for all subjects in given grades report cycle.
  """
  @spec calculate_student_grades(
          student_id :: integer(),
          grades_report_id :: integer(),
          grades_report_cycle_id :: integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_student_grades(student_id, grades_report_id, grades_report_cycle_id) do
    # get grades report scale and all report subjects
    %{
      scale: scale,
      grades_report_subjects: grades_report_subjects
    } =
      get_grades_report!(grades_report_id,
        preloads: [:scale, :grades_report_subjects]
      )

    grades_report_subject_entries_grade_components =
      from(
        e in AssessmentPointEntry,
        join: s in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        join: ap in assoc(e, :assessment_point),
        join: st in assoc(ap, :strand),
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        join: gc in assoc(ap, :grade_components),
        join: gr in assoc(gc, :grades_report),
        join: grc in assoc(gc, :grades_report_cycle),
        join: grs in assoc(gc, :grades_report_subject),
        # exclude empty entries and entries where there are only student self-assessments
        where: e.has_marking,
        where: e.student_id == ^student_id,
        where: grc.id == ^grades_report_cycle_id,
        order_by: gc.position,
        preload: [ordinal_value: ov, scale: s],
        select: {e, gc, %{curriculum_item: ci, curriculum_component: cc, strand: st}, grs.id}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {_e, _gc, _metadata, grs_id} -> grs_id end,
        fn {e, gc, metadata, _grs_id} -> {e, gc, metadata} end
      )

    grades_report_subjects
    |> Enum.map(fn grades_report_subject ->
      {
        student_id,
        grades_report_subject.id,
        Map.get(
          grades_report_subject_entries_grade_components,
          grades_report_subject.id,
          []
        )
      }
    end)
    |> handle_grades_batch_calculation_results(
      grades_report_id,
      grades_report_cycle_id,
      scale
    )
  end

  @doc """
  Calculate subject grades for given students and grades report cycle.
  """
  @spec calculate_subject_grades(
          students_ids :: [integer()],
          grades_report_id :: integer(),
          grades_report_cycle_id :: integer(),
          grades_report_subject_id :: integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_subject_grades(
        students_ids,
        grades_report_id,
        grades_report_cycle_id,
        grades_report_subject_id
      ) do
    # get grades report scale
    %{scale: scale} = get_grades_report!(grades_report_id, preloads: :scale)

    students_entries_grade_components =
      from(
        e in AssessmentPointEntry,
        join: s in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        join: ap in assoc(e, :assessment_point),
        join: st in assoc(ap, :strand),
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        join: gc in assoc(ap, :grade_components),
        join: gr in assoc(gc, :grades_report),
        join: grc in assoc(gc, :grades_report_cycle),
        join: grs in assoc(gc, :grades_report_subject),
        # exclude empty entries and entries where there are only student self-assessments
        where: e.has_marking,
        where: e.student_id in ^students_ids,
        where: gr.id == ^grades_report_id,
        where: grc.id == ^grades_report_cycle_id,
        where: grs.id == ^grades_report_subject_id,
        order_by: gc.position,
        preload: [ordinal_value: ov, scale: s],
        select:
          {e, gc, %{curriculum_item: ci, curriculum_component: cc, strand: st}, e.student_id}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {_e, _gc, _metadata, std_id} -> std_id end,
        fn {e, gc, metadata, _std_id} -> {e, gc, metadata} end
      )

    students_ids
    |> Enum.map(fn student_id ->
      {
        student_id,
        grades_report_subject_id,
        Map.get(
          students_entries_grade_components,
          student_id,
          []
        )
      }
    end)
    |> handle_grades_batch_calculation_results(
      grades_report_id,
      grades_report_cycle_id,
      scale
    )
  end

  @doc """
  Calculate all grades for given students and grades report cycle.
  """
  @spec calculate_cycle_grades(
          students_ids :: [integer()],
          grades_report_id :: integer(),
          grades_report_cycle_id :: integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_cycle_grades(
        students_ids,
        grades_report_id,
        grades_report_cycle_id
      ) do
    # get grades report scale and all report subjects
    %{
      scale: scale,
      grades_report_subjects: grades_report_subjects
    } =
      get_grades_report!(grades_report_id,
        preloads: [:scale, :grades_report_subjects]
      )

    students_grades_report_subject_entries_grade_components =
      from(
        e in AssessmentPointEntry,
        join: s in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        join: ap in assoc(e, :assessment_point),
        join: st in assoc(ap, :strand),
        join: ci in assoc(ap, :curriculum_item),
        join: cc in assoc(ci, :curriculum_component),
        join: gc in assoc(ap, :grade_components),
        join: gr in assoc(gc, :grades_report),
        join: grc in assoc(gc, :grades_report_cycle),
        join: grs in assoc(gc, :grades_report_subject),
        # exclude empty entries and entries where there are only student self-assessments
        where: e.has_marking,
        where: e.student_id in ^students_ids,
        where: gr.id == ^grades_report_id,
        where: grc.id == ^grades_report_cycle_id,
        order_by: gc.position,
        preload: [ordinal_value: ov, scale: s],
        select:
          {e, gc, %{curriculum_item: ci, curriculum_component: cc, strand: st}, grs.id,
           e.student_id}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {_e, _gc, _metadata, grs_id, std_id} -> "#{std_id}_#{grs_id}" end,
        fn {e, gc, metadata, _grs_id, _std_id} -> {e, gc, metadata} end
      )

    students_ids
    |> Enum.flat_map(fn student_id ->
      grades_report_subjects
      |> Enum.map(&{student_id, &1.id})
    end)
    |> Enum.map(fn {std_id, grs_id} ->
      {
        std_id,
        grs_id,
        Map.get(
          students_grades_report_subject_entries_grade_components,
          "#{std_id}_#{grs_id}",
          []
        )
      }
    end)
    |> handle_grades_batch_calculation_results(
      grades_report_id,
      grades_report_cycle_id,
      scale
    )
  end

  defp handle_grades_batch_calculation_results(
         student_grades_report_subject_entries_and_grade_components,
         grades_report_id,
         grades_report_cycle_id,
         scale,
         results \\ %{created: 0, updated: 0, updated_with_manual: 0, deleted: 0, noop: 0}
       )

  defp handle_grades_batch_calculation_results(
         [],
         _grades_report_id,
         _grades_report_cycle_id,
         _scale,
         results
       ),
       do: {:ok, results}

  defp handle_grades_batch_calculation_results(
         [
           {std_id, grs_id, entries_and_grade_components}
           | student_grades_report_subject_entries_and_grade_components
         ],
         grades_report_id,
         grades_report_cycle_id,
         scale,
         results
       ) do
    handle_student_grades_report_entry_creation(
      entries_and_grade_components,
      std_id,
      grades_report_id,
      grades_report_cycle_id,
      grs_id,
      scale
    )
    |> case do
      {:ok, _result, operation} ->
        handle_grades_batch_calculation_results(
          student_grades_report_subject_entries_and_grade_components,
          grades_report_id,
          grades_report_cycle_id,
          scale,
          Map.update!(results, operation, &(&1 + 1))
        )

      {:error, changeset} ->
        {:error, changeset, results}
    end
  end

  @doc """
  Calculate student final grade for a given grades report and subject.

  Uses a third elemente in the `:ok` returned tuple:
  - `:created` when the `StudentGradesReportFinalEntry` is created
  - `:updated` when the `StudentGradesReportFinalEntry` is updated
  - `:updated_with_manual` when the `StudentGradesReportFinalEntry` is updated, except from manually adjusted `ordinal_value_id` or `score`
  - `:deleted` when the `StudentGradesReportFinalEntry` is deleted (always `nil` in the second element)
  - `:noop` when the nothing is created, updated, or deleted (always `nil` in the second element)

  ### Options

  - `:force_overwrite` - ignore the update with manual rule, and overwrite grade if needed
  """
  @spec calculate_student_final_grade(
          student_id :: integer(),
          grades_report_id :: integer(),
          grades_report_subject_id :: integer(),
          Keyword.t()
        ) ::
          {:ok, StudentGradesReportEntry.t() | nil,
           :created | :updated | :updated_keep_manual | :deleted | :noop}
          | {:error, Ecto.Changeset.t()}
  def calculate_student_final_grade(
        student_id,
        grades_report_id,
        grades_report_subject_id,
        opts \\ []
      ) do
    # get grades report scale
    %{scale: scale} = get_grades_report!(grades_report_id, preloads: :scale)

    from(
      sgre in StudentGradesReportEntry,
      left_join: ov in assoc(sgre, :ordinal_value),
      join: grc in assoc(sgre, :grades_report_cycle),
      join: sc in assoc(grc, :school_cycle),
      where: sgre.student_id == ^student_id,
      where: sgre.grades_report_id == ^grades_report_id,
      where: sgre.grades_report_subject_id == ^grades_report_subject_id,
      order_by: sc.start_at,
      preload: [ordinal_value: ov],
      select: {sgre, sc, grc.weight}
    )
    |> Repo.all()
    |> handle_student_grades_report_final_entry_creation(
      student_id,
      grades_report_id,
      grades_report_subject_id,
      scale,
      opts
    )
  end

  defp handle_student_grades_report_final_entry_creation(
         student_grades_report_entries_cycles_and_weight,
         student_id,
         grades_report_id,
         grades_report_subject_id,
         scale,
         opts \\ []
       )

  defp handle_student_grades_report_final_entry_creation(
         [],
         student_id,
         _grades_report_id,
         grades_report_subject_id,
         _scale,
         _opts
       ) do
    # delete existing student grade report entry if needed
    Repo.get_by(StudentGradesReportFinalEntry,
      student_id: student_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> case do
      nil ->
        {:ok, nil, :noop}

      sgrfe ->
        case delete_student_grades_report_final_entry(sgrfe) do
          {:ok, _} -> {:ok, nil, :deleted}
          error_tuple -> error_tuple
        end
    end
  end

  defp handle_student_grades_report_final_entry_creation(
         student_grades_report_entries_cycles_and_weight,
         student_id,
         grades_report_id,
         grades_report_subject_id,
         scale,
         opts
       ) do
    {normalized_avg, composition} =
      calculate_weighted_avg_and_build_final_comp_metadata(
        student_grades_report_entries_cycles_and_weight
      )

    scale_value = Grading.convert_normalized_value_to_scale_value(normalized_avg, scale)

    # setup student grade report final entry attrs
    attrs =
      case scale_value do
        %OrdinalValue{} = ordinal_value ->
          %{
            ordinal_value_id: ordinal_value.id,
            composition_ordinal_value_id: ordinal_value.id
          }

        score ->
          %{
            score: score,
            composition_score: score
          }
      end
      |> Enum.into(%{
        student_id: student_id,
        grades_report_id: grades_report_id,
        grades_report_subject_id: grades_report_subject_id,
        composition: composition,
        composition_normalized_value: normalized_avg,
        composition_datetime: DateTime.utc_now()
      })

    force_overwrite =
      case Keyword.get(opts, :force_overwrite) do
        true -> true
        _ -> false
      end

    # create or update existing student grade report entry
    Repo.get_by(StudentGradesReportFinalEntry,
      student_id: student_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> create_or_update_student_grades_report_final_entry(attrs, force_overwrite)
  end

  defp create_or_update_student_grades_report_final_entry(nil, attrs, _) do
    case create_student_grades_report_final_entry(attrs) do
      {:ok, sgrfe} -> {:ok, sgrfe, :created}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_final_entry(
         %{ordinal_value_id: ov_id, composition_ordinal_value_id: comp_ov_id} = sgrfe,
         attrs,
         false
       )
       when ov_id != comp_ov_id do
    attrs = Map.drop(attrs, [:ordinal_value_id])

    case update_student_grades_report_final_entry(sgrfe, attrs) do
      {:ok, sgrfe} -> {:ok, sgrfe, :updated_with_manual}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_final_entry(
         %{score: score, composition_score: comp_score} = sgrfe,
         attrs,
         false
       )
       when score != comp_score do
    attrs = Map.drop(attrs, [:score])

    case update_student_grades_report_final_entry(sgrfe, attrs) do
      {:ok, sgrfe} -> {:ok, sgrfe, :updated_with_manual}
      error_tuple -> error_tuple
    end
  end

  defp create_or_update_student_grades_report_final_entry(sgrfe, attrs, _force_overwrite) do
    case update_student_grades_report_final_entry(sgrfe, attrs) do
      {:ok, sgrfe} -> {:ok, sgrfe, :updated}
      error_tuple -> error_tuple
    end
  end

  defp calculate_weighted_avg_and_build_final_comp_metadata(
         student_grades_report_entries_cycles_and_weight,
         sumprod \\ 0,
         sumweight \\ 0,
         composition \\ []
       )

  defp calculate_weighted_avg_and_build_final_comp_metadata([], sumprod, sumweight, composition) do
    normalized_avg = Float.round(sumprod / sumweight, 5)
    {normalized_avg, composition}
  end

  defp calculate_weighted_avg_and_build_final_comp_metadata(
         [{sgre, sc, weight} | student_grades_report_entries_cycles_and_weight],
         sumprod,
         sumweight,
         composition
       ) do
    cycle_composition =
      build_cycle_composition(sgre, sc, sgre.normalized_value, weight)

    sumprod = sgre.normalized_value * weight + sumprod
    sumweight = weight + sumweight
    composition = composition ++ [cycle_composition]

    calculate_weighted_avg_and_build_final_comp_metadata(
      student_grades_report_entries_cycles_and_weight,
      sumprod,
      sumweight,
      composition
    )
  end

  defp build_cycle_composition(
         %StudentGradesReportEntry{} = sgre,
         %Cycle{} = sc,
         entry_normalized_value,
         weight
       ) do
    %{
      school_cycle_id: sc.id,
      school_cycle_name: sc.name,
      ordinal_value_id: sgre.ordinal_value && sgre.ordinal_value.id,
      ordinal_value_name: sgre.ordinal_value && sgre.ordinal_value.name,
      score: sgre.score,
      normalized_value: entry_normalized_value,
      weight: weight
    }
  end

  @doc """
  Calculate student final grades for all subjects in given grades report.
  """
  @spec calculate_student_final_grades(
          student_id :: pos_integer(),
          grades_report_id :: pos_integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_student_final_grades(student_id, grades_report_id) do
    # get grades report scale and all report subjects
    %{
      scale: scale,
      grades_report_subjects: grades_report_subjects
    } =
      get_grades_report!(grades_report_id,
        preloads: [:scale, :grades_report_subjects]
      )

    grades_report_subject_entries_cycles_and_weight =
      from(
        sgre in StudentGradesReportEntry,
        left_join: ov in assoc(sgre, :ordinal_value),
        join: grc in assoc(sgre, :grades_report_cycle),
        join: sc in assoc(grc, :school_cycle),
        where: sgre.student_id == ^student_id,
        where: sgre.grades_report_id == ^grades_report_id,
        order_by: sc.start_at,
        preload: [ordinal_value: ov],
        select: {sgre, sc, grc.weight}
      )
      |> Repo.all()
      |> Enum.group_by(fn {sgre, _sc, _weight} -> sgre.grades_report_subject_id end)

    grades_report_subjects
    |> Enum.map(fn grades_report_subject ->
      {
        student_id,
        grades_report_subject.id,
        Map.get(
          grades_report_subject_entries_cycles_and_weight,
          grades_report_subject.id,
          []
        )
      }
    end)
    |> handle_final_grades_batch_calculation_results(
      grades_report_id,
      scale
    )
  end

  @doc """
  Calculate final grades for given students, subject, and grades report.
  """
  @spec calculate_subject_final_grades(
          students_ids :: [pos_integer()],
          grades_report_id :: pos_integer(),
          grades_report_subject_id :: pos_integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_subject_final_grades(students_ids, grades_report_id, grades_report_subject_id) do
    # get grades report scale
    %{scale: scale} = get_grades_report!(grades_report_id, preloads: [:scale])

    grades_report_student_entries_cycles_and_weight =
      from(
        sgre in StudentGradesReportEntry,
        left_join: ov in assoc(sgre, :ordinal_value),
        join: grc in assoc(sgre, :grades_report_cycle),
        join: sc in assoc(grc, :school_cycle),
        where: sgre.student_id in ^students_ids,
        where: sgre.grades_report_id == ^grades_report_id,
        where: sgre.grades_report_subject_id == ^grades_report_subject_id,
        order_by: sc.start_at,
        preload: [ordinal_value: ov],
        select: {sgre, sc, grc.weight}
      )
      |> Repo.all()
      |> Enum.group_by(fn {sgre, _sc, _weight} -> sgre.student_id end)

    students_ids
    |> Enum.map(fn student_id ->
      {
        student_id,
        grades_report_subject_id,
        Map.get(
          grades_report_student_entries_cycles_and_weight,
          student_id,
          []
        )
      }
    end)
    |> handle_final_grades_batch_calculation_results(
      grades_report_id,
      scale
    )
  end

  @doc """
  Calculate final grades for all subjects and given students and grades report.
  """
  @spec calculate_grades_report_final_grades(
          students_ids :: [pos_integer()],
          grades_report_id :: pos_integer()
        ) ::
          {:ok, batch_calculation_results()}
          | {:error, Ecto.Changeset.t(), batch_calculation_results()}
  def calculate_grades_report_final_grades(students_ids, grades_report_id) do
    # get grades report scale and all report subjects
    %{
      scale: scale,
      grades_report_subjects: grades_report_subjects
    } =
      get_grades_report!(grades_report_id,
        preloads: [:scale, :grades_report_subjects]
      )

    grades_report_entries_cycles_and_weight =
      from(
        sgre in StudentGradesReportEntry,
        left_join: ov in assoc(sgre, :ordinal_value),
        join: grc in assoc(sgre, :grades_report_cycle),
        join: sc in assoc(grc, :school_cycle),
        where: sgre.student_id in ^students_ids,
        where: sgre.grades_report_id == ^grades_report_id,
        order_by: sc.start_at,
        preload: [ordinal_value: ov],
        select: {sgre, sc, grc.weight}
      )
      |> Repo.all()
      |> Enum.group_by(fn {sgre, _sc, _weight} ->
        "#{sgre.student_id}_#{sgre.grades_report_subject_id}"
      end)

    students_ids
    |> Enum.flat_map(fn student_id ->
      grades_report_subjects
      |> Enum.map(&{student_id, &1.id})
    end)
    |> Enum.map(fn {std_id, grs_id} ->
      {
        std_id,
        grs_id,
        Map.get(
          grades_report_entries_cycles_and_weight,
          "#{std_id}_#{grs_id}",
          []
        )
      }
    end)
    |> handle_final_grades_batch_calculation_results(
      grades_report_id,
      scale
    )
  end

  defp handle_final_grades_batch_calculation_results(
         students_grades_report_subjects_entries_cycles_and_weights,
         grades_report_id,
         scale,
         results \\ %{created: 0, updated: 0, updated_with_manual: 0, deleted: 0, noop: 0}
       )

  defp handle_final_grades_batch_calculation_results(
         [],
         _grades_report_id,
         _scale,
         results
       ),
       do: {:ok, results}

  defp handle_final_grades_batch_calculation_results(
         [
           {std_id, grades_report_subject_id, entries_cycles_and_weights}
           | students_grades_report_subjects_entries_cycles_and_weights
         ],
         grades_report_id,
         scale,
         results
       ) do
    handle_student_grades_report_final_entry_creation(
      entries_cycles_and_weights,
      std_id,
      grades_report_id,
      grades_report_subject_id,
      scale
    )
    |> case do
      {:ok, _result, operation} ->
        handle_final_grades_batch_calculation_results(
          students_grades_report_subjects_entries_cycles_and_weights,
          grades_report_id,
          scale,
          Map.update!(results, operation, &(&1 + 1))
        )

      {:error, changeset} ->
        {:error, changeset, results}
    end
  end

  @doc """
  Returns a map in the format

      %{
        student_id => %{
          grades_report_cycle_id => %{
            grades_report_subject_id => %StudentGradesReportEntry{},
            # other subjects ids...
          },
          # other cycles ids...
          final => %{
            grades_report_subject_id => %StudentGradesReportFinalEntry{},
            # other subjects ids...
          }
        }
        # other students ids...
      }

  for the given students and grades report.
  """
  @spec build_students_full_grades_report_map(grades_report_id :: pos_integer()) :: map()
  def build_students_full_grades_report_map(grades_report_id) do
    grades_report_students_query =
      from(
        std in Student,
        join: sgre in assoc(std, :grades_report_entries),
        where: sgre.grades_report_id == ^grades_report_id,
        distinct: true
      )

    final_entries_map =
      from(
        std in subquery(grades_report_students_query),
        join: grs in GradesReportSubject,
        on: grs.grades_report_id == ^grades_report_id,
        left_join: sgrfe in StudentGradesReportFinalEntry,
        on:
          sgrfe.grades_report_subject_id == grs.id and
            sgrfe.student_id == std.id,
        select: {std.id, grs.id, sgrfe}
      )
      |> Repo.all()
      |> Enum.reduce(%{}, fn {std_id, grs_id, sgrfe}, acc ->
        # clear composition to save memory
        sgrfe =
          case sgrfe do
            nil ->
              nil

            sgrfe ->
              %{sgrfe | composition: nil}
          end

        # get or create student map
        std_map = Map.get(acc, std_id, %{})

        # add subject to student map
        std_map = Map.put(std_map, grs_id, sgrfe)

        Map.put(acc, std_id, std_map)
      end)

    from(
      std in subquery(grades_report_students_query),
      join: grs in GradesReportSubject,
      on: grs.grades_report_id == ^grades_report_id,
      join: grc in GradesReportCycle,
      on: grc.grades_report_id == ^grades_report_id,
      left_join: sgre in StudentGradesReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == std.id,
      select: {std.id, grc.id, grs.id, sgre}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {std_id, grc_id, grs_id, sgre}, acc ->
      # clear composition to save memory
      sgre =
        case sgre do
          nil ->
            nil

          sgre ->
            %{sgre | composition: nil}
        end

      # get or create student map
      std_map = Map.get(acc, std_id, %{})

      # get or create cycle map and put entry in subject
      cycle_map =
        std_map
        |> Map.get(grc_id, %{})
        |> Map.put(grs_id, sgre)

      std_map =
        std_map
        # update/add cycle to student map
        |> Map.put(grc_id, cycle_map)
        # put final entries in map
        |> Map.put(:final, final_entries_map[std_id])

      Map.put(acc, std_id, std_map)
    end)
  end

  @doc """
  Returns a map in the format

      %{
        student_id => %{
          subject_id => %StudentGradesReportEntry{},
          # other subjects ids...
        }
        # other students ids...
      }

  for the given students, grades report and cycle.
  """
  @spec build_students_grades_cycle_map(
          students_ids :: [pos_integer()],
          grades_report_id :: pos_integer(),
          cycle_id :: pos_integer()
        ) :: %{}
  def build_students_grades_cycle_map(students_ids, grades_report_id, cycle_id) do
    from(
      std in Student,
      join: grs in GradesReportSubject,
      on: true,
      join: grc in GradesReportCycle,
      on: grc.grades_report_id == grs.grades_report_id,
      left_join: sgre in StudentGradesReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == std.id,
      where: std.id in ^students_ids,
      where: grc.grades_report_id == ^grades_report_id,
      where: grc.school_cycle_id == ^cycle_id,
      select: {std.id, grs.id, sgre}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {std_id, grs_id, sgre}, acc ->
      # clear composition to save memory
      sgre =
        case sgre do
          nil ->
            nil

          sgre ->
            %{sgre | composition: nil}
        end

      # build student map
      std_map =
        Map.get(acc, std_id, %{})
        |> Map.put(grs_id, sgre)

      Map.put(acc, std_id, std_map)
    end)
  end

  @doc """
  Returns a map in the format

      %{
        cycle_id => %{
          grades_report_subject_id => %StudentGradesReportEntry{},
          # other subjects ids...
        },
        # other cycles ids...
        :final => %{
          grades_report_subject_id => %StudentGradesReportFinalEntry{},
          # other subjects ids...
        }
      }

  for the given student report card id.

  Removes `composition` from returned `StudentGradesReportEntry` to save memory.

  Ordinal values preloaded (manually) in student grade report entry.
  """
  @spec build_student_grades_map(student_report_card_id :: pos_integer()) :: map()
  def build_student_grades_map(student_report_card_id) do
    final_grades_map =
      from(
        src in StudentReportCard,
        join: rc in assoc(src, :report_card),
        join: gr in assoc(rc, :grades_report),
        join: grs in assoc(gr, :grades_report_subjects),
        left_join: sgrfe in StudentGradesReportFinalEntry,
        on:
          sgrfe.grades_report_subject_id == grs.id and
            sgrfe.student_id == src.student_id and
            gr.final_is_visible,
        where: src.id == ^student_report_card_id,
        select: {grs.id, sgrfe}
      )
      |> Repo.all()
      |> Enum.into(%{})

    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: gr in assoc(rc, :grades_report),
      join: grc in assoc(gr, :grades_report_cycles),
      on: grc.is_visible,
      join: grs in assoc(gr, :grades_report_subjects),
      left_join: sgre in StudentGradesReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == src.student_id,
      where: src.id == ^student_report_card_id,
      select: {grc.id, grs.id, sgre}
    )
    |> Repo.all()
    |> Enum.map(fn {grc_id, grs_id, sgre} ->
      {grc_id, grs_id, sgre && %{sgre | composition: nil}}
    end)
    |> build_grades_report_cycle_subject_map()
    |> Map.put(:final, final_grades_map)
  end

  @doc """
  Returns a map in the format

      %{
        grades_report_id => %{
          grades_report_cycle_id => %{
            grades_report_subject_id => %StudentGradesReportEntry{},
            # other subjects ids...
          },
          # other cycles ids...
          :final => %{
            grades_report_subject_id => %StudentGradesReportFinalEntry{},
          }
        },
        # other grades reports...
      }

  for the given student and grades reports.

  Removes `composition` from returned `StudentGradesReportEntry` to save memory.
  """
  @spec build_student_grades_maps(
          student_id :: pos_integer(),
          grades_reports_ids :: [pos_integer()]
        ) :: map()
  def build_student_grades_maps(student_id, grades_reports_ids) do
    final_student_grades_maps =
      from(
        gr in GradesReport,
        join: grs in assoc(gr, :grades_report_subjects),
        left_join: sgrfe in StudentGradesReportFinalEntry,
        on:
          sgrfe.grades_report_subject_id == grs.id and
            sgrfe.student_id == ^student_id,
        # and gr.final_is_visible,
        where: gr.id in ^grades_reports_ids,
        select: {gr.id, grs.id, sgrfe}
      )
      |> Repo.all()
      # remove composition from sgrfe to save memory while grouping
      |> Enum.group_by(
        fn {gr_id, _, _} -> gr_id end,
        fn {_, grs_id, sgrfe} ->
          {grs_id, sgrfe && %{sgrfe | composition: nil}}
        end
      )
      |> Enum.map(fn {gr_id, grs_id_sgrfe_tuples} ->
        {
          gr_id,
          Enum.into(grs_id_sgrfe_tuples, %{})
        }
      end)
      |> Enum.into(%{})

    from(
      gr in GradesReport,
      join: grc in assoc(gr, :grades_report_cycles),
      # on: grc.is_visible,
      join: grs in assoc(gr, :grades_report_subjects),
      left_join: sgre in StudentGradesReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == ^student_id,
      where: gr.id in ^grades_reports_ids,
      select: {gr.id, grc.id, grs.id, sgre}
    )
    |> Repo.all()
    # remove composition from sgre to save memory while grouping
    |> Enum.group_by(
      fn {gr_id, _, _, _} -> gr_id end,
      fn {_, grc_id, grs_id, sgre} ->
        {grc_id, grs_id, sgre && %{sgre | composition: nil}}
      end
    )
    |> Enum.map(fn {gr_id, rest} ->
      {
        gr_id,
        build_grades_report_cycle_subject_map(rest)
        |> Map.put(:final, final_student_grades_maps[gr_id])
      }
    end)
    |> Enum.into(%{})
  end

  defp build_grades_report_cycle_subject_map(grades_reports_cycles_subjects_entries) do
    grades_reports_cycles_subjects_entries
    |> Enum.reduce(%{}, fn {grc_id, grs_id, sgre}, acc ->
      # build cycle map
      cycle_map =
        Map.get(acc, grc_id, %{})
        |> Map.put(grs_id, sgre)

      Map.put(acc, grc_id, cycle_map)
    end)
  end

  @doc """
  Returns the list of students linked to the given grades report.

  A student is "linked" to a grades report if they have at least
  one grade report entry.

  Student classes that belong to the same year as the grades report
  will be preloaded.

  Results are ordered by class name, then by student name.

  We could query the grades report to get the year id, but in most cases
  the caller will already have access to this id.
  """
  @spec list_grades_report_students(
          grades_report_id :: pos_integer(),
          grades_report_year_id :: pos_integer()
        ) :: [Student.t()]
  def list_grades_report_students(grades_report_id, grades_report_year_id) do
    students_ids =
      from(
        std in Student,
        join: sgre in assoc(std, :grades_report_entries),
        where: sgre.grades_report_id == ^grades_report_id,
        distinct: true
      )
      |> Repo.all()
      |> Enum.map(& &1.id)

    from(
      std in Student,
      left_join: c in assoc(std, :classes),
      left_join: y in assoc(c, :years),
      where: std.id in ^students_ids,
      where: (not is_nil(c) and y.id == ^grades_report_year_id) or is_nil(c),
      order_by: [asc: c.name, asc: std.name],
      preload: [classes: c]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of all `GradesReportSubject`s linked to the given strands,
  cycle, and grades report.

  This function looks for all `GradeComponent`s to identify those that are
  linked to the list of strands, cycles (through `GradesReportCycle`), and grades report,
  then return a list of tuples with the strand id as the first element, and a list
  of unique `GradesReportSubject`s as the second element, ordered by position.

  The returned list will follow the order passed in `strands_ids` arg.
  """

  @spec list_strands_linked_grades_report_subjects(
          strands_ids :: [pos_integer()],
          cycle_id :: pos_integer(),
          grades_report_id :: pos_integer()
        ) :: [{strand_id :: pos_integer(), [GradesReportSubject.t()]}]
  def list_strands_linked_grades_report_subjects(strands_ids, cycle_id, grades_report_id) do
    strand_id_grs_map =
      from(
        gc in GradeComponent,
        join: grc in assoc(gc, :grades_report_cycle),
        join: grs in assoc(gc, :grades_report_subject),
        join: sub in assoc(grs, :subject),
        join: ap in assoc(gc, :assessment_point),
        where: ap.strand_id in ^strands_ids,
        select: {ap.strand_id, %{grs | subject: sub}},
        where: grc.school_cycle_id == ^cycle_id,
        where: gc.grades_report_id == ^grades_report_id,
        distinct: [ap.strand_id, sub.id]
      )
      |> Repo.all()
      |> Enum.sort_by(fn {_strand_id, grs} -> grs.position end)
      |> Enum.group_by(
        fn {strand_id, _grs} -> strand_id end,
        fn {_strand_id, grs} -> grs end
      )

    strands_ids
    |> Enum.map(&{&1, Map.get(strand_id_grs_map, &1, [])})
  end

  @doc """
  Returns a list of all `StudentGradesReportEntry`s linked to the given student,
  strand, cycle, and grades report.

  This function looks for all `StudentGradesReportEntry`s to identify those that are
  linked to the given student and grades report, also filtering by strand and cycle.

  We use `GradesReportCycle` to identify the entry cycle, and check for embeded
  `CompositionComponent` to determine if the entry is linked to the strand.

  Returned list is ordered by `GradesReportSubject`s' position.

  `GradesReportSubject` with `Subject` preloaded.

  ### Options

  - `:only_visible` - if true, will check for grades report cycle visibility

  """

  @spec list_student_grades_report_entries_for_strand(
          student_id :: pos_integer(),
          strand_id :: pos_integer(),
          cycle_id :: pos_integer(),
          grades_report_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: [StudentGradesReportEntry.t()]
  def list_student_grades_report_entries_for_strand(
        student_id,
        strand_id,
        cycle_id,
        grades_report_id,
        opts \\ []
      ) do
    cycle_visibility_condition =
      case Keyword.get(opts, :only_visible) do
        true -> dynamic([_sgre, grades_report_cycle: grc], grc.is_visible)
        _ -> true
      end

    from(
      sgre in StudentGradesReportEntry,
      join: grc in assoc(sgre, :grades_report_cycle),
      as: :grades_report_cycle,
      join: grs in assoc(sgre, :grades_report_subject),
      join: sub in assoc(grs, :subject),
      where: sgre.student_id == ^student_id,
      where: sgre.grades_report_id == ^grades_report_id,
      where: grc.school_cycle_id == ^cycle_id,
      where: ^cycle_visibility_condition,
      where: fragment("? @> ?", sgre.composition, ^[%{strand_id: strand_id}]),
      order_by: [asc: grs.position],
      preload: [grades_report_subject: {grs, subject: sub}]
    )
    |> Repo.all()
  end
end
