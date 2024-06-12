defmodule Lanttern.GradesReports do
  @moduledoc """
  The GradesReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Schools.Student
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.GradesReportCycle
  alias Lanttern.GradesReports.GradesReportSubject
  alias Lanttern.GradesReports.StudentGradeReportEntry
  alias Lanttern.Grading
  alias Lanttern.Grading.GradeComponent
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Reporting.StudentReportCard

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
  Returns the list of student_grade_report_entries.

  ## Examples

      iex> list_student_grade_report_entries()
      [%StudentGradeReportEntry{}, ...]

  """
  def list_student_grade_report_entries do
    Repo.all(StudentGradeReportEntry)
  end

  @doc """
  Gets a single student_grade_report_entry.

  Raises `Ecto.NoResultsError` if the Student grade report entry does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_grade_report_entry!(123)
      %StudentGradeReportEntry{}

      iex> get_student_grade_report_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_grade_report_entry!(id, opts \\ []) do
    Repo.get!(StudentGradeReportEntry, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_grade_report_entry.

  ## Examples

      iex> create_student_grade_report_entry(%{field: value})
      {:ok, %StudentGradeReportEntry{}}

      iex> create_student_grade_report_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_grade_report_entry(attrs \\ %{}) do
    %StudentGradeReportEntry{}
    |> StudentGradeReportEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_grade_report_entry.

  ## Examples

      iex> update_student_grade_report_entry(student_grade_report_entry, %{field: new_value})
      {:ok, %StudentGradeReportEntry{}}

      iex> update_student_grade_report_entry(student_grade_report_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_grade_report_entry(
        %StudentGradeReportEntry{} = student_grade_report_entry,
        attrs
      ) do
    student_grade_report_entry
    |> StudentGradeReportEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_grade_report_entry.

  ## Examples

      iex> delete_student_grade_report_entry(student_grade_report_entry)
      {:ok, %StudentGradeReportEntry{}}

      iex> delete_student_grade_report_entry(student_grade_report_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_grade_report_entry(%StudentGradeReportEntry{} = student_grade_report_entry) do
    Repo.delete(student_grade_report_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_grade_report_entry changes.

  ## Examples

      iex> change_student_grade_report_entry(student_grade_report_entry)
      %Ecto.Changeset{data: %StudentGradeReportEntry{}}

  """
  def change_student_grade_report_entry(
        %StudentGradeReportEntry{} = student_grade_report_entry,
        attrs \\ %{}
      ) do
    StudentGradeReportEntry.changeset(student_grade_report_entry, attrs)
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
  - `:created` when the `StudentGradeReportEntry` is created
  - `:updated` when the `StudentGradeReportEntry` is updated
  - `:deleted` when the `StudentGradeReportEntry` is deleted (always `nil` in the second element)
  - `:noop` when the nothing is created, updated, or deleted (always `nil` in the second element)
  """
  @spec calculate_student_grade(
          student_id :: integer(),
          grades_report_id :: integer(),
          grades_report_cycle_id :: integer(),
          grades_report_subject_id :: integer()
        ) ::
          {:ok, StudentGradeReportEntry.t() | nil, :created | :updated | :deleted | :noop}
          | {:error, Ecto.Changeset.t()}
  def calculate_student_grade(
        student_id,
        grades_report_id,
        grades_report_cycle_id,
        grades_report_subject_id
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
      scale
    )
  end

  defp handle_student_grades_report_entry_creation(
         [],
         student_id,
         _grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         _scale
       ) do
    # delete existing student grade report entry if needed
    Repo.get_by(StudentGradeReportEntry,
      student_id: student_id,
      grades_report_cycle_id: grades_report_cycle_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> case do
      nil ->
        {:ok, nil, :noop}

      sgre ->
        case delete_student_grade_report_entry(sgre) do
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
         scale
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
        composition: composition,
        composition_normalized_value: normalized_avg,
        composition_datetime: DateTime.utc_now()
      })

    # create or update existing student grade report entry
    Repo.get_by(StudentGradeReportEntry,
      student_id: student_id,
      grades_report_cycle_id: grades_report_cycle_id,
      grades_report_subject_id: grades_report_subject_id
    )
    |> case do
      nil ->
        case create_student_grade_report_entry(attrs) do
          {:ok, sgre} -> {:ok, sgre, :created}
          error_tuple -> error_tuple
        end

      sgre ->
        case update_student_grade_report_entry(sgre, attrs) do
          {:ok, sgre} -> {:ok, sgre, :updated}
          error_tuple -> error_tuple
        end
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
        grades_report_subject.id,
        Map.get(
          grades_report_subject_entries_grade_components,
          grades_report_subject.id,
          []
        )
      }
    end)
    |> handle_grades_report_subject_entries_and_grade_components(
      student_id,
      grades_report_id,
      grades_report_cycle_id,
      scale
    )
  end

  defp handle_grades_report_subject_entries_and_grade_components(
         grades_report_subject_entries_grade_components,
         student_id,
         grades_report_id,
         grades_report_cycle_id,
         scale,
         results \\ %{created: 0, updated: 0, deleted: 0, noop: 0}
       )

  defp handle_grades_report_subject_entries_and_grade_components(
         [],
         _student_id,
         _grades_report_id,
         _grades_report_cycle_id,
         _scale,
         results
       ),
       do: {:ok, results}

  defp handle_grades_report_subject_entries_and_grade_components(
         [
           {grs_id, entries_and_grade_components} | grades_report_subject_entries_grade_components
         ],
         student_id,
         grades_report_id,
         grades_report_cycle_id,
         scale,
         results
       ) do
    handle_student_grades_report_entry_creation(
      entries_and_grade_components,
      student_id,
      grades_report_id,
      grades_report_cycle_id,
      grs_id,
      scale
    )
    |> case do
      {:ok, _result, operation} ->
        handle_grades_report_subject_entries_and_grade_components(
          grades_report_subject_entries_grade_components,
          student_id,
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
        Map.get(
          students_entries_grade_components,
          student_id,
          []
        )
      }
    end)
    |> handle_students_entries_and_grade_components(
      grades_report_id,
      grades_report_cycle_id,
      grades_report_subject_id,
      scale
    )
  end

  defp handle_students_entries_and_grade_components(
         student_entries_grade_components,
         grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         scale,
         results \\ %{created: 0, updated: 0, deleted: 0, noop: 0}
       )

  defp handle_students_entries_and_grade_components(
         [],
         _grades_report_id,
         _grades_report_cycle_id,
         _grades_report_subject_id,
         _scale,
         results
       ),
       do: {:ok, results}

  defp handle_students_entries_and_grade_components(
         [
           {std_id, entries_and_grade_components} | student_entries_grade_components
         ],
         grades_report_id,
         grades_report_cycle_id,
         grades_report_subject_id,
         scale,
         results
       ) do
    handle_student_grades_report_entry_creation(
      entries_and_grade_components,
      std_id,
      grades_report_id,
      grades_report_cycle_id,
      grades_report_subject_id,
      scale
    )
    |> case do
      {:ok, _result, operation} ->
        handle_students_entries_and_grade_components(
          student_entries_grade_components,
          grades_report_id,
          grades_report_cycle_id,
          grades_report_subject_id,
          scale,
          Map.update!(results, operation, &(&1 + 1))
        )

      {:error, changeset} ->
        {:error, changeset, results}
    end
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
    |> handle_students_grades_report_subjects_entries_and_grade_components(
      grades_report_id,
      grades_report_cycle_id,
      scale
    )
  end

  defp handle_students_grades_report_subjects_entries_and_grade_components(
         student_grades_report_subject_entries_and_grade_components,
         grades_report_id,
         grades_report_cycle_id,
         scale,
         results \\ %{created: 0, updated: 0, deleted: 0, noop: 0}
       )

  defp handle_students_grades_report_subjects_entries_and_grade_components(
         [],
         _grades_report_id,
         _grades_report_cycle_id,
         _scale,
         results
       ),
       do: {:ok, results}

  defp handle_students_grades_report_subjects_entries_and_grade_components(
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
        handle_students_grades_report_subjects_entries_and_grade_components(
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
  Returns a map in the format

      %{
        student_id => %{
          subject_id => %StudentGradeReportEntry{},
          # other subjects ids...
        }
        # other students ids...
      }

  for the given students, grades report and cycle.

  Ordinal values preloaded (manually) in student grade report entry.
  """
  @spec build_students_grades_map(
          student_ids :: [integer()],
          grades_report_id :: integer(),
          cycle_id :: integer()
        ) :: %{}
  def build_students_grades_map(students_ids, grades_report_id, cycle_id) do
    from(
      std in Student,
      join: grs in GradesReportSubject,
      on: true,
      join: grc in GradesReportCycle,
      on: grc.grades_report_id == grs.grades_report_id,
      left_join: sgre in StudentGradeReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == std.id,
      left_join: ov in assoc(sgre, :ordinal_value),
      where: std.id in ^students_ids,
      where: grc.grades_report_id == ^grades_report_id,
      where: grc.school_cycle_id == ^cycle_id,
      select: {std.id, grs.id, sgre, ov}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {std_id, grs_id, sgre, ov}, acc ->
      # "preload" ordinal value in student grade report entry
      sgre =
        case sgre do
          nil -> nil
          sgre -> %{sgre | ordinal_value: ov}
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
          subject_id => %StudentGradeReportEntry{},
          # other subjects ids...
        }
        # other cycles ids...
      }

  for the given student report card id.

  Ordinal values preloaded (manually) in student grade report entry.
  """
  @spec build_student_grades_map(student_report_card_id :: integer()) :: %{}
  def build_student_grades_map(student_report_card_id) do
    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: gr in assoc(rc, :grades_report),
      join: grc in assoc(gr, :grades_report_cycles),
      on: grc.is_visible,
      join: grs in assoc(gr, :grades_report_subjects),
      left_join: sgre in StudentGradeReportEntry,
      on:
        sgre.grades_report_cycle_id == grc.id and
          sgre.grades_report_subject_id == grs.id and
          sgre.student_id == src.student_id,
      left_join: ov in assoc(sgre, :ordinal_value),
      where: src.id == ^student_report_card_id,
      select: {grc.id, grs.id, sgre, ov}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {grc_id, grs_id, sgre, ov}, acc ->
      # "preload" ordinal value in student grade report entry
      sgre =
        case sgre do
          nil -> nil
          sgre -> %{sgre | ordinal_value: ov}
        end

      # build cycle map
      cycle_map =
        Map.get(acc, grc_id, %{})
        |> Map.put(grs_id, sgre)

      Map.put(acc, grc_id, cycle_map)
    end)
  end
end
