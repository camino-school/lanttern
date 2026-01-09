defmodule Lanttern.SchoolConfigFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.SchoolConfig` context.
  """

  @doc """
  Generate a moment_card_template.
  """
  def moment_card_template_fixture(scope, attrs \\ %{}) do
    {:ok, moment_card_template} =
      attrs
      |> Enum.into(%{
        name: "some name",
        template: "some template"
      })
      |> then(&Lanttern.SchoolConfig.create_moment_card_template(scope, &1))

    moment_card_template
  end
end
