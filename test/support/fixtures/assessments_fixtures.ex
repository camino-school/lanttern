defmodule Lanttern.AssessmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Assessments` context.
  """

  @doc """
  Generate a assessment point.
  """
  def assessment_point_fixture(attrs \\ %{}) do
    scale = Lanttern.GradingFixtures.scale_fixture()
    curriculum_item = Lanttern.CurriculaFixtures.item_fixture()

    {:ok, assessment_point} =
      attrs
      |> Enum.into(%{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })
      |> Lanttern.Assessments.create_assessment_point()

    assessment_point
  end

  @doc """
  Generate a assessment_point_entry.
  """
  def assessment_point_entry_fixture(attrs \\ %{}) do
    assessment_point = assessment_point_fixture()
    student = Lanttern.SchoolsFixtures.student_fixture()

    {:ok, assessment_point_entry} =
      attrs
      |> Enum.into(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        score: nil,
        ordinal_value_id: nil
      })
      |> Lanttern.Assessments.create_assessment_point_entry()

    assessment_point_entry
  end
end
