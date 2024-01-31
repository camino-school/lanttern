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

  # helpers

  defp maybe_gen_author_id(%{author_id: author_id} = _attrs),
    do: author_id

  defp maybe_gen_author_id(_attrs),
    do: teacher_profile_fixture().id
end
