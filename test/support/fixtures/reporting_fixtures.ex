defmodule Lanttern.ReportingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Reporting` context.
  """

  @doc """
  Generate a report_card.
  """
  def report_card_fixture(attrs \\ %{}) do
    {:ok, report_card} =
      attrs
      |> Enum.into(%{
        name: "some name",
        description: "some description",
        school_cycle_id: maybe_gen_school_cycle_id(attrs)
      })
      |> Lanttern.Reporting.create_report_card()

    report_card
  end

  defp maybe_gen_school_cycle_id(%{school_cycle_id: school_cycle_id} = _attrs),
    do: school_cycle_id

  defp maybe_gen_school_cycle_id(_attrs),
    do: Lanttern.SchoolsFixtures.cycle_fixture().id
end
