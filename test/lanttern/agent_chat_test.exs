defmodule Lanttern.AgentChatTest do
  use Lanttern.DataCase

  alias Lanttern.AgentChat
  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.AgentChat.StrandConversation
  alias Lanttern.Identity.Profile
  alias Lanttern.IdentityFixtures

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

  describe "rename_conversation_based_on_chain/3" do
    setup do
      Mimic.copy(LangChain.Chains.LLMChain)

      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile, name: nil})

      # Create a mock LLM
      mock_llm = LangChain.ChatModels.ChatOpenAI.new!(%{model: "gpt-4", api_key: "test-key"})

      # Create a chain with sample messages
      chain =
        LangChain.Chains.LLMChain.new!(%{llm: mock_llm})
        |> LangChain.Chains.LLMChain.add_message(
          LangChain.Message.new_user!("What is the capital of France?")
        )
        |> LangChain.Chains.LLMChain.add_message(
          LangChain.Message.new_assistant!("The capital of France is Paris.")
        )

      %{scope: scope, conversation: conversation, chain: chain, profile: profile}
    end

    test "successfully renames conversation based on chain messages", %{
      scope: scope,
      conversation: conversation,
      chain: chain
    } do
      # Mock LLMChain.run to execute the function and return the result
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        # Extract the function from the chain
        [rename_function] = naming_chain.tools

        # Simulate the LLM calling the function with a title
        {:ok, content, updated_conv} =
          rename_function.function.(%{"title" => "Capital of France"}, %{})

        # Create a proper ToolResult
        tool_result =
          LangChain.Message.ToolResult.new!(%{
            type: :function,
            tool_call_id: "call_123",
            name: "set_conversation_title",
            content: content,
            processed_content: updated_conv
          })

        # Return a chain with the tool result
        result_chain = %{
          naming_chain
          | messages:
              naming_chain.messages ++
                [
                  LangChain.Message.new_tool_result!(%{
                    tool_results: [tool_result]
                  })
                ]
        }

        {:ok, result_chain}
      end)

      assert {:ok, %Conversation{} = result} =
               AgentChat.rename_conversation_based_on_chain(scope, conversation, chain)

      assert result.name == "Capital of France"
      assert result.id == conversation.id

      # Verify the conversation was actually updated in the database
      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.name == "Capital of France"
    end

    test "handles LLM errors gracefully", %{
      scope: scope,
      conversation: conversation,
      chain: chain
    } do
      error = %LangChain.LangChainError{message: "API rate limit exceeded"}

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn _chain, _opts ->
        {:error, chain, error}
      end)

      assert {:error, %LangChain.LangChainError{}} =
               AgentChat.rename_conversation_based_on_chain(scope, conversation, chain)

      # Verify conversation name remains nil
      db_conversation = Repo.get!(Conversation, conversation.id)
      assert db_conversation.name == nil
    end

    test "handles missing tool result by reloading conversation", %{
      scope: scope,
      conversation: conversation,
      chain: chain
    } do
      # Mock response chain without tool result
      response_chain = %{
        chain
        | messages: chain.messages ++ [LangChain.Message.new_assistant!("I cannot help")]
      }

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn _chain, _opts ->
        {:ok, response_chain}
      end)

      assert {:ok, %Conversation{} = result} =
               AgentChat.rename_conversation_based_on_chain(scope, conversation, chain)

      # Should return the conversation reloaded from DB
      assert result.id == conversation.id
    end

    test "raises when scope does not match conversation profile", %{
      chain: chain,
      profile: profile
    } do
      different_scope = IdentityFixtures.scope_fixture()
      conversation = insert(:conversation, %{profile: profile, name: nil})

      assert_raise MatchError, fn ->
        AgentChat.rename_conversation_based_on_chain(different_scope, conversation, chain)
      end
    end

    test "only works with conversations that have no name", %{
      scope: scope,
      profile: profile,
      chain: chain
    } do
      conversation_with_name = insert(:conversation, %{profile: profile, name: "Existing Name"})

      # Function pattern match should fail - it only matches conversations with name: nil
      assert_raise FunctionClauseError, fn ->
        AgentChat.rename_conversation_based_on_chain(scope, conversation_with_name, chain)
      end
    end

    test "extracts context from first 4 messages only", %{
      scope: scope,
      conversation: conversation,
      chain: chain
    } do
      # Add more messages to chain (total will be 7 messages)
      extended_chain =
        chain
        |> LangChain.Chains.LLMChain.add_message(LangChain.Message.new_user!("What about Italy?"))
        |> LangChain.Chains.LLMChain.add_message(
          LangChain.Message.new_assistant!("The capital of Italy is Rome.")
        )
        |> LangChain.Chains.LLMChain.add_message(LangChain.Message.new_user!("And Germany?"))
        |> LangChain.Chains.LLMChain.add_message(
          LangChain.Message.new_assistant!("The capital of Germany is Berlin.")
        )
        |> LangChain.Chains.LLMChain.add_message(LangChain.Message.new_user!("Thanks!"))

      # Capture the chain that gets passed to run to verify context building
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        # The naming chain should have 1 message (the naming prompt)
        # And it should only reference the first 4 messages from the original chain
        assert length(naming_chain.messages) == 1
        [naming_message] = naming_chain.messages
        assert naming_message.role == :user

        # The content should only include first 4 messages (2 user + 2 assistant from extended_chain)
        content = LangChain.Message.ContentPart.content_to_string(naming_message.content)
        assert content =~ "What is the capital of France?"
        assert content =~ "The capital of France is Paris"
        assert content =~ "What about Italy?"
        assert content =~ "The capital of Italy is Rome"

        # Should NOT include the 5th+ messages
        refute content =~ "And Germany?"
        refute content =~ "Berlin"

        # Execute the function to update the conversation
        [rename_function] = naming_chain.tools

        {:ok, content, updated_conv} =
          rename_function.function.(%{"title" => "European Capitals"}, %{})

        tool_result =
          LangChain.Message.ToolResult.new!(%{
            type: :function,
            tool_call_id: "call_123",
            name: "set_conversation_title",
            content: content,
            processed_content: updated_conv
          })

        result_chain = %{
          naming_chain
          | messages:
              naming_chain.messages ++
                [LangChain.Message.new_tool_result!(%{tool_results: [tool_result]})]
        }

        {:ok, result_chain}
      end)

      assert {:ok, %Conversation{}} =
               AgentChat.rename_conversation_based_on_chain(scope, conversation, extended_chain)
    end

    test "truncates titles longer than 50 characters", %{
      scope: scope,
      conversation: conversation,
      chain: chain
    } do
      long_title = "This is a very long conversation title that exceeds fifty characters"
      expected_title = String.slice(long_title, 0, 50)

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        # Execute the function with a long title
        [rename_function] = naming_chain.tools
        {:ok, content, updated_conv} = rename_function.function.(%{"title" => long_title}, %{})

        tool_result =
          LangChain.Message.ToolResult.new!(%{
            type: :function,
            tool_call_id: "call_123",
            name: "set_conversation_title",
            content: content,
            processed_content: updated_conv
          })

        result_chain = %{
          naming_chain
          | messages:
              naming_chain.messages ++
                [LangChain.Message.new_tool_result!(%{tool_results: [tool_result]})]
        }

        {:ok, result_chain}
      end)

      assert {:ok, %Conversation{} = result} =
               AgentChat.rename_conversation_based_on_chain(scope, conversation, chain)

      assert result.name == expected_title
      assert String.length(result.name) == 50
    end
  end

  describe "run_llm_chain/4" do
    import Lanttern.TaxonomyFixtures
    import Lanttern.LearningContextFixtures

    alias Lanttern.Lessons

    setup do
      Mimic.copy(LangChain.Chains.LLMChain)

      scope = IdentityFixtures.scope_fixture()
      profile = Repo.get!(Profile, scope.profile_id)
      conversation = insert(:conversation, %{profile: profile})

      user_message =
        insert(:agent_message, %{
          conversation: conversation,
          role: "user",
          content: "Test question"
        })

      mock_llm = LangChain.ChatModels.ChatOpenAI.new!(%{model: "gpt-4", api_key: "test-key"})

      %{scope: scope, messages: [user_message], llm: mock_llm}
    end

    test "runs LLM chain with basic messages", %{scope: scope, messages: messages, llm: llm} do
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify chain structure - should have 1 user message
        assert length(chain.messages) == 1
        assert hd(chain.messages).role == :user

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Test response")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{} = chain} =
               AgentChat.run_llm_chain(scope, messages, llm)

      # Verify the chain has both user and assistant messages
      assert length(chain.messages) == 2
    end

    test "adds strand system messages when strand_id is provided", %{
      scope: scope,
      messages: messages,
      llm: llm
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

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify that strand system message was added
        system_messages = Enum.filter(chain.messages, &(&1.role == :system))
        assert length(system_messages) >= 1

        # Find the strand context message
        strand_message =
          Enum.find(system_messages, fn msg ->
            content = LangChain.Message.ContentPart.content_to_string(msg.content)
            content =~ "<strand_context>"
          end)

        assert strand_message != nil

        strand_content = LangChain.Message.ContentPart.content_to_string(strand_message.content)
        assert strand_content =~ "Environmental Science"
        assert strand_content =~ "Science"
        assert strand_content =~ "Year 5"
        assert strand_content =~ "Introduction"

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Strand-aware response")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm, strand_id: strand.id)
    end

    test "adds lesson system messages when lesson_id is provided", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      subject = subject_fixture(%{name: "Mathematics"})
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(%{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Introduction to Algebra",
          description: "Basic algebraic concepts",
          teacher_notes: "Focus on variables",
          differentiation_notes: "Provide extra examples",
          subjects_ids: [subject.id]
        })

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify that lesson system message was added
        system_messages = Enum.filter(chain.messages, &(&1.role == :system))
        assert length(system_messages) >= 1

        # Find the lesson context message
        lesson_message =
          Enum.find(system_messages, fn msg ->
            content = LangChain.Message.ContentPart.content_to_string(msg.content)
            content =~ "<lesson_context>"
          end)

        assert lesson_message != nil

        lesson_content = LangChain.Message.ContentPart.content_to_string(lesson_message.content)
        assert lesson_content =~ "Introduction to Algebra"
        assert lesson_content =~ "Basic algebraic concepts"
        assert lesson_content =~ "Mathematics"
        assert lesson_content =~ "Week 1"
        assert lesson_content =~ "Focus on variables"
        assert lesson_content =~ "Provide extra examples"

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Lesson-aware response")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm, lesson_id: lesson.id)
    end

    test "adds both strand and lesson system messages when both are provided", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      strand = strand_fixture(%{name: "Biology Strand"})
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 2", position: 2})

      {:ok, lesson} =
        Lessons.create_lesson(%{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Cell Biology",
          description: "Introduction to cells"
        })

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        system_messages = Enum.filter(chain.messages, &(&1.role == :system))

        # Should have both strand and lesson context messages
        has_strand_context =
          Enum.any?(system_messages, fn msg ->
            content = LangChain.Message.ContentPart.content_to_string(msg.content)
            content =~ "<strand_context>"
          end)

        has_lesson_context =
          Enum.any?(system_messages, fn msg ->
            content = LangChain.Message.ContentPart.content_to_string(msg.content)
            content =~ "<lesson_context>"
          end)

        assert has_strand_context
        assert has_lesson_context

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Context-aware response")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm,
                 strand_id: strand.id,
                 lesson_id: lesson.id
               )
    end

    test "adds update_lesson tool when enabled_functions includes it", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(%{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Original description"
        })

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify that update_lesson tool was added
        assert length(chain.tools) == 1
        [tool] = chain.tools
        assert tool.name == "update_lesson"

        # Verify tool has the expected parameters
        param_names = Enum.map(tool.parameters, & &1.name)
        assert "description" in param_names
        assert "teacher_notes" in param_names
        assert "differentiation_notes" in param_names

        # Verify lesson_id is in the custom context
        assert chain.custom_context.lesson_id == lesson.id

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("I can update the lesson")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm,
                 lesson_id: lesson.id,
                 enabled_functions: ["update_lesson"]
               )
    end

    test "update_lesson tool successfully updates the lesson", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(%{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Original description",
          teacher_notes: "Original notes"
        })

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Get the update_lesson tool and call it directly
        [tool] = chain.tools

        # Simulate the LLM calling the tool
        args = %{
          "description" => "Updated description from AI",
          "teacher_notes" => "Updated teacher notes"
        }

        result = tool.function.(args, chain.custom_context)

        # Verify the tool returns success
        assert {:ok, "SUCCESS: lesson was updated successfully", updated_lesson} = result
        assert updated_lesson.description == "Updated description from AI"
        assert updated_lesson.teacher_notes == "Updated teacher notes"

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Lesson updated successfully")
          )

        {:ok, response_chain}
      end)

      assert {:ok, _chain} =
               AgentChat.run_llm_chain(scope, messages, llm,
                 lesson_id: lesson.id,
                 enabled_functions: ["update_lesson"]
               )

      # Verify lesson was actually updated in the database
      updated_lesson = Lessons.get_lesson!(lesson.id)
      assert updated_lesson.description == "Updated description from AI"
      assert updated_lesson.teacher_notes == "Updated teacher notes"
    end

    test "does not add update_lesson tool when not in enabled_functions", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      strand = strand_fixture()
      moment = moment_fixture(%{strand_id: strand.id, name: "Week 1", position: 1})

      {:ok, lesson} =
        Lessons.create_lesson(%{
          strand_id: strand.id,
          moment_id: moment.id,
          name: "Test Lesson",
          description: "Some description"
        })

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify no tools were added
        assert chain.tools == []

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Response without tools")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm, lesson_id: lesson.id)
    end

    test "does not add update_lesson tool when lesson_id is missing", %{
      scope: scope,
      messages: messages,
      llm: llm
    } do
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify no tools were added even though enabled_functions includes update_lesson
        assert chain.tools == []

        response_chain =
          LangChain.Chains.LLMChain.add_message(
            chain,
            LangChain.Message.new_assistant!("Response without tools")
          )

        {:ok, response_chain}
      end)

      assert {:ok, %LangChain.Chains.LLMChain{}} =
               AgentChat.run_llm_chain(scope, messages, llm, enabled_functions: ["update_lesson"])
    end

    test "raises when last message is not a user message", %{
      scope: scope,
      llm: llm
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
        AgentChat.run_llm_chain(scope, messages, llm)
      end
    end

    test "returns error when LLM chain fails", %{scope: scope, messages: messages, llm: llm} do
      error = %LangChain.LangChainError{message: "API error"}

      Mimic.expect(LangChain.Chains.LLMChain, :run, fn _chain, _opts ->
        {:error, %LangChain.Chains.LLMChain{messages: []}, error}
      end)

      assert {:error, %LangChain.Chains.LLMChain{}, %LangChain.LangChainError{}} =
               AgentChat.run_llm_chain(scope, messages, llm)
    end
  end
end
