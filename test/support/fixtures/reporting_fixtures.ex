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
        description: "some description"
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

  # generator helpers

  def maybe_gen_report_card_id(%{report_card_id: report_card_id} = _attrs),
    do: report_card_id

  def maybe_gen_report_card_id(_attrs),
    do: report_card_fixture().id
end
