defmodule Lanttern.ConversationTest do
  use Lanttern.DataCase

  alias Lanttern.Conversation

  describe "comments" do
    alias Lanttern.Conversation.Comment

    import Lanttern.ConversationFixtures

    @invalid_attrs %{comment: nil}

    test "list_comments/1 returns all comments" do
      comment = comment_fixture()
      assert Conversation.list_comments() == [comment]
    end

    test "list_comments/1 with preloads returns all comments with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      comment = comment_fixture(%{profile_id: profile.id})

      [expected] = Conversation.list_comments(preloads: :profile)

      assert expected.id == comment.id
      assert expected.profile.id == profile.id
    end

    test "get_comment!/2 returns the comment with given id" do
      comment = comment_fixture()
      assert Conversation.get_comment!(comment.id) == comment
    end

    test "get_comment!/2 with preloads returns the comment with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      comment = comment_fixture(%{profile_id: profile.id})

      expected = Conversation.get_comment!(comment.id, preloads: :profile)

      assert expected.id == comment.id
      assert expected.profile.id == profile.id
    end

    test "create_comment/1 with valid data creates a comment" do
      profile = Lanttern.IdentityFixtures.student_profile_fixture()
      valid_attrs = %{comment: "some comment", profile_id: profile.id}

      assert {:ok, %Comment{} = comment} = Conversation.create_comment(valid_attrs)
      assert comment.comment == "some comment"
      assert comment.profile_id == profile.id
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Conversation.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{comment: "some updated comment"}

      assert {:ok, %Comment{} = comment} = Conversation.update_comment(comment, update_attrs)
      assert comment.comment == "some updated comment"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Conversation.update_comment(comment, @invalid_attrs)
      assert comment == Conversation.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Conversation.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Conversation.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Conversation.change_comment(comment)
    end
  end

  describe "feedback_comments" do
    alias Lanttern.Conversation.Comment
    alias Lanttern.Assessments

    test "create_feedback_comment/2 with valid data creates a comment linked to feedback" do
      feedback = Lanttern.AssessmentsFixtures.feedback_fixture()
      profile = Lanttern.IdentityFixtures.student_profile_fixture()

      valid_attrs = %{
        comment: Faker.Lorem.paragraph(1..5),
        profile_id: profile.id
      }

      assert {:ok, %Comment{} = comment} =
               Conversation.create_feedback_comment(valid_attrs, feedback.id)

      assert comment.comment == valid_attrs.comment
      assert comment.profile_id == profile.id

      %{comments: [expected]} = Assessments.get_feedback!(feedback.id, preloads: :comments)
      assert expected.id == comment.id
    end

    test "create_feedback_comment/2 does not erases existing comments" do
      feedback = Lanttern.AssessmentsFixtures.feedback_fixture()
      profile = Lanttern.IdentityFixtures.student_profile_fixture()

      valid_attrs_1 = %{
        comment: Faker.Lorem.paragraph(1..5),
        profile_id: profile.id
      }

      valid_attrs_2 = %{
        comment: Faker.Lorem.paragraph(1..5),
        profile_id: profile.id
      }

      assert {:ok, %Comment{} = comment_1} =
               Conversation.create_feedback_comment(valid_attrs_1, feedback.id)

      assert {:ok, %Comment{} = comment_2} =
               Conversation.create_feedback_comment(valid_attrs_2, feedback.id)

      %{comments: expected} = Assessments.get_feedback!(feedback.id, preloads: :comments)
      assert length(expected) == 2

      for c <- expected do
        c.id in [comment_1.id, comment_2.id]
      end
    end
  end
end
