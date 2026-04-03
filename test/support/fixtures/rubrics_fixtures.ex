defmodule Lanttern.RubricsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Rubrics` context.
  """

  import Lanttern.Factory
  alias Lanttern.GradingFixtures
  alias Lanttern.LearningContextFixtures

  @doc """
  Generate a rubric.
  """

  def rubric_fixture(attrs \\ %{}) do
    {:ok, rubric} =
      attrs
      |> Enum.into(%{
        criteria: "some criteria",
        scale_id: GradingFixtures.maybe_gen_scale_id(attrs),
        strand_id: LearningContextFixtures.maybe_gen_strand_id(attrs),
        curriculum_item_id: maybe_gen_curriculum_item_id(attrs),
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
    scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
    rubric = rubric_fixture(%{scale_id: scale.id})
    ordinal_value = insert(:ordinal_value, scale_id: scale.id)

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

  defp maybe_gen_curriculum_item_id(%{curriculum_item_id: id}), do: id
  defp maybe_gen_curriculum_item_id(_attrs), do: insert(:curriculum_item).id
end
