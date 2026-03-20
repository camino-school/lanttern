defmodule Lanttern.GradingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Grading` context.
  """

  import Lanttern.Factory

  @doc """
  Generate a grade_component.
  """
  def grade_component_fixture(attrs \\ %{}) do
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
          grades_report = Lanttern.GradesReportsFixtures.grades_report_fixture()

          {
            grades_report.id,
            Lanttern.GradesReportsFixtures.grades_report_cycle_fixture(%{
              grades_report_id: grades_report.id
            }).id,
            Lanttern.GradesReportsFixtures.grades_report_subject_fixture(%{
              grades_report_id: grades_report.id
            }).id
          }
      end

    {:ok, grade_component} =
      attrs
      |> Enum.into(%{
        position: 42,
        weight: 120.5,
        assessment_point_id: Lanttern.AssessmentsFixtures.maybe_gen_assessment_point_id(attrs),
        grades_report_id: grades_report_id,
        grades_report_cycle_id: grades_report_cycle_id,
        grades_report_subject_id: grades_report_subject_id
      })
      |> Lanttern.Grading.create_grade_component()

    grade_component
  end

  # generator helpers

  def maybe_gen_scale_id(%{scale_id: scale_id} = _attrs), do: scale_id
  def maybe_gen_scale_id(_attrs), do: insert(:scale).id
end
