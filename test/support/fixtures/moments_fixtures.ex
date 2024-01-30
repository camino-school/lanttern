defmodule Lanttern.MomentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Moments` context.
  """

  @doc """
  Generate a moment_card.
  """
  def moment_card_fixture(attrs \\ %{}) do
    {:ok, moment_card} =
      attrs
      |> Enum.into(%{
        name: "some name",
        position: 42,
        description: "some description",
        moment_id: maybe_gen_moment_id(attrs)
      })
      |> Lanttern.Moments.create_moment_card()

    moment_card
  end

  # helpers

  defp maybe_gen_moment_id(%{moment_id: moment_id} = _attrs),
    do: moment_id

  defp maybe_gen_moment_id(_attrs),
    do: Lanttern.LearningContextFixtures.moment_fixture().id
end
