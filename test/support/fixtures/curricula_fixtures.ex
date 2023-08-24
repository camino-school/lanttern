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
end
