defmodule Lanttern.AgentChat do
  @moduledoc """
  The AgentChat context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Lanttern.Repo

  alias LangChain.Chains.LLMChain

  alias Lanttern.AgentChat.Conversation
  alias Lanttern.AgentChat.Message
  alias Lanttern.AgentChat.ModelCall
  alias Lanttern.Identity.Scope

  @doc """
  Returns the list of conversations for the given scope profile.

  ## Examples

      iex> list_conversations(scope)
      [%Conversation{}, ...]

  """
  def list_conversations(%Scope{} = scope) do
    from(
      c in Conversation,
      where: c.profile_id == ^scope.profile_id,
      order_by: [desc: :updated_at]
    )
    |> Repo.all()
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

  ## Examples

      iex> create_conversation_with_message(scope, "Hello")
      {:ok, %{conversation: %Conversation{}, user_message: %Message{}}}

  """
  def create_conversation_with_message(%Scope{} = scope, content) do
    Multi.new()
    |> Multi.insert(:conversation, Conversation.changeset(%Conversation{}, %{}, scope))
    |> Multi.insert(:user_message, fn %{conversation: conversation} ->
      Message.changeset(%Message{}, %{
        role: "user",
        content: content,
        conversation_id: conversation.id
      })
    end)
    |> Repo.transaction()
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
      |> Enum.map_join("\n", fn msg -> "#{msg.role}: #{extract_text_content(msg.content)}" end)

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

  # Extract text content from LangChain message content (handles ContentPart lists)
  defp extract_text_content(content) when is_list(content) do
    content
    |> Enum.filter(&(&1.type == :text))
    |> Enum.map_join("\n", & &1.content)
  end

  defp extract_text_content(content) when is_binary(content), do: content
  defp extract_text_content(_), do: ""

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

  @spec run_llm_chain([Message.t()], any()) ::
          {:ok, LLMChain.t()} | {:error, LLMChain.t(), LangChain.LangChainError.t()}
  def run_llm_chain(messages, llm) do
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
    |> LLMChain.add_messages(langchain_messages)
    |> LLMChain.run()
  end

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
