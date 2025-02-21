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
        position: 42,
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> Lanttern.ILP.create_ilp_template()

    ilp_template
  end
end
