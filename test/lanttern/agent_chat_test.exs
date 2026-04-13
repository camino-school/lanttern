defmodule Lanttern.AgentChatTest do
  use Lanttern.DataCase

  alias Lanttern.AgentChat
  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.AgentChat.StrandConversation
  alias Lanttern.Identity.Profile
  alias Lanttern.IdentityFixtures
  alias Lanttern.LLM

  import Lanttern.Factory

  describe "list_conversations/2" do
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

    test "filters by strand_id when provided" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      strand_1 = insert(:strand)
      strand_2 = insert(:strand)

      # Conversation linked to strand_1
      conversation_1 = insert(:conversation, %{profile: profile})
      insert(:strand_conversation, %{conversation: conversation_1, strand: strand_1})

      # Conversation linked to strand_2
      conversation_2 = insert(:conversation, %{profile: profile})
      insert(:strand_conversation, %{conversation: conversation_2, strand: strand_2})

      # Conversation without strand link
      _conversation_3 = insert(:conversation, %{profile: profile})

      assert [%Conversation{id: id}] = AgentChat.list_conversations(scope, strand_id: strand_1.id)
      assert id == conversation_1.id
    end

    test "filters by lesson_id when provided" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      strand = insert(:strand)
      lesson_1 = insert(:lesson, strand: strand)
      lesson_2 = insert(:lesson, strand: strand)

      # Conversation linked to lesson_1
      conversation_1 = insert(:conversation, %{profile: profile})

      insert(:strand_conversation, %{
        conversation: conversation_1,
        strand: strand,
        lesson: lesson_1
      })

      # Conversation linked to lesson_2
      conversation_2 = insert(:conversation, %{profile: profile})

      insert(:strand_conversation, %{
        conversation: conversation_2,
        strand: strand,
        lesson: lesson_2
      })

      # Conversation linked to strand without specific lesson
      conversation_3 = insert(:conversation, %{profile: profile})
      insert(:strand_conversation, %{conversation: conversation_3, strand: strand, lesson: nil})

      assert [%Conversation{id: id}] = AgentChat.list_conversations(scope, lesson_id: lesson_1.id)
      assert id == conversation_1.id
    end

    test "filters by both strand_id and lesson_id when provided" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      strand_1 = insert(:strand)
      strand_2 = insert(:strand)
      lesson_1 = insert(:lesson, strand: strand_1)
      lesson_2 = insert(:lesson, strand: strand_2)

      # Conversation linked to strand_1 and lesson_1
      conversation_1 = insert(:conversation, %{profile: profile})

      insert(:strand_conversation, %{
        conversation: conversation_1,
        strand: strand_1,
        lesson: lesson_1
      })

      # Conversation linked to strand_2 and lesson_2
      conversation_2 = insert(:conversation, %{profile: profile})

      insert(:strand_conversation, %{
        conversation: conversation_2,
        strand: strand_2,
        lesson: lesson_2
      })

      assert [%Conversation{id: id}] =
               AgentChat.list_conversations(scope, strand_id: strand_1.id, lesson_id: lesson_1.id)

      assert id == conversation_1.id
    end

    test "filters by lesson_id: nil to return only strand conversations without lesson" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)

      # Conversation linked to strand without lesson
      conversation_strand_only = insert(:conversation, %{profile: profile})
      insert(:strand_conversation, %{conversation: conversation_strand_only, strand: strand})

      # Conversation linked to strand with lesson
      conversation_with_lesson = insert(:conversation, %{profile: profile})

      insert(:strand_conversation, %{
        conversation: conversation_with_lesson,
        strand: strand,
        lesson: lesson
      })

      # Conversation without strand link
      _conversation_no_strand = insert(:conversation, %{profile: profile})

      assert [%Conversation{id: id}] =
               AgentChat.list_conversations(scope, strand_id: strand.id, lesson_id: nil)

      assert id == conversation_strand_only.id
    end
  end

  describe "list_conversation_messages/2" do
    test "returns all messages for a conversation ordered by inserted_at" do
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
          inserted_at: ~N[2024-01-01 12:00:00]
        })

      message_3 =
        insert(:agent_message, %{
          conversation: conversation,
          content: "Third message",
          inserted_at: ~N[2024-01-01 11:00:00]
        })

      messages = AgentChat.list_conversation_messages(scope, conversation)

      # Should be ordered by inserted_at: message_1, message_3, message_2
      assert [message_1.id, message_3.id, message_2.id] == Enum.map(messages, & &1.id)
    end

    test "returns empty list when conversation has no messages" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile})

      assert [] = AgentChat.list_conversation_messages(scope, conversation)
    end

    test "does not return messages from other conversations" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile})
      other_conversation = insert(:conversation, %{profile: profile})

      message = insert(:agent_message, %{conversation: conversation, content: "My message"})
      _other_message = insert(:agent_message, %{conversation: other_conversation})

      assert [%Message{id: id}] = AgentChat.list_conversation_messages(scope, conversation)
      assert id == message.id
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})

      assert_raise MatchError, fn ->
        AgentChat.list_conversation_messages(scope, conversation)
      end
    end
  end

  describe "get_conversation/2" do
    test "returns conversation when it belongs to scope's profile" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile})

      assert %Conversation{id: id} = AgentChat.get_conversation(scope, conversation.id)
      assert id == conversation.id
    end

    test "returns nil for conversation from different profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})

      assert nil == AgentChat.get_conversation(scope, conversation.id)
    end

    test "returns nil for non-existent conversation" do
      scope = IdentityFixtures.scope_fixture()

      assert nil == AgentChat.get_conversation(scope, -1)
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

  describe "create_conversation_with_message/3" do
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

    test "links conversation to strand when strand_id is provided" do
      scope = IdentityFixtures.scope_fixture()
      strand = insert(:strand)

      assert {:ok, result} =
               AgentChat.create_conversation_with_message(
                 scope,
                 "Let's discuss this strand",
                 strand_id: strand.id
               )

      assert %Conversation{} = result.conversation
      assert %Message{} = result.user_message
      assert %StrandConversation{} = result.strand_conversation
      assert result.strand_conversation.conversation_id == result.conversation.id
      assert result.strand_conversation.strand_id == strand.id
      assert result.strand_conversation.lesson_id == nil
    end

    test "links conversation to strand and lesson when both are provided" do
      scope = IdentityFixtures.scope_fixture()
      strand = insert(:strand)
      lesson = insert(:lesson, strand: strand)

      assert {:ok, result} =
               AgentChat.create_conversation_with_message(
                 scope,
                 "Let's discuss this lesson",
                 strand_id: strand.id,
                 lesson_id: lesson.id
               )

      assert %Conversation{} = result.conversation
      assert %Message{} = result.user_message
      assert %StrandConversation{} = result.strand_conversation
      assert result.strand_conversation.conversation_id == result.conversation.id
      assert result.strand_conversation.strand_id == strand.id
      assert result.strand_conversation.lesson_id == lesson.id
    end

    test "does not create strand_conversation when no strand_id is provided" do
      scope = IdentityFixtures.scope_fixture()

      assert {:ok, result} =
               AgentChat.create_conversation_with_message(scope, "Regular conversation")

      assert %Conversation{} = result.conversation
      assert %Message{} = result.user_message
      refute Map.has_key?(result, :strand_conversation)
    end

    test "sets conversation status to processing" do
      scope = IdentityFixtures.scope_fixture()

      assert {:ok, %{conversation: conversation}} =
               AgentChat.create_conversation_with_message(scope, "Hello")

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.status == "processing"
      assert db_conversation.last_error == nil
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

    test "raises FunctionClauseError when name is empty string" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: "Old name"})

      assert_raise FunctionClauseError, fn ->
        AgentChat.rename_conversation(scope, conversation, "")
      end
    end
  end

  describe "change_conversation_name/3" do
    test "returns a changeset for tracking conversation rename changes" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: "Current name"})

      changeset = AgentChat.change_conversation_name(scope, conversation)

      assert %Ecto.Changeset{} = changeset
      assert changeset.data == conversation
    end

    test "returns a changeset with updated attributes" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: "Current name"})

      changeset = AgentChat.change_conversation_name(scope, conversation, %{name: "New name"})

      assert %Ecto.Changeset{} = changeset
      assert Ecto.Changeset.get_change(changeset, :name) == "New name"
    end

    test "validates name is required" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation = insert(:conversation, %{profile: profile, name: "Current name"})

      changeset =
        AgentChat.change_conversation_name(scope, conversation, %{name: ""})
        |> Map.put(:action, :validate)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)

      conversation = insert(:conversation, %{profile: other_profile})

      assert_raise MatchError, fn ->
        AgentChat.change_conversation_name(scope, conversation)
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

    test "sets conversation status to processing and clears last_error" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation =
        insert(:conversation, %{profile: profile, status: "idle", last_error: "Previous error"})

      assert {:ok, %Message{}} = AgentChat.add_user_message(scope, conversation, "Follow-up")

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.status == "processing"
      assert db_conversation.last_error == nil
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

  describe "mark_conversation_idle/3" do
    test "sets conversation status to idle" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile, status: "processing"})

      assert {:ok, %Conversation{}} = AgentChat.mark_conversation_idle(scope, conversation)

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.status == "idle"
    end

    test "clears last_error when called without error" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation =
        insert(:conversation, %{
          profile: profile,
          status: "processing",
          last_error: "Something failed"
        })

      AgentChat.mark_conversation_idle(scope, conversation)

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.last_error == nil
    end

    test "sets last_error when error message is provided" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile, status: "processing"})

      AgentChat.mark_conversation_idle(scope, conversation, "Failed to get AI response")

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.status == "idle"
      assert db_conversation.last_error == "Failed to get AI response"
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)
      conversation = insert(:conversation, %{profile: other_profile, status: "processing"})

      assert_raise MatchError, fn ->
        AgentChat.mark_conversation_idle(scope, conversation)
      end
    end
  end

  describe "mark_conversation_processing/2" do
    test "sets conversation status to processing and clears last_error" do
      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)

      conversation =
        insert(:conversation, %{profile: profile, status: "idle", last_error: "Previous error"})

      assert {:ok, %Conversation{}} = AgentChat.mark_conversation_processing(scope, conversation)

      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.status == "processing"
      assert db_conversation.last_error == nil
    end

    test "raises when scope does not match conversation profile" do
      scope = IdentityFixtures.scope_fixture()
      other_profile = insert(:profile)
      conversation = insert(:conversation, %{profile: other_profile})

      assert_raise MatchError, fn ->
        AgentChat.mark_conversation_processing(scope, conversation)
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

  describe "rename_conversation_from_result/5" do
    setup do
      Mimic.copy(Lanttern.LLM)

      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile, name: nil})

      # Create an LLM.Response with plain messages
      result = %LLM.Response{
        text: "The capital of France is Paris.",
        usage: %{input_tokens: 50, output_tokens: 100},
        messages: [
          %{role: :user, content: "What is the capital of France?"},
          %{role: :assistant, content: "The capital of France is Paris."}
        ]
      }

      %{scope: scope, conversation: conversation, result: result, profile: profile}
    end

    test "successfully renames conversation based on result messages", %{
      scope: scope,
      conversation: conversation,
      result: result
    } do
      Mimic.expect(Lanttern.LLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok, %LLM.Response{object: %{"title" => "Capital of France"}}}
      end)

      assert {:ok, %Conversation{} = renamed} =
               AgentChat.rename_conversation_from_result(scope, conversation, result, "gpt-4",
                 llm_module: Lanttern.LLM
               )

      assert renamed.name == "Capital of France"
      assert renamed.id == conversation.id

      # Verify the conversation was actually updated in the database
      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.name == "Capital of France"
    end

    test "handles LLM errors gracefully", %{
      scope: scope,
      conversation: conversation,
      result: result
    } do
      Mimic.expect(Lanttern.LLM, :generate_object, fn _model, _prompt, _schema ->
        {:error, "API rate limit exceeded"}
      end)

      assert {:error, "API rate limit exceeded"} =
               AgentChat.rename_conversation_from_result(scope, conversation, result, "gpt-4",
                 llm_module: Lanttern.LLM
               )

      # Verify conversation name remains nil
      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.name == nil
    end

    test "raises when scope does not match conversation profile", %{
      result: result,
      profile: profile
    } do
      different_scope = IdentityFixtures.scope_fixture()
      conversation = insert(:conversation, %{profile: profile, name: nil})

      assert_raise MatchError, fn ->
        AgentChat.rename_conversation_from_result(
          different_scope,
          conversation,
          result,
          "gpt-4",
          llm_module: Lanttern.LLM
        )
      end
    end

    test "only works with conversations that have no name", %{
      scope: scope,
      profile: profile,
      result: result
    } do
      conversation_with_name = insert(:conversation, %{profile: profile, name: "Existing Name"})

      # Function pattern match should fail - it only matches conversations with name: nil
      assert_raise FunctionClauseError, fn ->
        AgentChat.rename_conversation_from_result(
          scope,
          conversation_with_name,
          result,
          "gpt-4",
          llm_module: Lanttern.LLM
        )
      end
    end

    test "extracts context from first 4 messages only", %{
      scope: scope,
      conversation: conversation
    } do
      # Create a result with 7 messages (user/assistant pairs + extra user)
      extended_result = %LLM.Response{
        text: "The capital of Germany is Berlin.",
        usage: %{input_tokens: 100, output_tokens: 200},
        messages: [
          %{role: :user, content: "What is the capital of France?"},
          %{role: :assistant, content: "The capital of France is Paris."},
          %{role: :user, content: "What about Italy?"},
          %{role: :assistant, content: "The capital of Italy is Rome."},
          %{role: :user, content: "And Germany?"},
          %{role: :assistant, content: "The capital of Germany is Berlin."},
          %{role: :user, content: "Thanks!"}
        ]
      }

      Mimic.expect(Lanttern.LLM, :generate_object, fn _model, prompt, _schema ->
        # The prompt should only include the first 4 messages
        assert prompt =~ "What is the capital of France?"
        assert prompt =~ "The capital of France is Paris"
        assert prompt =~ "What about Italy?"
        assert prompt =~ "The capital of Italy is Rome"

        # Should NOT include the 5th+ messages
        refute prompt =~ "And Germany?"
        refute prompt =~ "Berlin"

        {:ok, %LLM.Response{object: %{"title" => "European Capitals"}}}
      end)

      assert {:ok, %Conversation{}} =
               AgentChat.rename_conversation_from_result(
                 scope,
                 conversation,
                 extended_result,
                 "gpt-4",
                 llm_module: Lanttern.LLM
               )
    end

    test "truncates titles longer than 50 characters", %{
      scope: scope,
      conversation: conversation,
      result: result
    } do
      long_title = "This is a very long conversation title that exceeds fifty characters"
      expected_title = String.slice(long_title, 0, 50)

      Mimic.expect(Lanttern.LLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok, %LLM.Response{object: %{"title" => long_title}}}
      end)

      assert {:ok, %Conversation{} = renamed} =
               AgentChat.rename_conversation_from_result(scope, conversation, result, "gpt-4",
                 llm_module: Lanttern.LLM
               )

      assert renamed.name == expected_title
      assert String.length(renamed.name) == 50
    end
  end

  describe "run_llm_chain/4" do
    import Lanttern.TaxonomyFixtures
    import Lanttern.LearningContextFixtures

    alias Lanttern.Lessons

    setup do
      Mimic.copy(Lanttern.LLM)

      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile})

      user_message =
        insert(:agent_message, %{
          conversation: conversation,
          role: "user",
          content: "Test question"
        })

      %{scope: scope, messages: [user_message]}
    end

    defp build_generate_text_with_tools_response(messages) do
      {:ok,
       %LLM.Response{
         text: "Test response",
         usage: %{input_tokens: 50, output_tokens: 100},
         messages: messages ++ [%{role: :assistant, content: "Test response"}]
       }}
    end

    defp extract_system_text(messages) do
      system_msg = Enum.find(messages, &(&1.role == :system))

      case system_msg do
        nil -> nil
        msg -> msg.content
      end
    end

    test "runs LLM chain with basic messages", %{scope: scope, messages: messages} do
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        # Verify messages include at least a user message
        assert Enum.any?(msgs, &(&1.role == :user))

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{} = result} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)

      assert is_binary(result.text)
      assert result.usage.input_tokens > 0
    end

    test "adds strand system messages when strand_id is provided", %{
      scope: scope,
      messages: messages
    } do
      subject = subject_fixture(%{name: "Science"})
      year = year_fixture(%{name: "Year 5"})

      strand =
        strand_fixture(%{
          name: "Environmental Science",
          description: "Study of ecosystems",
          subjects_ids: [subject.id],
          years_ids: [year.id]
        })

      moment_fixture(%{
        strand_id: strand.id,
        name: "Introduction",
        description: "Intro to ecosystems",
        position: 1
      })

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<strand_context>"
        assert system_text =~ "Environmental Science"
        assert system_text =~ "Science"
        assert system_text =~ "Year 5"
        assert system_text =~ "Introduction"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "adds lesson system messages when lesson_id is provided", %{
      scope: scope,
      messages: messages
    } do
      subject = subject_fixture(%{name: "Mathematics"})
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(scope, %{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Introduction to Algebra",
          description: "Basic algebraic concepts",
          teacher_notes: "Focus on variables",
          differentiation_notes: "Provide extra examples",
          subjects_ids: [subject.id]
        })

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<lesson_context>"
        assert system_text =~ "Introduction to Algebra"
        assert system_text =~ "Basic algebraic concepts"
        assert system_text =~ "Mathematics"
        assert system_text =~ "Week 1"
        assert system_text =~ "Focus on variables"
        assert system_text =~ "Provide extra examples"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 lesson_id: lesson.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "adds both strand and lesson system messages when both are provided", %{
      scope: scope,
      messages: messages
    } do
      strand = strand_fixture(%{name: "Biology Strand"})
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 2", position: 2})

      {:ok, lesson} =
        Lessons.create_lesson(scope, %{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Cell Biology",
          description: "Introduction to cells"
        })

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<strand_context>"
        assert system_text =~ "<lesson_context>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 lesson_id: lesson.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "adds update_lesson tool when enabled_functions includes it", %{
      scope: scope,
      messages: messages
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(scope, %{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Original description"
        })

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        # Verify that update_lesson tool was added
        assert length(tools) == 1
        [tool] = tools
        assert tool.name == "update_lesson"

        # Verify tool has the expected parameters
        param_names = Keyword.keys(tool.parameter_schema)
        assert :description in param_names
        assert :teacher_notes in param_names
        assert :differentiation_notes in param_names
        assert :name in param_names

        # On update the lesson already has a name, so the LLM must be allowed
        # to omit it. `required: true` here would force pointless rewrites.
        refute Keyword.get(tool.parameter_schema, :name)[:required] == true

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 lesson_id: lesson.id,
                 enabled_functions: ["update_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "create_lesson tool marks :name as required", %{
      scope: scope,
      messages: messages
    } do
      strand = insert(:strand)
      insert(:moment, strand: strand, name: "Week 1", position: 1)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        [tool] = tools
        assert tool.name == "create_lesson"
        assert Keyword.get(tool.parameter_schema, :name)[:required] == true

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "create_lesson tool surfaces changeset errors without raising", %{
      scope: scope,
      messages: messages
    } do
      strand = insert(:strand)
      insert(:moment, strand: strand, name: "Week 1", position: 1)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        [tool] = tools

        # Force a failed changeset by omitting required :name — must return an
        # {:error, "ERROR: ..."} tuple, not crash.
        assert {:error, "ERROR: " <> reason} =
                 tool.callback.(%{description: "no name provided"})

        assert reason =~ "name"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "update_lesson tool successfully updates the lesson", %{
      scope: scope,
      messages: messages
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(scope, %{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Original description",
          teacher_notes: "Original notes"
        })

      # The wrapper handles the tool loop internally, so we mock generate_text_with_tools
      # to simulate the tool being called and the lesson being updated
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        # Execute the update_lesson tool callback directly
        [tool] = tools
        assert tool.name == "update_lesson"

        {:ok, _} =
          tool.callback.(%{
            "description" => "Updated description from AI",
            "teacher_notes" => "Updated teacher notes"
          })

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 lesson_id: lesson.id,
                 enabled_functions: ["update_lesson"],
                 llm_module: Lanttern.LLM
               )

      # Verify lesson was actually updated in the database
      updated_lesson = Lessons.get_lesson!(lesson.id)
      assert updated_lesson.description == "Updated description from AI"
      assert updated_lesson.teacher_notes == "Updated teacher notes"
    end

    test "does not add update_lesson tool when not in enabled_functions", %{
      scope: scope,
      messages: messages
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(scope, %{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Some description"
        })

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        # Verify no tools were added
        assert tools == []

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 lesson_id: lesson.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "does not add update_lesson tool when lesson_id is missing", %{
      scope: scope,
      messages: messages
    } do
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        # Verify no tools were added even though enabled_functions includes update_lesson
        assert tools == []

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 enabled_functions: ["update_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "raises when last message is not a user message", %{
      scope: scope
    } do
      conversation = insert(:conversation)

      messages = [
        insert(:agent_message, %{
          conversation: conversation,
          role: "user",
          content: "Question"
        }),
        insert(:agent_message, %{
          conversation: conversation,
          role: "assistant",
          content: "Answer"
        })
      ]

      assert_raise MatchError, fn ->
        AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
      end
    end

    test "returns error when LLM chain fails", %{scope: scope, messages: messages} do
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, _msgs, _tools ->
        {:error, "API error"}
      end)

      assert {:error, "API error"} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "adds school system messages when ai_config exists with knowledge", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      insert(:ai_config,
        school: school,
        knowledge: "Our school uses project-based learning",
        guardrails: nil
      )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<school_knowledge>"
        assert system_text =~ "Our school uses project-based learning"

        # Should NOT have guardrails (it's nil)
        refute system_text =~ "<school_guardrails>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "adds school system messages when ai_config exists with guardrails", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      insert(:ai_config,
        school: school,
        knowledge: nil,
        guardrails: "Always be respectful and supportive"
      )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil

        # Should NOT have knowledge (it's nil)
        refute system_text =~ "<school_knowledge>"

        # Should have guardrails
        assert system_text =~ "<school_guardrails>"
        assert system_text =~ "Always be respectful and supportive"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "adds both school knowledge and guardrails when ai_config has both", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      insert(:ai_config,
        school: school,
        knowledge: "School knowledge content",
        guardrails: "School guardrails content"
      )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<school_knowledge>"
        assert system_text =~ "School knowledge content"
        assert system_text =~ "<school_guardrails>"
        assert system_text =~ "School guardrails content"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "does not add school system messages when ai_config does not exist", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      # No ai_config inserted for this school

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        # Should have no school-related content in system message
        # (system_text might be nil if no system messages at all, or might not contain school tags)
        if system_text do
          refute system_text =~ "<school_knowledge>"
          refute system_text =~ "<school_guardrails>"
        end

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "ignores empty string knowledge and guardrails in ai_config", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      insert(:ai_config,
        school: school,
        knowledge: "",
        guardrails: ""
      )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        # Should have no school-related content (empty strings are ignored)
        if system_text do
          refute system_text =~ "<school_knowledge>"
          refute system_text =~ "<school_guardrails>"
        end

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "adds create_lesson tool when enabled_functions includes it", %{
      scope: scope,
      messages: messages
    } do
      strand = insert(:strand, name: "Test Strand")
      insert(:moment, strand: strand, name: "Week 1", position: 1)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        assert length(tools) == 1
        [tool] = tools
        assert tool.name == "create_lesson"

        param_names = Keyword.keys(tool.parameter_schema)
        assert :description in param_names
        assert :teacher_notes in param_names
        assert :moment_id in param_names
        assert :subjects_ids in param_names

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "create_lesson tool successfully creates a lesson", %{
      scope: scope,
      messages: messages
    } do
      subject = insert(:subject, name: "Science")
      strand = insert(:strand, subjects: [subject])
      moment = insert(:moment, strand: strand, name: "Week 1", position: 1)

      # The wrapper handles the tool loop internally, so we mock generate_text_with_tools
      # to simulate the tool being called and the lesson being created
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        # Execute the create_lesson tool callback directly
        [tool] = tools
        assert tool.name == "create_lesson"

        {:ok, _} =
          tool.callback.(%{
            name: "AI Lesson",
            description: "AI-created lesson content",
            teacher_notes: "AI teacher notes",
            moment_id: moment.id,
            subjects_ids: [subject.id]
          })

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )

      # Verify lesson was actually created in the database
      lessons = Lessons.list_lessons(strand_id: strand.id)
      assert length(lessons) == 1
      [lesson] = lessons
      assert lesson.description == "AI-created lesson content"
      assert lesson.teacher_notes == "AI teacher notes"
    end

    test "does not add create_lesson tool when strand_id is missing", %{
      scope: scope,
      messages: messages
    } do
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, tools ->
        assert tools == []

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "adds agent system messages when agent_id is provided", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      agent =
        insert(:agent,
          school: school,
          personality: "Friendly teacher",
          instructions: "Help plan lessons",
          knowledge: "Curriculum expertise",
          guardrails: "Stay on topic"
        )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<agent_personality>Friendly teacher</agent_personality>"
        assert system_text =~ "<agent_instructions>Help plan lessons</agent_instructions>"
        assert system_text =~ "<agent_knowledge>Curriculum expertise</agent_knowledge>"
        assert system_text =~ "<agent_guardrails>Stay on topic</agent_guardrails>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 agent_id: agent.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "filters out empty agent fields from system messages", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      agent =
        insert(:agent,
          school: school,
          personality: "Friendly",
          instructions: nil,
          knowledge: "",
          guardrails: nil
        )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<agent_personality>Friendly</agent_personality>"
        refute system_text =~ "<agent_instructions>"
        refute system_text =~ "<agent_knowledge>"
        refute system_text =~ "<agent_guardrails>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 agent_id: agent.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "adds staff member system messages when scope has staff_member_id", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()

      # scope_fixture creates a staff_member with the profile
      staff_member = Lanttern.Schools.get_staff_member!(scope.staff_member_id)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<staff_member_context>"
        assert system_text =~ "<name>#{staff_member.name}</name>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4", llm_module: Lanttern.LLM)
    end

    test "adds lesson template system messages when lesson_template_id is provided", %{
      messages: messages
    } do
      scope = IdentityFixtures.scope_fixture()
      school = Lanttern.Schools.get_school!(scope.school_id)

      lesson_template =
        insert(:lesson_template,
          school: school,
          about: "A project-based template",
          template: "## Introduction\n## Activities"
        )

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil

        assert system_text =~
                 "<lesson_template_info>A project-based template</lesson_template_info>"

        assert system_text =~ "<lesson_template>## Introduction"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 lesson_template_id: lesson_template.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "adds tools_args system messages when lesson functions enabled with strand", %{
      scope: scope,
      messages: messages
    } do
      subject = insert(:subject, name: "Art")
      year = insert(:year, name: "Year 3")

      strand =
        insert(:strand,
          name: "Creative Arts",
          subjects: [subject],
          years: [year]
        )

      insert(:moment, strand: strand, name: "Intro", position: 1)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        assert system_text != nil
        assert system_text =~ "<tools_args>"
        assert system_text =~ "<moments>"
        assert system_text =~ "<subjects>"

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end

    test "does not add tools_args when no lesson functions enabled", %{
      scope: scope,
      messages: messages
    } do
      strand = insert(:strand)
      insert(:moment, strand: strand, name: "Week 1", position: 1)

      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, msgs, _tools ->
        system_text = extract_system_text(msgs)

        if system_text do
          refute system_text =~ "<tools_args>"
        end

        build_generate_text_with_tools_response(msgs)
      end)

      assert {:ok, %LLM.Response{}} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 llm_module: Lanttern.LLM
               )
    end

    test "returns error when tool call loop exceeds max iterations", %{
      scope: scope,
      messages: messages
    } do
      strand = insert(:strand)
      _moment = insert(:moment, strand: strand, name: "Week 1", position: 1)

      # The tool loop is now inside Lanttern.LLM, so we mock it to return the error directly
      Mimic.expect(Lanttern.LLM, :generate_text_with_tools, fn _model, _msgs, _tools ->
        {:error, :max_tool_iterations_exceeded}
      end)

      assert {:error, :max_tool_iterations_exceeded} =
               AgentChat.run_llm_chain(scope, messages, "gpt-4",
                 strand_id: strand.id,
                 enabled_functions: ["create_lesson"],
                 llm_module: Lanttern.LLM
               )
    end
  end
end
