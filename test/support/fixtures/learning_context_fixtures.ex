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
  Generate an moment.
  """
  def moment_fixture(attrs \\ %{}) do
    {:ok, moment} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        strand_id: maybe_gen_strand_id(attrs)
      })
      |> Lanttern.LearningContext.create_moment()

    moment
  end

  @doc """
  Generate a moment_card.
  """
  def moment_card_fixture(scope, attrs \\ %{}) do
    {:ok, moment_card} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        moment_id: maybe_gen_moment_id(attrs),
        school_id: Lanttern.SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> then(&Lanttern.LearningContext.create_moment_card(scope, &1))

    moment_card
  end

  # generator helpers

  def maybe_gen_strand_id(%{strand_id: strand_id} = _attrs), do: strand_id
  def maybe_gen_strand_id(_attrs), do: strand_fixture().id

  def maybe_gen_moment_id(%{moment_id: moment_id} = _attrs), do: moment_id
  def maybe_gen_moment_id(_attrs), do: moment_fixture().id
end
