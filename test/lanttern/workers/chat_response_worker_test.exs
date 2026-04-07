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
      Mimic.copy(ReqLLM)

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
      # Mock the main LLM call
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        assistant_msg = ReqLLM.Context.assistant("The capital of France is Paris.")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 50, output_tokens: 100}
         }}
      end)

      # Mock the rename call (since conversation has no name)
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok,
         %ReqLLM.Response{
           id: "rename-test",
           model: "gpt-4o",
           context: ReqLLM.Context.new([]),
           message: ReqLLM.Context.assistant(""),
           object: %{"title" => "Capital of France"}
         }}
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

      # Mock the main LLM call
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        assistant_msg = ReqLLM.Context.assistant("Paris is the capital.")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      # Mock the rename call
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok,
         %ReqLLM.Response{
           id: "rename-test",
           model: "gpt-4o",
           context: ReqLLM.Context.new([]),
           message: ReqLLM.Context.assistant(""),
           object: %{"title" => "Paris Capital"}
         }}
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

      # Mock generate_text to fail
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, _opts ->
        {:error, "API error"}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-4o"
      }

      # Job returns :ok (broadcasts error via PubSub, doesn't fail the Oban job)
      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify failed broadcast was received
      assert_receive {:conversation, {:failed, {:error, "API error"}}}

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

      # Expect generate_text to be called with agent system messages in context
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Verify agent system messages are included in the single system message
        messages = ReqLLM.Context.to_list(context)
        system_msg = Enum.find(messages, &(&1.role == :system))
        assert system_msg != nil

        system_text =
          system_msg.content
          |> Enum.filter(&(&1.type == :text))
          |> Enum.map_join("", & &1.text)

        assert system_text =~ "agent_personality"
        assert system_text =~ "agent_instructions"
        assert system_text =~ "agent_knowledge"
        assert system_text =~ "agent_guardrails"

        assistant_msg = ReqLLM.Context.assistant("Response with agent context.")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 100, output_tokens: 50}
         }}
      end)

      # Mock the rename call
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok,
         %ReqLLM.Response{
           id: "rename-test",
           model: "gpt-4o",
           context: ReqLLM.Context.new([]),
           message: ReqLLM.Context.assistant(""),
           object: %{"title" => "Agent Chat"}
         }}
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

      # Expect generate_text to be called with lesson template system messages in context
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Verify lesson template system messages are included in the single system message
        messages = ReqLLM.Context.to_list(context)
        system_msg = Enum.find(messages, &(&1.role == :system))
        assert system_msg != nil

        system_text =
          system_msg.content
          |> Enum.filter(&(&1.type == :text))
          |> Enum.map_join("", & &1.text)

        assert system_text =~ "lesson_template_info"
        assert system_text =~ "lesson_template"

        assistant_msg = ReqLLM.Context.assistant("Response with lesson context.")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 80, output_tokens: 40}
         }}
      end)

      # Mock the rename call
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok,
         %ReqLLM.Response{
           id: "rename-test",
           model: "gpt-4o",
           context: ReqLLM.Context.new([]),
           message: ReqLLM.Context.assistant(""),
           object: %{"title" => "Lesson Chat"}
         }}
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

      # Only expect one generate_text call (no generate_object for rename)
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        assistant_msg = ReqLLM.Context.assistant("Hi there!")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 5}
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
      # Mock generate_text with nil usage
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        assistant_msg = ReqLLM.Context.assistant("Response without usage data.")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: nil
         }}
      end)

      # Mock the rename call
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema ->
        {:ok,
         %ReqLLM.Response{
           id: "rename-test",
           model: "gpt-4o",
           context: ReqLLM.Context.new([]),
           message: ReqLLM.Context.assistant(""),
           object: %{"title" => "No Usage"}
         }}
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

  describe "model resolution" do
    setup do
      Mimic.copy(ReqLLM)

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

      conversation =
        insert(:conversation, %{
          profile: profile,
          school: school,
          name: "Test Conversation"
        })

      insert(:agent_message, %{
        conversation: conversation,
        role: "user",
        content: "Test message"
      })

      %{
        user: user,
        profile: profile,
        school: school,
        conversation: conversation
      }
    end

    test "uses model from args when provided", %{
      user: user,
      conversation: conversation
    } do
      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Verify the model used is from args
        assert model == "gpt-5-turbo"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "gpt-5-turbo"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify the model was recorded correctly
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "gpt-5-turbo"
    end

    test "uses school ai_config base_model when model not in args", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      # Create ai_config with base_model for the school
      insert(:ai_config, school: school, base_model: "school-preferred-model")

      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Verify the model used is from school ai_config
        assert model == "school-preferred-model"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      # No model in args
      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify the school model was recorded
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "school-preferred-model"
    end

    test "uses app config default when no model in args and no school ai_config", %{
      user: user,
      conversation: conversation
    } do
      # No ai_config for the school, no model in args
      # Should fall back to app config default (gpt-5-nano)

      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Verify the model used is the default
        assert model == "gpt-5-nano"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      # Verify the default model was recorded
      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "gpt-5-nano"
    end

    test "model in args takes precedence over school ai_config", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      # Create ai_config with base_model for the school
      insert(:ai_config, school: school, base_model: "school-model")

      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Should use the model from args, not from school config
        assert model == "args-model"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => "args-model"
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "args-model"
    end

    test "ignores empty string model in args and falls back to school config", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      insert(:ai_config, school: school, base_model: "school-fallback-model")

      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Empty string model should be ignored, use school config
        assert model == "school-fallback-model"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id,
        "model" => ""
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "school-fallback-model"
    end

    test "ignores empty string base_model in ai_config and falls back to app default", %{
      user: user,
      school: school,
      conversation: conversation
    } do
      insert(:ai_config, school: school, base_model: "")

      Mimic.expect(ReqLLM, :generate_text, fn model, context, _opts ->
        # Empty base_model should be ignored, use app default
        assert model == "gpt-5-nano"

        assistant_msg = ReqLLM.Context.assistant("Response")

        {:ok,
         %ReqLLM.Response{
           id: "test-#{System.unique_integer([:positive])}",
           model: model,
           context: ReqLLM.Context.append(context, assistant_msg),
           message: assistant_msg,
           usage: %{input_tokens: 10, output_tokens: 20}
         }}
      end)

      args = %{
        "user_id" => user.id,
        "conversation_id" => conversation.id
      }

      assert :ok = perform_job(ChatResponseWorker, args)

      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assistant_message = Enum.find(messages, &(&1.role == "assistant"))
      model_call = Repo.get_by(ModelCall, message_id: assistant_message.id)
      assert model_call.model == "gpt-5-nano"
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
      assert get_change(job, :max_attempts) == 3
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
