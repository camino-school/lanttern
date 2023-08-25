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

  @doc """
  Generate a curriculum item.
  """
  def curriculum_item_fixture(attrs \\ %{}) do
    curriculum_component = curriculum_component_fixture()
    subject = Lanttern.TaxonomyFixtures.subject_fixture()
    year = Lanttern.TaxonomyFixtures.year_fixture()

    {:ok, curriculum_item} =
      attrs
      |> Enum.into(%{
        name: "some name",
        code: "some code",
        curriculum_component_id: curriculum_component.id,
        subject_id: subject.id,
        year_id: year.id
      })
      |> Lanttern.Curricula.create_curriculum_item()

    curriculum_item
  end

  @doc """
  Generate a curriculum_relationship.
  """
  def curriculum_relationship_fixture(attrs \\ %{}) do
    curriculum_item_a = curriculum_item_fixture()
    curriculum_item_b = curriculum_item_fixture()

    {:ok, curriculum_relationship} =
      attrs
      |> Enum.into(%{
        curriculum_item_a_id: curriculum_item_a.id,
        curriculum_item_b_id: curriculum_item_b.id,
        type: "cross"
      })
      |> Lanttern.Curricula.create_curriculum_relationship()

    curriculum_relationship
  end
end
