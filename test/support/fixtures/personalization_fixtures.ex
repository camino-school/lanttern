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

  # helpers

  defp maybe_gen_author_id(%{author_id: author_id} = _attrs),
    do: author_id

  defp maybe_gen_author_id(_attrs),
    do: teacher_profile_fixture().id
end
