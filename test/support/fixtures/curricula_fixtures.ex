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
        code: Faker.String.base64(100),
        name: Faker.Lorem.sentence(5..10)
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
        code: Faker.String.base64(100),
        name: Faker.Lorem.sentence(5..10),
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

    {:ok, curriculum_item} =
      attrs
      |> Enum.into(%{
        code: Faker.String.base64(100),
        name: Faker.Lorem.sentence(5..10),
        curriculum_component_id: curriculum_component.id
      })
      |> Lanttern.Curricula.create_curriculum_item()

    # use get_curriculum_item to retrieve generated searchable field from DB
    Lanttern.Curricula.get_curriculum_item!(curriculum_item.id)
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
