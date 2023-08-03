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
        date: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })
      |> Lanttern.Assessments.create_assessment_point()

    assessment_point
  end
end
