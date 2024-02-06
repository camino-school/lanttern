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
        school_cycle_id: maybe_gen_school_cycle_id(attrs)
      })
      |> Lanttern.Reporting.create_report_card()

    report_card
  end

  defp maybe_gen_school_cycle_id(%{school_cycle_id: school_cycle_id} = _attrs),
    do: school_cycle_id

  defp maybe_gen_school_cycle_id(_attrs),
    do: Lanttern.SchoolsFixtures.cycle_fixture().id

  @doc """
  Generate a strand_report.
  """
  def strand_report_fixture(attrs \\ %{}) do
    {:ok, strand_report} =
      attrs
      |> Enum.into(%{
        report_card_id: maybe_gen_report_card_id(attrs),
        strand_id: maybe_gen_strand_id(attrs),
        description: "some description",
        position: 0
      })
      |> Lanttern.Reporting.create_strand_report()

    strand_report
  end

  defp maybe_gen_report_card_id(%{report_card_id: report_card_id} = _attrs),
    do: report_card_id

  defp maybe_gen_report_card_id(_attrs),
    do: report_card_fixture().id

  defp maybe_gen_strand_id(%{strand_id: strand_id} = _attrs),
    do: strand_id

  defp maybe_gen_strand_id(_attrs),
    do: Lanttern.LearningContextFixtures.strand_fixture().id

  @doc """
  Generate a student_report_card.
  """
  def student_report_card_fixture(attrs \\ %{}) do
    {:ok, student_report_card} =
      attrs
      |> Enum.into(%{
        report_card_id: maybe_gen_report_card_id(attrs),
        student_id: maybe_gen_student_id(attrs),
        comment: "some comment",
        footnote: "some footnote"
      })
      |> Lanttern.Reporting.create_student_report_card()

    student_report_card
  end

  defp maybe_gen_student_id(%{student_id: student_id} = _attrs),
    do: student_id

  defp maybe_gen_student_id(_attrs),
    do: Lanttern.SchoolsFixtures.student_fixture().id
end
