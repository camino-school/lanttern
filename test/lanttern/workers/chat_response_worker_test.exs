defmodule Lanttern.ChatResponseWorkerTest do
  use Lanttern.DataCase, async: true
  use Oban.Testing, repo: Lanttern.Repo

  import Ecto.Changeset
  import Lanttern.Factory

  alias Lanttern.AgentChat
  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.ChatResponseWorker
  alias Lanttern.Identity.User
  alias Lanttern.IdentityFixtures
  alias Lanttern.SchoolsFixtures

  describe "perform/1" do
    setup do
      Mimic.copy(LangChain.Chains.LLMChain)

      # Create a properly linked user/profile/school setup
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      user = IdentityFixtures.user_fixture()

      profile =
        IdentityFixtures.staff_member_profile_fixture(%{
          user_id: user.id,
          staff_member_id: staff_member.id
        })

      # Update user's current_profile_id so preload works
      user
      |> User.current_profile_id_changeset(%{current_profile_id: profile.id})
      |> Repo.update!()

      # Create conversation with proper profile and school
      conversation =
        insert(:conversation, %{
          profile: profile,
          school: school,
          name: nil
        })

      insert(:agent_message, %{
        conversation: conversation,
        role: "user",
        content: "What is the capital of France?"
      })

      %{
        user: user,
        profile: profile,
        school: school,
        staff_member: staff_member,
        conversation: conversation
      }
    end

    test "successfully processes LLM response and adds assistant message", %{
      user: user,
      conversation: conversation
    } do
      # Mock LLMChain.run to return a successful response
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "The capital of France is Paris.",
            metadata: %{usage: %{input: 50, output: 100}}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      # Mock the rename chain call (since conversation has no name)
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        [rename_function] = naming_chain.tools

        {:ok, content, updated_conv} =
          rename_function.function.(%{"title" => "Capital of France"}, %{})

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

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify assistant message was created
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assert length(messages) == 2

      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      assert assistant_message.content == "The capital of France is Paris."

      # Verify model call was created
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.prompt_tokens == 50
      assert model_call.completion_tokens == 100
      assert model_call.model == "gpt-4o"

      # Verify conversation was renamed
      updated_conversation = Repo.get!(Conversation, conversation.id)
      assert updated_conversation.name == "Capital of France"
    end

    test "broadcasts message_added event on success", %{
      user: user,
      conversation: conversation
    } do
      # Subscribe to conversation updates
      AgentChat.subscribe_conversation(conversation.id)

      # Mock LLMChain.run
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "Paris is the capital.",
            metadata: %{usage: %{input: 10, output: 20}}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      # Mock the rename chain call
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        [rename_function] = naming_chain.tools

        {:ok, content, updated_conv} =
          rename_function.function.(%{"title" => "Paris Capital"}, %{})

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

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify broadcast was received
      assert_receive {:conversation, {:message_added, %Message{content: "Paris is the capital."}}}

      assert_receive {:conversation,
                      {:conversation_renamed, %Conversation{name: "Paris Capital"}}}
    end

    test "broadcasts failed event when LLM chain fails", %{
      user: user,
      conversation: conversation
    } do
      # Subscribe to conversation updates
      AgentChat.subscribe_conversation(conversation.id)

      error = %LangChain.LangChainError{message: "API error"}

      # Mock LLMChain.run to fail
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        {:error, chain, error}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o"
      }

      # Job returns :ok (broadcasts error via PubSub, doesn't fail the Oban job)
      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify failed broadcast was received
      assert_receive {:conversation, {:failed, {:error, _chain, %LangChain.LangChainError{}}}}

      # Verify no assistant message was created
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assert length(messages) == 1
      assert hd(messages).role == "user"
    end

    test "includes agent_id in chain options when provided", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      agent = insert(:agent, school: school)

      # Expect run to be called with agent system messages
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify agent system messages are included
        system_messages = Enum.filter(chain.messages, &(&1.role == :system))
        assert length(system_messages) >= 4

        contents =
          Enum.map(system_messages, &LangChain.Message.ContentPart.content_to_string(&1.content))

        assert Enum.any?(contents, &(&1 =~ "agent_personality"))
        assert Enum.any?(contents, &(&1 =~ "agent_instructions"))
        assert Enum.any?(contents, &(&1 =~ "agent_knowledge"))
        assert Enum.any?(contents, &(&1 =~ "agent_guardrails"))

        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "Response with agent context.",
            metadata: %{usage: %{input: 100, output: 50}}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      # Mock the rename chain call
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        [rename_function] = naming_chain.tools
        {:ok, content, updated_conv} = rename_function.function.(%{"title" => "Agent Chat"}, %{})

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

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o",
        "agent_id" => agent.id
      }

      assert :ok = perform_job(ChatResponseWorker, args)
    end

    test "includes lesson_template_id in chain options when provided", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      lesson_template = insert(:lesson_template, school: school)

      # Expect run to be called with lesson template system messages
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        # Verify lesson template system messages are included
        system_messages = Enum.filter(chain.messages, &(&1.role == :system))
        assert length(system_messages) >= 2

        contents =
          Enum.map(system_messages, &LangChain.Message.ContentPart.content_to_string(&1.content))

        assert Enum.any?(contents, &(&1 =~ "lesson_template_info"))
        assert Enum.any?(contents, &(&1 =~ "lesson_template"))

        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "Response with lesson context.",
            metadata: %{usage: %{input: 80, output: 40}}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      # Mock the rename chain call
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        [rename_function] = naming_chain.tools
        {:ok, content, updated_conv} = rename_function.function.(%{"title" => "Lesson Chat"}, %{})

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

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o",
        "lesson_template_id" => lesson_template.id
      }

      assert :ok = perform_job(ChatResponseWorker, args)
    end

    test "does not trigger rename for conversations with existing name", %{
      user: user,
      profile: profile,
      school: school
    } do
      # Create conversation with existing name
      conversation_with_name =
        insert(:conversation, %{profile: profile, school: school, name: "Existing Name"})

      insert(:agent_message, %{
        conversation: conversation_with_name,
        role: "user",
        content: "Hello"
      })

      # Only expect one LLMChain.run call (no rename call)
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "Hi there!",
            metadata: %{usage: %{input: 10, output: 5}}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation_with_name.id,
        "model" => "gpt-4o"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify name was not changed
      updated_conversation = Repo.get!(Conversation, conversation_with_name.id)
      assert updated_conversation.name == "Existing Name"
    end

    test "handles missing usage metadata gracefully", %{
      user: user,
      conversation: conversation
    } do
      # Mock LLMChain.run with missing usage metadata
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn chain, _opts ->
        assistant_message =
          LangChain.Message.new_assistant!(%{
            content: "Response without usage data.",
            metadata: %{}
          })

        {:ok,
         %{
           chain
           | last_message: assistant_message,
             messages: chain.messages ++ [assistant_message]
         }}
      end)

      # Mock the rename chain call
      Mimic.expect(LangChain.Chains.LLMChain, :run, fn naming_chain, _opts ->
        [rename_function] = naming_chain.tools
        {:ok, content, updated_conv} = rename_function.function.(%{"title" => "No Usage"}, %{})

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

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify model call was created with 0 tokens
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.prompt_tokens == 0
      assert model_call.completion_tokens == 0
    end
  end

  describe "integration with Oban" do
    setup do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      user = IdentityFixtures.user_fixture()

      profile =
        IdentityFixtures.staff_member_profile_fixture(%{
          user_id: user.id,
          staff_member_id: staff_member.id
        })

      user
      |> User.current_profile_id_changeset(%{current_profile_id: profile.id})
      |> Repo.update!()

      conversation = insert(:conversation, %{profile: profile, school: school})

      insert(:agent_message, %{
        conversation: conversation,
        role: "user",
        content: "Test message"
      })

      %{user: user, conversation: conversation}
    end

    test "job is properly configured" do
      job =
        ChatResponseWorker.new(%{
          user_id: 1,
          conversation_id: 1,
          model: "gpt-4o"
        })

      assert get_change(job, :worker) == "Lanttern.ChatResponseWorker"
      assert get_change(job, :queue) == "ai"
      assert get_change(job, :max_attempts) == 1
    end

    test "job can be enqueued", %{user: user, conversation: conversation} do
      args = %{
        user_id: user.id,
        conversation_id: conversation.id,
        model: "gpt-4o"
      }

      assert {:ok, _job} = ChatResponseWorker.new(args) |> Oban.insert()

      assert_enqueued(worker: ChatResponseWorker, queue: "ai")
    end

    test "job has unique constraint" do
      # The worker uses unique: true, so duplicate jobs should be prevented
      job = ChatResponseWorker.new(%{user_id: 1, conversation_id: 1, model: "gpt-4o"})
      assert get_change(job, :unique) != nil
    end
  end
end
