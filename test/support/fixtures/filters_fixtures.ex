defmodule Lanttern.FiltersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Filters` context.
  """

  alias Lanttern.Filters

  @doc """
  Generate a profile_strand_filter.
  """
  def profile_strand_filter_fixture(attrs \\ %{}) do
    {:ok, profile_strand_filter} =
      attrs
      |> Enum.into(%{
        profile_id: Lanttern.IdentityFixtures.maybe_gen_profile_id(attrs),
        strand_id: Lanttern.LearningContextFixtures.maybe_gen_strand_id(attrs),
        class_id: Lanttern.SchoolsFixtures.maybe_gen_class_id(attrs)
      })
      |> Filters.create_profile_strand_filter()

    profile_strand_filter
  end

  @doc """
  Generate a profile_report_card_filter.
  """
  def profile_report_card_filter_fixture(attrs \\ %{}) do
    {:ok, profile_report_card_filter} =
      attrs
      |> Enum.into(%{
        profile_id: Lanttern.IdentityFixtures.maybe_gen_profile_id(attrs),
        report_card_id: Lanttern.ReportingFixtures.maybe_gen_report_card_id(attrs),
        class_id: Lanttern.SchoolsFixtures.maybe_gen_class_id(attrs)
      })
      |> Filters.create_profile_report_card_filter()

    profile_report_card_filter
  end
end
