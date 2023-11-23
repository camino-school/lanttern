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

  @doc """
  Generate an activity.
  """
  def activity_fixture(attrs \\ %{}) do
    {:ok, activity} =
      attrs
      |> Enum.into(%{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: maybe_gen_strand_id(attrs)
      })
      |> Lanttern.LearningContext.create_activity()

    activity
  end

  # helpers

  defp maybe_gen_strand_id(%{strand_id: strand_id} = _attrs),
    do: strand_id

  defp maybe_gen_strand_id(_attrs),
    do: strand_fixture().id
end
