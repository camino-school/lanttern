defmodule Lanttern.StudentRecordReportsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.StudentRecordReports` context.
  """

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentRecordReports

  @doc """
  Generate a student_record_report_ai_config.
  """
  def student_record_report_ai_config_fixture(attrs \\ %{}) do
    {:ok, student_record_report_ai_config} =
      attrs
      |> Enum.into(%{
        cooldown_minutes: 42,
        model: "some model",
        summary_instructions: "some summary_instructions",
        update_instructions: "some update_instructions",
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> StudentRecordReports.create_student_record_report_ai_config()

    student_record_report_ai_config
  end

  @doc """
  Generate a student_record_report.
  """
  def student_record_report_fixture(attrs \\ %{}) do
    {:ok, student_record_report} =
      attrs
      |> Enum.into(%{
        description: "some description",
        student_id: SchoolsFixtures.maybe_gen_student_id(attrs)
      })
      |> Lanttern.StudentRecordReports.create_student_record_report()

    student_record_report
  end
end
