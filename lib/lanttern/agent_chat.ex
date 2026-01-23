defmodule Lanttern.AgentChat do
  @moduledoc """
  The AgentChat context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Lanttern.Repo

  alias LangChain.Chains.LLMChain
  alias LangChain.Message.ContentPart

  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.AgentChat.StrandConversation
  alias Lanttern.Agents
  alias Lanttern.Identity.Scope
  alias Lanttern.LessonTemplates

  @doc """
  Subscribes to scoped notifications about chain responses in conversations.

  The broadcasted messages match the pattern:

    * {:conversation, {:failed, error}}
    * {:conversation, {:message_added, %Message{}}}
    * {:conversation, {:conversation_renamed, %Conversation{}}}

  """
  def subscribe_conversation(conversation_id) do
    Phoenix.PubSub.subscribe(Lanttern.PubSub, "conversation:#{conversation_id}")
  end

  def broadcast_conversation(conversation_id, message) do
    Phoenix.PubSub.broadcast(
      Lanttern.PubSub,
      "conversation:#{conversation_id}",
      {:conversation, message}
    )
  end

  @doc """
  Returns the list of conversations for the given scope profile.

  ## Options

    * `:strand_id` - Filters conversations linked to the given strand
    * `:lesson_id` - Filters conversations linked to the given lesson (requires a strand link)

  ## Examples

      iex> list_conversations(scope)
      [%Conversation{}, ...]

      iex> list_conversations(scope, strand_id: 1)
      [%Conversation{}, ...]

      iex> list_conversations(scope, strand_id: 1, lesson_id: 2)
      [%Conversation{}, ...]

  """
  def list_conversations(%Scope{} = scope, opts \\ []) do
    from(
      c in Conversation,
      where: c.profile_id == ^scope.profile_id,
      order_by: [desc: :updated_at]
    )
    |> apply_list_conversations_opts(opts)
    |> Repo.all()
  end

  defp apply_list_conversations_opts(queryable, []),
    do: queryable

  defp apply_list_conversations_opts(queryable, [{:strand_id, strand_id} | opts]) do
    queryable
    |> maybe_join_strand_conversation()
    |> where([_c, strand_conversation: sc], sc.strand_id == ^strand_id)
    |> apply_list_conversations_opts(opts)
  end

  defp apply_list_conversations_opts(queryable, [{:lesson_id, lesson_id} | opts]) do
    queryable
    |> maybe_join_strand_conversation()
    |> where([_c, strand_conversation: sc], sc.lesson_id == ^lesson_id)
    |> apply_list_conversations_opts(opts)
  end

  defp apply_list_conversations_opts(queryable, [_ | opts]),
    do: apply_list_conversations_opts(queryable, opts)

  defp maybe_join_strand_conversation(queryable) do
    if has_named_binding?(queryable, :strand_conversation) do
      queryable
    else
      join(
        queryable,
        :inner,
        [c],
        sc in assoc(c, :strand_conversation),
        as: :strand_conversation
      )
    end
  end

  @doc """
  Gets a single conversation with preloaded messages.

  Returns `nil` if the Conversation does not exist.

  ## Examples

      iex> get_conversation_with_messages(scope, 123)
      %Conversation{messages: [%Message{}, ...]}

  """
  def get_conversation_with_messages(%Scope{} = scope, id) do
    from(
      c in Conversation,
      where: c.id == ^id and c.profile_id == ^scope.profile_id,
      join: m in assoc(c, :messages),
      order_by: m.inserted_at,
      preload: [messages: m]
    )
    |> Repo.one()
  end

  @doc """
  Creates a model call record for tracking token usage.

  ## Examples

      iex> create_model_call(%{prompt_tokens: 10, completion_tokens: 20}, message_id)
      {:ok, %ModelCall{}}

  """
  def create_model_call(attrs, message_id) do
    attrs = Map.put(attrs, :message_id, message_id)

    %ModelCall{}
    |> ModelCall.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a new conversation with an initial user message.

  Returns the conversation and message in a multi result.

  ## Options

    * `:strand_id` - Links the conversation to a strand
    * `:lesson_id` - Links the conversation to a specific lesson (requires `:strand_id`)

  ## Examples

      iex> create_conversation_with_message(scope, "Hello")
      {:ok, %{conversation: %Conversation{}, user_message: %Message{}}}

      iex> create_conversation_with_message(scope, "Hello", strand_id: 1, lesson_id: 2)
      {:ok, %{conversation: %Conversation{}, user_message: %Message{}, strand_conversation: %StrandConversation{}}}

  """
  def create_conversation_with_message(%Scope{} = scope, content, opts \\ []) do
    Multi.new()
    |> Multi.insert(:conversation, Conversation.changeset(%Conversation{}, %{}, scope))
    |> Multi.insert(:user_message, fn %{conversation: conversation} ->
      Message.changeset(%Message{}, %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      })
    end)
    |> maybe_insert_strand_conversation(opts)
    |> Repo.transaction()
  end

  defp maybe_insert_strand_conversation(multi, opts) do
    case Keyword.get(opts, :strand_id) do
      nil ->
        multi

      strand_id ->
        Multi.insert(multi, :strand_conversation, fn %{conversation: conversation} ->
          StrandConversation.changeset(%StrandConversation{}, %{
            conversation_id: conversation.id,
            strand_id: strand_id,
            lesson_id: Keyword.get(opts, :lesson_id)
          })
        end)
    end
  end

  @doc """
  Renames a conversation.

  ## Examples

      iex> rename_conversation(scope, conversation, "New name")
      {:ok, %Conversation{}}

  """
  def rename_conversation(%Scope{} = scope, %Conversation{} = conversation, name)
      when is_binary(name) and name != "" do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    conversation
    |> Conversation.changeset(%{name: name}, scope)
    |> Repo.update()
  end

  @doc """
  Renames an existing conversation based on chain messages.

  The AI agent will use this function to name unnamed conversations
  based on the initial user messages and model responses (first 4 messages max).

  Uses LLM function calling to ensure consistent, structured output.

  ## Examples

      iex> rename_conversation_based_on_chain(scope, conversation, chain)
      {:ok, %Conversation{}}

  """
  def rename_conversation_based_on_chain(
        %Scope{} = scope,
        %Conversation{name: nil} = conversation,
        chain
      ) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    # Extract context from chain messages (user message + assistant response)
    context =
      chain.messages
      |> Enum.filter(&(&1.role in [:user, :assistant]))
      |> Enum.take(4)
      |> Enum.map_join("\n", fn msg ->
        "#{msg.role}: #{ContentPart.content_to_string(msg.content)}"
      end)

    rename_function = build_rename_function(scope, conversation)

    naming_prompt = """
    Based on the following conversation excerpt, generate a concise title (max 50 characters) that captures the main topic or intent. Use the set_conversation_title function to set the title.

    #{context}
    """

    naming_chain =
      LLMChain.new!(%{llm: chain.llm})
      |> LLMChain.add_tools([rename_function])
      |> LLMChain.add_message(LangChain.Message.new_user!(naming_prompt))

    case LLMChain.run(naming_chain, mode: :while_needs_response) do
      {:ok, updated_chain} ->
        # The function was executed - find the tool result to get the conversation
        tool_result =
          updated_chain.messages
          |> Enum.find(&(&1.role == :tool))

        case tool_result do
          %{tool_results: [%{processed_content: %Conversation{} = updated_conversation}]} ->
            {:ok, updated_conversation}

          _ ->
            # Fallback: reload conversation from DB
            {:ok, Repo.get!(Conversation, conversation.id)}
        end

      {:error, _chain, error} ->
        {:error, error}
    end
  end

  defp build_rename_function(scope, conversation) do
    LangChain.Function.new!(%{
      name: "set_conversation_title",
      description:
        "Sets the title for this conversation. The title should be concise (max 50 characters) and capture the main topic.",
      parameters: [
        LangChain.FunctionParam.new!(%{
          name: "title",
          type: :string,
          description: "The conversation title (max 50 characters)",
          required: true
        })
      ],
      function: fn %{"title" => title}, _context ->
        title = String.slice(title, 0, 50)

        case rename_conversation(scope, conversation, title) do
          {:ok, updated_conversation} ->
            {:ok, "Title set to: #{title}", updated_conversation}

          {:error, changeset} ->
            {:error, "Failed to set title: #{inspect(changeset.errors)}"}
        end
      end
    })
  end

  @doc """
  Adds a user message to an existing conversation.

  ## Examples

      iex> add_user_message(scope, conversation, "Hello")
      {:ok, %Message{}}

  """
  def add_user_message(%Scope{} = scope, %Conversation{} = conversation, content) do
    true = Scope.matches_profile?(scope, conversation.profile_id)

    attrs =
      %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      }

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Executes an LLM chain with the given conversation messages.

  Converts a list of `Message` structs into LangChain message format and runs
  them through the provided LLM model.

  When adding system messages, this function prepends them to the chain
  following always the same order to benefit from prompt caching.

  ## Options

    * `:agent_id` - Adds agent info as system messages
    * `:lesson_template_id` - Adds template info as system messages

  ## Examples

      iex> run_llm_chain(scope, messages, llm)
      {:ok, %LLMChain{}}
  """
  @spec run_llm_chain(Scope.t(), [Message.t()], any(), Keyword.t()) ::
          {:ok, LLMChain.t()} | {:error, LLMChain.t(), LangChain.LangChainError.t()}
  def run_llm_chain(%Scope{} = scope, messages, llm, opts \\ []) do
    # check if last message is a user message (prevent LLM from running improperly)
    %{role: "user"} = messages |> Enum.at(-1)

    system_messages =
      add_agent_system_messages(
        scope,
        Keyword.get(opts, :agent_id)
      )
      |> add_lesson_template_system_messages(
        scope,
        Keyword.get(opts, :lesson_template_id)
      )

    # Build LangChain messages from conversation messages
    langchain_messages =
      Enum.map(messages, fn msg ->
        case msg.role do
          "user" -> LangChain.Message.new_user!(msg.content)
          "assistant" -> LangChain.Message.new_assistant!(msg.content)
          "system" -> LangChain.Message.new_system!(msg.content)
        end
      end)

    LLMChain.new!(%{llm: llm})
    |> LLMChain.add_messages(system_messages)
    |> LLMChain.add_messages(langchain_messages)
    |> LLMChain.run()
  end

  defp add_agent_system_messages(system_messages \\ [], scope, agent_id)

  defp add_agent_system_messages(system_messages, scope, agent_id) when is_integer(agent_id) do
    agent = Agents.get_agent!(scope, agent_id)

    system_messages ++
      [
        LangChain.Message.new_system!(
          "<agent_personality>#{agent.personality}</agent_personality>"
        ),
        LangChain.Message.new_system!(
          "<agent_instructions>#{agent.instructions}</agent_instructions>"
        ),
        LangChain.Message.new_system!("<agent_knowledge>#{agent.knowledge}</agent_knowledge>"),
        LangChain.Message.new_system!("<agent_guardrails>#{agent.guardrails}</agent_guardrails>")
      ]
  end

  defp add_agent_system_messages(system_messages, _scope, _agent_id), do: system_messages

  defp add_lesson_template_system_messages(system_messages, scope, lesson_template_id)
       when is_integer(lesson_template_id) do
    template = LessonTemplates.get_lesson_template!(scope, lesson_template_id)

    system_messages ++
      [
        LangChain.Message.new_system!(
          "<lesson_template_info>#{template.about}</lesson_template_info>"
        ),
        LangChain.Message.new_system!("<lesson_template>#{template.template}</lesson_template>")
      ]
  end

  defp add_lesson_template_system_messages(system_messages, _scope, _lesson_template_id),
    do: system_messages

  @doc """
  Adds an assistant message to a conversation with model call tracking.

  ## Examples

      iex> add_assistant_message(conversation_id, "Hello!", %{prompt_tokens: 10, completion_tokens: 20, model: "gpt-5-nano"})
      {:ok, %{message: %Message{}, model_call: %ModelCall{}}}

  """
  def add_assistant_message(conversation_id, content, usage_attrs) do
    Multi.new()
    |> Multi.insert(
      :message,
      Message.changeset(%Message{}, %{
        role: "assistant",
        content: content,
        conversation_id: conversation_id
      })
    )
    |> Multi.insert(:model_call, fn %{message: message} ->
      ModelCall.changeset(%ModelCall{}, Map.put(usage_attrs, :message_id, message.id))
    end)
    |> Multi.update(
      :touch_conversation,
      fn %{message: message} ->
        conversation = Repo.get!(Conversation, message.conversation_id)
        Ecto.Changeset.change(conversation, %{})
      end,
      # force true to update updated_at timestamp
      force: true
    )
    |> Repo.transaction()
  end
end
