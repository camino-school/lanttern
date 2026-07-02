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
        curriculum_item_id: maybe_gen_curriculum_item_id(attrs)
      })
      |> then(&Lanttern.Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, &1))

    assessment_point
  end

  @doc """
  Links an assessment point to a lesson via the `assessment_points_lessons` join.

  Bare state setup for tests — inserts the join row directly, bypassing the
  `Lanttern.Lessons` link API (and its scope guard / audit log) so it works with any
  scope. Returns the assessment point unchanged.
  """
  def link_assessment_point_to_lesson_fixture(assessment_point, lesson) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Lanttern.Repo.insert_all(
      "assessment_points_lessons",
      [
        %{
          assessment_point_id: assessment_point.id,
          lesson_id: lesson.id,
          inserted_at: now,
          updated_at: now
        }
      ],
      on_conflict: :nothing
    )

    assessment_point
  end

  @doc """
  Generates a moment-owned assessment point and links it to a lesson.

  Replaces the old `assessment_point_fixture(%{lesson_id: ...})` pattern: an AP must be
  moment-owned to be linkable, and the link now lives in the join table. `attrs` are
  forwarded to `assessment_point_fixture/1` (with `:moment_id` set from `moment`).
  """
  def moment_assessment_point_linked_to_lesson_fixture(moment, lesson, attrs \\ %{}) do
    attrs
    |> Enum.into(%{moment_id: moment.id})
    |> assessment_point_fixture()
    |> link_assessment_point_to_lesson_fixture(lesson)
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
      |> then(&Lanttern.Assessments.create_assessment_point_entry(%Lanttern.Identity.Scope{}, &1))

    assessment_point_entry
  end

  def assessment_point_entry_fixture(attrs) do
    scale = Lanttern.Factory.insert(:scale)
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
      |> then(&Lanttern.Assessments.create_assessment_point_entry(%Lanttern.Identity.Scope{}, &1))

    assessment_point_entry
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

  defp maybe_gen_curriculum_item_id(%{curriculum_item_id: id}), do: id
  defp maybe_gen_curriculum_item_id(_attrs), do: Lanttern.Factory.insert(:curriculum_item).id
end
