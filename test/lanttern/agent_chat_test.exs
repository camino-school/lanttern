defmodule Lanttern.AgentChatTest do
  use Lanttern.DataCase

  alias Lanttern.AgentChat
  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.Identity.Profile
  alias Lanttern.IdentityFixtures

  import Lanttern.Factory

  describe "list_conversations/1" do
    test "returns all conversations from scope's profile ordered by updated_at desc" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      # Insert conversations for the scope's profile with different timestamps
      conversation_1 =
        insert(:conversation, %{
          name: "First Conversation",
          profile: profile,
          inserted_at: ~N[2024-01-01 10:00:00],
          updated_at: ~N[2024-01-01 10:00:00]
        })

      conversation_2 =
        insert(:conversation, %{
          name: "Second Conversation",
          profile: profile,
          inserted_at: ~N[2024-01-02 10:00:00],
          updated_at: ~N[2024-01-03 10:00:00]
        })

      conversation_3 =
        insert(:conversation, %{
          name: "Third Conversation",
          profile: profile,
          inserted_at: ~N[2024-01-03 10:00:00],
          updated_at: ~N[2024-01-02 10:00:00]
        })

      # Create conversation from different profile to verify filtering
      other_profile = insert(:profile)
      insert(:conversation, %{name: "Other Profile Conversation", profile: other_profile})

      conversations = AgentChat.list_conversations(scope)

      # Should be ordered by updated_at desc: conversation_2, conversation_3, conversation_1
      assert [conversation_2.id, conversation_3.id, conversation_1.id] ==
               Enum.map(conversations, & &1.id)
    end

    test "returns empty list when profile has no conversations" do
      scope = IdentityFixtures.scope_fixture()

      assert [] = AgentChat.list_conversations(scope)
    end

    test "does not return conversations from other profiles" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      # Insert conversation for the scope's profile
      conversation = insert(:conversation, %{name: "My Conversation", profile: profile})

      # Create conversations from different profiles
      other_profile_1 = insert(:profile)
      other_profile_2 = insert(:profile)
      insert(:conversation, %{name: "Other Conversation 1", profile: other_profile_1})
      insert(:conversation, %{name: "Other Conversation 2", profile: other_profile_2})

      assert [%Conversation{id: id}] = AgentChat.list_conversations(scope)
      assert id == conversation.id
    end
  end

  describe "get_conversation_with_messages/2" do
    test "returns conversation with preloaded messages ordered by inserted_at" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile})

      # Insert messages with different timestamps
      message_1 =
        insert(:agent_message, %{
          conversation: conversation,
          content: "First message",
          inserted_at: ~N[2024-01-01 10:00:00]
        })

      message_2 =
        insert(:agent_message, %{
          conversation: conversation,
          content: "Second message",
          inserted_at: ~N[2024-01-01 11:00:00]
        })

      message_3 =
        insert(:agent_message, %{
          conversation: conversation,
          content: "Third message",
          inserted_at: ~N[2024-01-01 10:30:00]
        })

      result = AgentChat.get_conversation_with_messages(scope, conversation.id)

      assert %Conversation{messages: messages} = result
      # Should be ordered by inserted_at: message_1, message_3, message_2
      assert [message_1.id, message_3.id, message_2.id] == Enum.map(messages, & &1.id)
    end

    test "returns nil for conversation from different profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})
      insert(:agent_message, %{conversation: conversation})

      assert nil == AgentChat.get_conversation_with_messages(scope, conversation.id)
    end

    test "returns nil for non-existent conversation" do
      scope = IdentityFixtures.scope_fixture()

      assert nil == AgentChat.get_conversation_with_messages(scope, -1)
    end
  end

  describe "create_model_call/2" do
    test "creates a model call record with the given attributes" do
      conversation = insert(:conversation)
      message = insert(:agent_message, %{conversation: conversation})

      attrs = %{
        prompt_tokens: 100,
        completion_tokens: 200,
        model: "gpt-5-nano"
      }

      assert {:ok, %ModelCall{} = model_call} = AgentChat.create_model_call(attrs, message.id)
      assert model_call.prompt_tokens == 100
      assert model_call.completion_tokens == 200
      assert model_call.model == "gpt-5-nano"
      assert model_call.message_id == message.id
    end

    test "creates model call with default token values" do
      conversation = insert(:conversation)
      message = insert(:agent_message, %{conversation: conversation})

      attrs = %{model: "claude-3-opus"}

      assert {:ok, %ModelCall{} = model_call} = AgentChat.create_model_call(attrs, message.id)
      assert model_call.prompt_tokens == 0
      assert model_call.completion_tokens == 0
      assert model_call.model == "claude-3-opus"
    end
  end

  describe "create_conversation_with_message/2" do
    test "creates a new conversation with an initial user message" do
      scope = IdentityFixtures.scope_fixture()

      assert {:ok, %{conversation: conversation, user_message: message}} =
               AgentChat.create_conversation_with_message(scope, "Hello, how can you help?")

      assert %Conversation{} = conversation
      assert conversation.profile_id == scope.profile_id
      assert conversation.school_id == scope.school_id

      assert %Message{} = message
      assert message.role == "user"
      assert message.content == "Hello, how can you help?"
      assert message.conversation_id == conversation.id
    end

    test "creates conversation without a name" do
      scope = IdentityFixtures.scope_fixture()

      assert {:ok, %{conversation: conversation}} =
               AgentChat.create_conversation_with_message(scope, "Test message")

      assert conversation.name == nil
    end
  end

  describe "rename_conversation/3" do
    test "successfully renames a conversation" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: "Old name"})

      assert {:ok, %Conversation{} = updated_conversation} =
               AgentChat.rename_conversation(scope, conversation, "New conversation name")

      assert updated_conversation.name == "New conversation name"
      assert updated_conversation.id == conversation.id
    end

    test "successfully sets name for conversation without initial name" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: nil})

      assert {:ok, %Conversation{} = updated_conversation} =
               AgentChat.rename_conversation(scope, conversation, "First name")

      assert updated_conversation.name == "First name"
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})

      assert_raise MatchError, fn ->
        AgentChat.rename_conversation(scope, conversation, "New name")
      end
    end
  end

  describe "add_user_message/3" do
    test "adds a user message to an existing conversation" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile})

      assert {:ok, %Message{} = message} =
               AgentChat.add_user_message(scope, conversation, "My question")

      assert message.role == "user"
      assert message.content == "My question"
      assert message.conversation_id == conversation.id
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})

      assert_raise MatchError, fn ->
        AgentChat.add_user_message(scope, conversation, "My question")
      end
    end
  end

  describe "add_assistant_message/3" do
    test "adds an assistant message with model call tracking" do
      conversation = insert(:conversation)

      usage_attrs = %{
        prompt_tokens: 50,
        completion_tokens: 100,
        model: "gpt-5-turbo"
      }

      assert {:ok, result} =
               AgentChat.add_assistant_message(
                 conversation.id,
                 "Here is my response",
                 usage_attrs
               )

      assert %Message{} = result.message
      assert result.message.role == "assistant"
      assert result.message.content == "Here is my response"
      assert result.message.conversation_id == conversation.id

      assert %ModelCall{} = result.model_call
      assert result.model_call.prompt_tokens == 50
      assert result.model_call.completion_tokens == 100
      assert result.model_call.model == "gpt-5-turbo"
      assert result.model_call.message_id == result.message.id
    end

    test "updates conversation's updated_at timestamp" do
      conversation =
        insert(:conversation, %{
          updated_at: ~N[2024-01-01 10:00:00]
        })

      usage_attrs = %{prompt_tokens: 10, completion_tokens: 20, model: "test"}

      {:ok, _result} =
        AgentChat.add_assistant_message(conversation.id, "Response", usage_attrs)

      updated_conversation = Repo.get!(Conversation, conversation.id)

      assert NaiveDateTime.compare(updated_conversation.updated_at, conversation.updated_at) ==
               :gt
    end
  end
end
