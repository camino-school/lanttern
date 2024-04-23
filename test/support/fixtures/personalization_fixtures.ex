defmodule Lanttern.PersonalizationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Personalization` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        author_id: Lanttern.IdentityFixtures.maybe_gen_profile_id(attrs),
        description: "some description"
      })
      |> Lanttern.Personalization.create_note()

    note
  end

  @doc """
  Generate a strand note.
  """
  def strand_note_fixture(user, strand_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "description" => "some description"
      })

    {:ok, note} =
      Lanttern.Personalization.create_strand_note(user, strand_id, attrs)

    note
  end

  @doc """
  Generate a moment note.
  """
  def moment_note_fixture(user, moment_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "description" => "some description"
      })

    {:ok, note} =
      Lanttern.Personalization.create_moment_note(user, moment_id, attrs)

    note
  end

  @doc """
  Generate a profile_view.
  """
  def profile_view_fixture(attrs \\ %{}) do
    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.teacher_profile_fixture().id

    {:ok, profile_view} =
      attrs
      |> Enum.into(%{
        name: "some name",
        profile_id: profile_id
      })
      |> Lanttern.Personalization.create_profile_view()

    profile_view
  end

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
      |> Lanttern.Personalization.create_profile_strand_filter()

    profile_strand_filter
  end

  @doc """
  Generate a profile_report_card_filters.
  """
  def profile_report_card_filters_fixture(attrs \\ %{}) do
    {:ok, profile_report_card_filters} =
      attrs
      |> Enum.into(%{
        profile_id: Lanttern.IdentityFixtures.maybe_gen_profile_id(attrs),
        report_card_id: Lanttern.ReportingFixtures.maybe_gen_report_card_id(attrs),
        class_id: Lanttern.SchoolsFixtures.maybe_gen_class_id(attrs)
      })
      |> Lanttern.Personalization.create_profile_report_card_filters()

    profile_report_card_filters
  end
end
