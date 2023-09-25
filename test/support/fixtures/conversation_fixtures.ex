defmodule Lanttern.ConversationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Lanttern.Conversation` context.
  """

  alias Lanttern.Conversation

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

  @doc """
  Generate a feedback comment.

  Uses context's `create_feedback_comment/2` function to link
  feedback and comment without the need to handle the relationship table manually
  """
  def feedback_comment_fixture(attrs \\ %{}, feedback_id \\ nil) do
    profile_id =
      Map.get(attrs, :profile_id) || Lanttern.IdentityFixtures.teacher_profile_fixture().id

    feedback_id =
      feedback_id || Lanttern.AssessmentsFixtures.feedback_fixture().id

    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: Faker.Lorem.paragraph(1..5),
        profile_id: profile_id
      })
      |> Conversation.create_feedback_comment(feedback_id)

    comment
  end
end
