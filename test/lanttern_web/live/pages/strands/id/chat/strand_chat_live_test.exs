defmodule LantternWeb.StrandChatLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Repo

  alias Lanttern.AgentChat.Conversation
  alias Lanttern.Identity.Profile

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  defp create_conversation_with_message(profile, strand) do
    conversation =
      insert(:conversation, %{
        profile: profile,
        name: "Test Conversation"
      })

    insert(:strand_conversation, %{
      conversation: conversation,
      strand: strand,
      lesson: nil
    })

    # The conversation component requires at least one message
    insert(:agent_message, %{
      conversation: conversation,
      role: "user",
      content: "Test message"
    })

    conversation
  end

  describe "Rename conversation" do
    test "rename button is not visible when there's no conversation selected", %{
      conn: conn
    } do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat")
      |> refute_has("button", text: "Rename conversation")
    end

    test "rename button is visible when there's a conversation selected", %{
      conn: conn,
      user: user
    } do
      strand = insert(:strand)
      profile = Repo.get!(Profile, user.current_profile.id)
      conversation = create_conversation_with_message(profile, strand)

      # Update the name for this specific test
      Repo.update!(Ecto.Changeset.change(conversation, name: "Test Conversation"))

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat/#{conversation.id}")
      |> assert_has("button", text: "Rename conversation")
    end

    test "clicking rename button opens the rename modal", %{conn: conn, user: user} do
      strand = insert(:strand)
      profile = Repo.get!(Profile, user.current_profile.id)
      conversation = create_conversation_with_message(profile, strand)

      # Update the name for this specific test
      Repo.update!(Ecto.Changeset.change(conversation, name: "Original Name"))

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat/#{conversation.id}")
      |> click_button("Rename conversation")
      |> assert_has("#rename-conversation-overlay")
      |> assert_has("label", text: "Rename conversation")
    end

    test "can cancel the rename modal", %{conn: conn, user: user} do
      strand = insert(:strand)
      profile = Repo.get!(Profile, user.current_profile.id)
      conversation = create_conversation_with_message(profile, strand)

      # Update the name for this specific test
      Repo.update!(Ecto.Changeset.change(conversation, name: "Original Name"))

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat/#{conversation.id}")
      |> click_button("Rename conversation")
      |> assert_has("#rename-conversation-overlay")
      |> click_button("#rename-conversation-overlay button", "Cancel")
      |> refute_has("#rename-conversation-overlay")
    end

    test "can successfully rename a conversation", %{conn: conn, user: user} do
      strand = insert(:strand)
      profile = Repo.get!(Profile, user.current_profile.id)
      conversation = create_conversation_with_message(profile, strand)

      # Update the name for this specific test
      Repo.update!(Ecto.Changeset.change(conversation, name: "Original Name"))

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat/#{conversation.id}")
      |> click_button("Rename conversation")
      |> within("#rename-conversation-overlay", fn session ->
        session
        |> fill_in("Rename conversation", with: "Updated Name")
        |> click_button("Save")
      end)
      |> refute_has("#rename-conversation-overlay")
      |> assert_has("button", text: "Updated Name")

      # Verify the conversation was actually updated in the database
      updated_conversation = Repo.get!(Conversation, conversation.id)
      assert updated_conversation.name == "Updated Name"
    end

    test "updated name appears in the conversation list dropdown", %{conn: conn, user: user} do
      strand = insert(:strand)
      profile = Repo.get!(Profile, user.current_profile.id)
      conversation = create_conversation_with_message(profile, strand)

      # Update the name for this specific test
      Repo.update!(Ecto.Changeset.change(conversation, name: "Original Name"))

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/chat/#{conversation.id}")
      |> click_button("Rename conversation")
      |> within("#rename-conversation-overlay", fn session ->
        session
        |> fill_in("Rename conversation", with: "New Fancy Name")
        |> click_button("Save")
      end)
      # The dropdown menu items should be updated with the new name
      |> assert_has("#conversation-list", text: "New Fancy Name")
    end
  end
end
