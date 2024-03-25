defmodule Lanttern.GradesReportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.GradesReports` context.
  """

  @doc """
  Generate a student_grade_report_entry.
  """
  def student_grade_report_entry_fixture(attrs \\ %{}) do
    {
      grades_report_id,
      grades_report_cycle_id,
      grades_report_subject_id
    } =
      case attrs do
        %{
          grades_report_id: grades_report_id,
          grades_report_cycle_id: grades_report_cycle_id,
          grades_report_subject_id: grades_report_subject_id
        } ->
          {
            grades_report_id,
            grades_report_cycle_id,
            grades_report_subject_id
          }

        _ ->
          grades_report = Lanttern.ReportingFixtures.grades_report_fixture()

          {
            grades_report.id,
            Lanttern.ReportingFixtures.grades_report_cycle_fixture(%{
              grades_report_id: grades_report.id
            }).id,
            Lanttern.ReportingFixtures.grades_report_subject_fixture(%{
              grades_report_id: grades_report.id
            }).id
          }
      end

    {:ok, student_grade_report_entry} =
      attrs
      |> Enum.into(%{
        student_id: Lanttern.SchoolsFixtures.maybe_gen_student_id(attrs),
        grades_report_id: grades_report_id,
        grades_report_cycle_id: grades_report_cycle_id,
        grades_report_subject_id: grades_report_subject_id,
        comment: "some comment",
        composition_normalized_value: 0.5,
        score: 120.5
      })
      |> Lanttern.GradesReports.create_student_grade_report_entry()

    student_grade_report_entry
  end
end
