defmodule Lanttern.TaxonomyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Taxonomy` context.
  """

  @doc """
  Generate a subject.
  """
  def subject_fixture(attrs \\ %{}) do
    {:ok, subject} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(5..10)
      })
      |> Lanttern.Taxonomy.create_subject()

    subject
  end

  @doc """
  Generate a year.
  """
  def year_fixture(attrs \\ %{}) do
    {:ok, year} =
      attrs
      |> Enum.into(%{
        name: Faker.Lorem.sentence(5..10)
      })
      |> Lanttern.Taxonomy.create_year()

    year
  end
end
