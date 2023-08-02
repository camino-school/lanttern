defmodule Lanttern.GradingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Grading` context.
  """

  alias Lanttern.CurriculaFixtures

  @doc """
  Generate a composition.
  """
  def composition_fixture(attrs \\ %{}) do
    {:ok, composition} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Lanttern.Grading.create_composition()

    composition
  end

  @doc """
  Generate a composition_component.
  """
  def composition_component_fixture(attrs \\ %{}) do
    composition = composition_fixture()

    {:ok, composition_component} =
      attrs
      |> Enum.into(%{
        name: "some name",
        weight: 120.5,
        composition_id: composition.id
      })
      |> Lanttern.Grading.create_composition_component()

    composition_component
  end

  @doc """
  Generate a composition_component_item.
  """
  def composition_component_item_fixture(attrs \\ %{}) do
    component = composition_component_fixture()
    curriculum_item = CurriculaFixtures.item_fixture()

    {:ok, composition_component_item} =
      attrs
      |> Enum.into(%{
        weight: 120.5,
        component_id: component.id,
        curriculum_item_id: curriculum_item.id
      })
      |> Lanttern.Grading.create_composition_component_item()

    composition_component_item
  end

  @doc """
  Generate a scale.
  """
  def scale_fixture(attrs \\ %{}) do
    {:ok, scale} =
      attrs
      |> Enum.into(%{
        name: "some name",
        start: 120.5,
        stop: 120.5,
        type: "numeric"
      })
      |> Lanttern.Grading.create_scale()

    scale
  end

  @doc """
  Generate a ordinal_value.
  """
  def ordinal_value_fixture(attrs \\ %{}) do
    scale = scale_fixture()

    {:ok, ordinal_value} =
      attrs
      |> Enum.into(%{
        name: "some name",
        normalized_value: 1,
        scale_id: scale.id
      })
      |> Lanttern.Grading.create_ordinal_value()

    ordinal_value
  end

  @doc """
  Generate a conversion_rule.
  """
  def conversion_rule_fixture(attrs \\ %{}) do
    from_scale = scale_fixture()
    to_scale = scale_fixture()

    {:ok, conversion_rule} =
      attrs
      |> Enum.into(%{
        name: "some name",
        from_scale_id: from_scale.id,
        to_scale_id: to_scale.id,
        conversions: %{}
      })
      |> Lanttern.Grading.create_conversion_rule()

    conversion_rule
  end
end
