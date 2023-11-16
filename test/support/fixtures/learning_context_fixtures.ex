defmodule Lanttern.LearningContextFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.LearningContext` context.
  """

  @doc """
  Generate a strand.
  """
  def strand_fixture(attrs \\ %{}) do
    {:ok, strand} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description"
      })
      |> Lanttern.LearningContext.create_strand()

    strand
  end
end
