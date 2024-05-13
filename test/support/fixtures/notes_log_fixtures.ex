defmodule Lanttern.NotesLogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.NotesLog` context.
  """

  import Lanttern.NotesFixtures
  alias Lanttern.IdentityFixtures

  @doc """
  Generate a note_log.
  """
  def note_log_fixture(attrs \\ %{}) do
    {:ok, note_log} =
      attrs
      |> Enum.into(%{
        note_id: maybe_gen_note_id(attrs),
        author_id: IdentityFixtures.maybe_gen_profile_id(attrs),
        description: "some description",
        operation: "CREATE"
      })
      |> Lanttern.NotesLog.create_note_log()

    note_log
  end
end
