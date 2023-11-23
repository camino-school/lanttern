defmodule Lanttern.PersonalizationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Personalization` context.
  """

  import Lanttern.IdentityFixtures

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        author_id: maybe_gen_author_id(attrs),
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
  Generate an activity note.
  """
  def activity_note_fixture(user, activity_id, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "description" => "some description"
      })

    {:ok, note} =
      Lanttern.Personalization.create_activity_note(user, activity_id, attrs)

    note
  end

  # helpers

  defp maybe_gen_author_id(%{author_id: author_id} = _attrs),
    do: author_id

  defp maybe_gen_author_id(_attrs),
    do: teacher_profile_fixture().id
end
