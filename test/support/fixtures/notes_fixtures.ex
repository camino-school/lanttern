defmodule Lanttern.NotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Notes` context.
  """

  alias Lanttern.Notes

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
      |> Notes.create_note()

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
      Notes.create_strand_note(user, strand_id, attrs)

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
      Notes.create_moment_note(user, moment_id, attrs)

    note
  end
end
