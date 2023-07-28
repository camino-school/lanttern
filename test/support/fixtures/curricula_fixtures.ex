defmodule Lanttern.CurriculaFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Curricula` context.
  """

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
