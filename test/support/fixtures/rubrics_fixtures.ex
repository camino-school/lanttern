defmodule Lanttern.RubricsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Rubrics` context.
  """

  alias Lanttern.GradingFixtures

  @doc """
  Generate a rubric.
  """

  def rubric_fixture(attrs \\ %{}) do
    {:ok, rubric} =
      attrs
      |> Enum.into(%{
        criteria: "some criteria",
        scale_id: scale_id(attrs),
        is_differentiation: false
      })
      |> Lanttern.Rubrics.create_rubric()

    rubric
  end

  defp scale_id(%{scale_id: scale_id} = _attrs),
    do: scale_id

  defp scale_id(_attrs),
    do: GradingFixtures.scale_fixture().id

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
end
