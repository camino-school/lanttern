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
    scale = scale_fixture()

    {:ok, composition} =
      attrs
      |> Enum.into(%{
        name: "some name",
        final_grade_scale_id: scale.id
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
    curriculum_item = CurriculaFixtures.curriculum_item_fixture()

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
  def scale_fixture(attrs \\ %{})

  def scale_fixture(%{type: "ordinal"} = attrs) do
    {:ok, scale} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: "ordinal",
        breakpoints: [0.4, 0.8]
      })
      |> Lanttern.Grading.create_scale()

    scale
  end

  def scale_fixture(attrs) do
    {:ok, scale} =
      attrs
      |> Enum.into(%{
        name: "some name",
        type: "numeric",
        start: 0,
        stop: 100
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
        scale_id: scale.id,
        bg_color: "#000000",
        text_color: "#ffffff"
      })
      |> Lanttern.Grading.create_ordinal_value()

    ordinal_value
  end
end
