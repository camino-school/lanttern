defmodule Lanttern.GradingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Grading` context.
  """

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
end
