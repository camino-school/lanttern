defmodule Lanttern.GradesReports do
  @moduledoc """
  The GradesReports context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.GradesReports.StudentGradeReportEntry
  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Reporting.GradesReportCycle

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

  ## Examples

      iex> get_student_grade_report_entry!(123)
      %StudentGradeReportEntry{}

      iex> get_student_grade_report_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_grade_report_entry!(id), do: Repo.get!(StudentGradeReportEntry, id)

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
  Calculate student grade based for given grades report cycle and subject.

  ## Expected opts:

  - `:student_id`
  - `:grades_report_cycle_id`
  - `:grades_report_subject_id`
  """
  @spec calculate_student_grade(Keyword.t()) ::
          {:ok, StudentGradeReportEntry.t()} | {:error, Ecto.Changeset.t()} | nil
  def calculate_student_grade(opts \\ []) do
    with student_id when not is_nil(student_id) <- Keyword.get(opts, :student_id),
         grades_report_cycle_id when not is_nil(grades_report_cycle_id) <-
           Keyword.get(opts, :grades_report_cycle_id),
         grades_report_subject_id when not is_nil(grades_report_subject_id) <-
           Keyword.get(opts, :grades_report_subject_id) do
      entries_grade_components_and_assessment_points =
        from(
          e in AssessmentPointEntry,
          join: s in assoc(e, :scale),
          left_join: ov in assoc(e, :ordinal_value),
          join: ap in assoc(e, :assessment_point),
          join: gc in assoc(ap, :grade_components),
          join: rc in assoc(gc, :report_card),
          join: gr in assoc(rc, :grades_report),
          join: grc in assoc(gr, :grades_report_cycles),
          join: grs in assoc(gr, :grades_report_subjects),
          where: e.student_id == ^student_id,
          where: grc.id == ^grades_report_cycle_id,
          where: grs.id == ^grades_report_subject_id,
          preload: [ordinal_value: ov, scale: s],
          select: {e, gc}
        )
        |> Repo.all()

      # calculate the weighted average
      {sumprod, sumweight} =
        entries_grade_components_and_assessment_points
        |> Enum.reduce({0, 0}, fn {e, gc}, {sumprod, sumweight} ->
          {get_normalized_value_from_entry(e) * gc.weight + sumprod, gc.weight + sumweight}
        end)

      normalized_avg = Float.round(sumprod / sumweight, 5)

      {scale, grades_report} =
        get_scale_and_grades_report_from_grades_report_cycle(grades_report_cycle_id)

      scale_value = Grading.convert_normalized_value_to_scale_value(normalized_avg, scale)

      # setup student grade report entry attrs and create
      case scale_value do
        %OrdinalValue{} = ordinal_value ->
          %{ordinal_value_id: ordinal_value.id}

        score ->
          %{score: score}
      end
      |> Enum.into(%{
        student_id: student_id,
        normalized_value: normalized_avg,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grades_report_cycle_id,
        grades_report_subject_id: grades_report_subject_id
      })
      |> create_student_grade_report_entry()
    end
  end

  defp get_normalized_value_from_entry(%AssessmentPointEntry{scale_type: "ordinal"} = entry),
    do: entry.ordinal_value.normalized_value

  defp get_normalized_value_from_entry(%AssessmentPointEntry{scale_type: "numeric"} = entry),
    do: (entry.score - entry.scale.start) / (entry.scale.stop - entry.scale.start)

  defp get_scale_and_grades_report_from_grades_report_cycle(grades_report_cycle_id) do
    from(
      grc in GradesReportCycle,
      join: gr in assoc(grc, :grades_report),
      join: s in assoc(gr, :scale),
      where: grc.id == ^grades_report_cycle_id,
      select: {s, gr}
    )
    |> Repo.one!()
  end
end
