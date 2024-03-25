defmodule Lanttern.ReportingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Reporting` context.
  """

  @doc """
  Generate a report_card.
  """
  def report_card_fixture(attrs \\ %{}) do
    {:ok, report_card} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        school_cycle_id: Lanttern.SchoolsFixtures.maybe_gen_cycle_id(attrs),
        year_id: Lanttern.TaxonomyFixtures.maybe_gen_year_id(attrs)
      })
      |> Lanttern.Reporting.create_report_card()

    report_card
  end

  @doc """
  Generate a strand_report.
  """
  def strand_report_fixture(attrs \\ %{}) do
    {:ok, strand_report} =
      attrs
      |> Enum.into(%{
        report_card_id: maybe_gen_report_card_id(attrs),
        strand_id: Lanttern.LearningContextFixtures.maybe_gen_strand_id(attrs),
        description: "some description",
        position: 0
      })
      |> Lanttern.Reporting.create_strand_report()

    strand_report
  end

  @doc """
  Generate a student_report_card.
  """
  def student_report_card_fixture(attrs \\ %{}) do
    {:ok, student_report_card} =
      attrs
      |> Enum.into(%{
        report_card_id: maybe_gen_report_card_id(attrs),
        student_id: Lanttern.SchoolsFixtures.maybe_gen_student_id(attrs),
        comment: "some comment",
        footnote: "some footnote"
      })
      |> Lanttern.Reporting.create_student_report_card()

    student_report_card
  end

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
        scale_id: Lanttern.GradingFixtures.maybe_gen_scale_id(attrs)
      })
      |> Lanttern.Reporting.create_grades_report()

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
      |> Lanttern.Reporting.add_subject_to_grades_report()

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
      |> Lanttern.Reporting.add_cycle_to_grades_report()

    grades_report_cycle
  end

  @doc """
  Generate a grade_component.
  """
  def grade_component_fixture(attrs \\ %{}) do
    {:ok, grade_component} =
      attrs
      |> Enum.into(%{
        position: 42,
        weight: 120.5,
        report_card_id: maybe_gen_report_card_id(attrs),
        assessment_point_id: Lanttern.AssessmentsFixtures.maybe_gen_assessment_point_id(attrs),
        subject_id: Lanttern.TaxonomyFixtures.maybe_gen_subject_id(attrs)
      })
      |> Lanttern.Reporting.create_grade_component()

    grade_component
  end

  # generator helpers

  def maybe_gen_report_card_id(%{report_card_id: report_card_id} = _attrs),
    do: report_card_id

  def maybe_gen_report_card_id(_attrs),
    do: report_card_fixture().id

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
