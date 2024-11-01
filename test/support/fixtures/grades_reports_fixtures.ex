defmodule Lanttern.GradesReportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.GradesReports` context.
  """

  @doc """
  Generate a grade report.
  """
  def grades_report_fixture(attrs \\ %{}) do
    {:ok, grades_report} =
      attrs
      |> Enum.into(%{
        name: "some name",
        info: "some info",
        school_cycle_id: Lanttern.SchoolsFixtures.maybe_gen_cycle_id(attrs),
        year_id: Lanttern.TaxonomyFixtures.maybe_gen_year_id(attrs),
        scale_id: Lanttern.GradingFixtures.maybe_gen_scale_id(attrs)
      })
      |> Lanttern.GradesReports.create_grades_report()

    grades_report
  end

  @doc """
  Generate a grades_report_subject.
  """
  def grades_report_subject_fixture(attrs \\ %{}) do
    {:ok, grades_report_subject} =
      attrs
      |> Enum.into(%{
        grades_report_id: maybe_gen_grades_report_id(attrs),
        subject_id: Lanttern.TaxonomyFixtures.maybe_gen_subject_id(attrs)
      })
      |> Lanttern.GradesReports.add_subject_to_grades_report()

    grades_report_subject
  end

  @doc """
  Generate a grades_report_cycle.
  """
  def grades_report_cycle_fixture(attrs \\ %{}) do
    {:ok, grades_report_cycle} =
      attrs
      |> Enum.into(%{
        grades_report_id: maybe_gen_grades_report_id(attrs),
        school_cycle_id: Lanttern.SchoolsFixtures.maybe_gen_cycle_id(attrs)
      })
      |> Lanttern.GradesReports.add_cycle_to_grades_report()

    grades_report_cycle
  end

  @doc """
  Generate a student_grades_report_entry.
  """
  def student_grades_report_entry_fixture(attrs \\ %{}) do
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
          grades_report = grades_report_fixture()

          {
            grades_report.id,
            grades_report_cycle_fixture(%{
              grades_report_id: grades_report.id
            }).id,
            grades_report_subject_fixture(%{
              grades_report_id: grades_report.id
            }).id
          }
      end

    {:ok, student_grades_report_entry} =
      attrs
      |> Enum.into(%{
        student_id: Lanttern.SchoolsFixtures.maybe_gen_student_id(attrs),
        grades_report_id: grades_report_id,
        grades_report_cycle_id: grades_report_cycle_id,
        grades_report_subject_id: grades_report_subject_id,
        comment: "some comment",
        composition_normalized_value: 0.5,
        normalized_value: 0.5,
        score: 120.5
      })
      |> Lanttern.GradesReports.create_student_grades_report_entry()

    student_grades_report_entry
  end

  @doc """
  Generate a student_grades_report_final_entry.
  """
  def student_grades_report_final_entry_fixture(attrs \\ %{}) do
    {
      grades_report_id,
      grades_report_subject_id
    } =
      case attrs do
        %{
          grades_report_id: grades_report_id,
          grades_report_subject_id: grades_report_subject_id
        } ->
          {
            grades_report_id,
            grades_report_subject_id
          }

        _ ->
          grades_report = grades_report_fixture()

          {
            grades_report.id,
            grades_report_subject_fixture(%{
              grades_report_id: grades_report.id
            }).id
          }
      end

    {:ok, student_grades_report_final_entry} =
      attrs
      |> Enum.into(%{
        student_id: Lanttern.SchoolsFixtures.maybe_gen_student_id(attrs),
        grades_report_id: grades_report_id,
        grades_report_subject_id: grades_report_subject_id,
        comment: "some comment",
        composition_normalized_value: 0.5,
        score: 120.5
      })
      |> Lanttern.GradesReports.create_student_grades_report_final_entry()

    student_grades_report_final_entry
  end

  # generator helpers

  def maybe_gen_grades_report_id(%{grades_report_id: grades_report_id} = _attrs),
    do: grades_report_id

  def maybe_gen_grades_report_id(_attrs),
    do: grades_report_fixture().id

  def maybe_gen_grades_report_cycle_id(
        %{grades_report_cycle_id: grades_report_cycle_id} = _attrs
      ),
      do: grades_report_cycle_id

  def maybe_gen_grades_report_cycle_id(_attrs),
    do: grades_report_cycle_fixture().id

  def maybe_gen_grades_report_subject_id(
        %{grades_report_subject_id: grades_report_subject_id} = _attrs
      ),
      do: grades_report_subject_id

  def maybe_gen_grades_report_subject_id(_attrs),
    do: grades_report_subject_fixture().id
end
