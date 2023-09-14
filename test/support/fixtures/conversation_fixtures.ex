defmodule Lanttern.ConversationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Conversation` context.
  """

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.teacher_profile_fixture().id

    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: Faker.Lorem.paragraph(1..5),
        profile_id: profile_id
      })
      |> Lanttern.Conversation.create_comment()

    comment
  end
end
