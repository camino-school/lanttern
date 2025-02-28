defmodule Lanttern.RubricsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Rubrics` context.
  """

  alias Lanttern.LearningContextFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

  @doc """
  Generate a rubric.
  """

  def rubric_fixture(attrs \\ %{}) do
    {:ok, rubric} =
      attrs
      |> Enum.into(%{
        criteria: "some criteria",
        scale_id: GradingFixtures.maybe_gen_scale_id(attrs),
        is_differentiation: false
      })
      |> Lanttern.Rubrics.create_rubric()

    rubric
  end

  @doc """
  Generate a rubric_descriptor.
  """
  def rubric_descriptor_fixture(attrs \\ %{})

  def rubric_descriptor_fixture(
        %{rubric_id: _rubric_id, scale_id: _scale_id, scale_type: _scale_type} = attrs
      ) do
    {:ok, rubric_descriptor} =
      attrs
      |> Enum.into(%{
        descriptor: "some descriptor"
      })
      |> Lanttern.Rubrics.create_rubric_descriptor()

    rubric_descriptor
  end

  def rubric_descriptor_fixture(attrs) do
    scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
    rubric = rubric_fixture(%{scale_id: scale.id})
    ordinal_value = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

    {:ok, rubric_descriptor} =
      attrs
      |> Enum.into(%{
        descriptor: "some descriptor",
        scale_id: scale.id,
        scale_type: scale.type,
        score: nil,
        rubric_id: rubric.id,
        ordinal_value_id: ordinal_value.id
      })
      |> Lanttern.Rubrics.create_rubric_descriptor()

    rubric_descriptor
  end

  @doc """
  Generate a strand rubric.
  """

  def strand_rubric_fixture(attrs \\ %{}) do
    {:ok, strand_rubric} =
      attrs
      |> maybe_inject_scale_id()
      |> maybe_inject_rubric_id()
      |> Enum.into(%{
        strand_id: LearningContextFixtures.maybe_gen_strand_id(attrs),
        curriculum_item_id: CurriculaFixtures.maybe_gen_curriculum_item_id(attrs)
      })
      |> Lanttern.Rubrics.create_strand_rubric()

    strand_rubric
  end

  # helpers

  defp maybe_inject_scale_id(%{scale_id: _} = attrs), do: attrs

  defp maybe_inject_scale_id(attrs) do
    attrs
    |> Map.put(:scale_id, GradingFixtures.scale_fixture().id)
  end

  defp maybe_inject_rubric_id(%{rubric_id: _} = attrs), do: attrs

  defp maybe_inject_rubric_id(attrs) do
    attrs
    |> Map.put(
      :rubric_id,
      rubric_fixture(%{scale_id: attrs.scale_id}).id
    )
  end
end
