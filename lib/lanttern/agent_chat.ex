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
