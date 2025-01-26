defmodule Lanttern.AssessmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Assessments` context.
  """

  @doc """
  Generate an assessment point.
  """
  def assessment_point_fixture(attrs \\ %{}) do
    {:ok, assessment_point} =
      attrs
      |> Enum.into(%{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        scale_id: Lanttern.GradingFixtures.maybe_gen_scale_id(attrs),
        curriculum_item_id: Lanttern.CurriculaFixtures.maybe_gen_curriculum_item_id(attrs)
      })
      |> Lanttern.Assessments.create_assessment_point()

    assessment_point
  end

  @doc """
  Generate a assessment_point_entry.
  """
  def assessment_point_entry_fixture(attrs \\ %{})

  def assessment_point_entry_fixture(%{assessment_point_id: _, student_id: _} = attrs) do
    {:ok, assessment_point_entry} =
      attrs
      |> Enum.into(%{
        observation: "some observation",
        score: nil,
        ordinal_value_id: nil
      })
      |> Lanttern.Assessments.create_assessment_point_entry()

    assessment_point_entry
  end

  def assessment_point_entry_fixture(attrs) do
    scale = Lanttern.GradingFixtures.scale_fixture()
    assessment_point = assessment_point_fixture(%{scale_id: scale.id})
    student = Lanttern.SchoolsFixtures.student_fixture()

    {:ok, assessment_point_entry} =
      attrs
      |> Enum.into(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        score: nil,
        ordinal_value_id: nil,
        scale_id: scale.id,
        scale_type: scale.type
      })
      |> Lanttern.Assessments.create_assessment_point_entry()

    assessment_point_entry
  end

  @doc """
  Generate a feedback.
  """
  def feedback_fixture(attrs \\ %{}) do
    assessment_point_id = Map.get(attrs, :assessment_point_id) || assessment_point_fixture().id
    student_id = Map.get(attrs, :student_id) || Lanttern.SchoolsFixtures.student_fixture().id

    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.staff_member_profile_fixture().id

    {:ok, feedback} =
      attrs
      |> Enum.into(%{
        comment: "Some feedback comment",
        assessment_point_id: assessment_point_id,
        student_id: student_id,
        profile_id: profile_id
      })
      |> Lanttern.Assessments.create_feedback()

    feedback
  end

  # generator helpers

  def maybe_gen_assessment_point_id(%{assessment_point_id: assessment_point_id} = _attrs),
    do: assessment_point_id

  def maybe_gen_assessment_point_id(_attrs),
    do: assessment_point_fixture().id

  def maybe_gen_assessment_point_entry_id(
        %{assessment_point_entry_id: assessment_point_entry_id} = _attrs
      ),
      do: assessment_point_entry_id

  def maybe_gen_assessment_point_entry_id(_attrs),
    do: assessment_point_entry_fixture().id
end
