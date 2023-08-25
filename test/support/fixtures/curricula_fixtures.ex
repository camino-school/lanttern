defmodule Lanttern.CurriculaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Curricula` context.
  """

  @doc """
  Generate a curriculum.
  """
  def curriculum_fixture(attrs \\ %{}) do
    {:ok, curriculum} =
      attrs
      |> Enum.into(%{
        name: "some name",
        code: "some code"
      })
      |> Lanttern.Curricula.create_curriculum()

    curriculum
  end

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> Lanttern.Curricula.create_item()

    item
  end

  @doc """
  Generate a curriculum_component.
  """
  def curriculum_component_fixture(attrs \\ %{}) do
    curriculum = curriculum_fixture()

    {:ok, curriculum_component} =
      attrs
      |> Enum.into(%{
        code: "some code",
        name: "some name",
        curriculum_id: curriculum.id
      })
      |> Lanttern.Curricula.create_curriculum_component()

    curriculum_component
  end
end
