defmodule Lanttern.StudentTagsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.StudentTags` context.
  """

  import Lanttern.SchoolsFixtures

  @doc """
  Generate a student tag.
  """
  def student_tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> Enum.into(%{
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff",
        school_id: maybe_gen_school_id(attrs)
      })
      |> Lanttern.StudentTags.create_student_tag()

    tag
  end
end
