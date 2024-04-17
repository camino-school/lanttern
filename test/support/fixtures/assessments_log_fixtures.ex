defmodule Lanttern.AssessmentsLogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.AssessmentsLog` context.
  """

  import Lanttern.AssessmentsFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.IdentityFixtures
  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a assessment_point_entry log.
  """
  def assessment_point_entry_log_fixture(attrs \\ %{}) do
    scale = GradingFixtures.scale_fixture()

    {:ok, assessment_point_entry_log} =
      attrs
      |> Enum.into(%{
        assessment_point_entry_id: maybe_gen_assessment_point_entry_id(attrs),
        assessment_point_id: maybe_gen_assessment_point_id(attrs),
        operation: "CREATE",
        profile_id: IdentityFixtures.maybe_gen_profile_id(attrs),
        scale_id: attrs[:scale_id] || scale.id,
        scale_type: attrs[:scale_type] || scale.type,
        student_id: SchoolsFixtures.maybe_gen_student_id(attrs)
      })
      |> Lanttern.AssessmentsLog.create_assessment_point_entry_log()

    assessment_point_entry_log
  end
end
