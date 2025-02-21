defmodule Lanttern.ILPFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.ILP` context.
  """

  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a ilp_template.
  """
  def ilp_template_fixture(attrs \\ %{}) do
    {:ok, ilp_template} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> Lanttern.ILP.create_ilp_template()

    ilp_template
  end

  @doc """
  Generate a ilp_section.
  """
  def ilp_section_fixture(attrs \\ %{}) do
    {:ok, ilp_section} =
      attrs
      |> Enum.into(%{
        name: "some name",
        position: 42,
        template_id: maybe_gen_template_id(attrs)
      })
      |> Lanttern.ILP.create_ilp_section()

    ilp_section
  end

  # generator helpers

  def maybe_gen_template_id(%{template_id: template_id} = _attrs), do: template_id
  def maybe_gen_template_id(_attrs), do: ilp_template_fixture().id
end
