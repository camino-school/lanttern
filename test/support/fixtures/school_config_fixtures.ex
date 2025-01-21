defmodule Lanttern.SchoolConfigFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.SchoolConfig` context.
  """

  alias Lanttern.SchoolsFixtures

  @doc """
  Generate a moment_card_template.
  """
  def moment_card_template_fixture(attrs \\ %{}) do
    {:ok, moment_card_template} =
      attrs
      |> Enum.into(%{
        name: "some name",
        template: "some template",
        school_id: SchoolsFixtures.maybe_gen_school_id(attrs)
      })
      |> Lanttern.SchoolConfig.create_moment_card_template()

    moment_card_template
  end
end
