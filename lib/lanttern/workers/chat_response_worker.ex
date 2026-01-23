defmodule Lanttern.ChatResponseWorker do
  @moduledoc """
  Oban worker that processes LLM chain requests for agent chat conversations.

  This worker handles the complete lifecycle of generating an AI response:

  1. **Message retrieval** - Fetches the conversation with all existing messages
  2. **Options building** - Constructs chain options from job args (e.g., `agent_id`, `lesson_template_id`)
  3. **LLM execution** - Runs the LangChain with the configured model and options
  4. **Data persistence** - Saves the assistant's response as a new conversation message
  5. **UI notification** - Broadcasts updates via PubSub so connected LiveViews can update

  Additionally, for new conversations without a name, it triggers an automatic
  rename based on the conversation content.

  ## Job arguments

  Required:
  - `user_id` - The user initiating the chat
  - `conversation_id` - The conversation to continue
  - `model` - The LLM model identifier (e.g., "gpt-4o")

  Optional:
  - `agent_id` - Specific agent configuration to use
  - `lesson_template_id` - Lesson template for lesson-specific chats
  - `strand_id` - Strand context for chats
  - `lesson_id` - Lesson context for chats
  """

  use Oban.Worker, queue: :ai, max_attempts: 1, unique: true

  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Message.ContentPart

  alias Lanttern.AgentChat
  alias Lanttern.Identity
  alias Lanttern.Identity.Scope

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "user_id" => user_id,
      "conversation_id" => conversation_id,
      "model" => model
    } = args

    llm = ChatOpenAI.new!(%{model: model, stream: false})
    opts = build_opts(Map.to_list(args))

    scope =
      Identity.get_user!(user_id, preload_current_profile: true)
      |> Scope.for_user()

    conversation = AgentChat.get_conversation_with_messages(scope, conversation_id)

    with {:ok, updated_chain} <- AgentChat.run_llm_chain(scope, conversation.messages, llm, opts),
         {content, usage_attrs} <-
           extract_content_and_usage_attrs_from_chain(updated_chain, model),
         {:ok, %{message: assistant_message}} <-
           AgentChat.add_assistant_message(conversation_id, content, usage_attrs) do
      # notify UIs
      AgentChat.broadcast_conversation(conversation_id, {:message_added, assistant_message})

      # Trigger rename for unnamed conversations
      rename_conversation(scope, conversation, updated_chain)

      :ok
    else
      error ->
        # notify UIs
        AgentChat.broadcast_conversation(conversation_id, {:failed, error})
    end
  end

  defp build_opts(opts \\ [], args)

  defp build_opts(opts, []), do: opts

  defp build_opts(opts, [{"agent_id", agent_id} | args]) when is_integer(agent_id) do
    [{:agent_id, agent_id} | opts]
    |> build_opts(args)
  end

  defp build_opts(opts, [{"lesson_template_id", lesson_template_id} | args])
       when is_integer(lesson_template_id) do
    [{:lesson_template_id, lesson_template_id} | opts]
    |> build_opts(args)
  end

  defp build_opts(opts, [{"strand_id", strand_id} | args])
       when is_integer(strand_id) do
    [{:strand_id, strand_id} | opts]
    |> build_opts(args)
  end

  defp build_opts(opts, [{"lesson_id", lesson_id} | args])
       when is_integer(lesson_id) do
    [{:lesson_id, lesson_id} | opts]
    |> build_opts(args)
  end

  defp build_opts(opts, [_ | args]), do: build_opts(opts, args)

  defp extract_content_and_usage_attrs_from_chain(chain, model) do
    # {:ok, updated_chain} = AgentChat.run_llm_chain(scope, conversation.messages, llm, opts)

    # Get the last message (assistant response)
    assistant_message = chain.last_message

    # Extract token usage from metadata
    usage = Map.get(assistant_message.metadata || %{}, :usage, %{})

    usage_attrs = %{
      prompt_tokens: Map.get(usage, :input, 0),
      completion_tokens: Map.get(usage, :output, 0),
      model: model
    }

    content = ContentPart.content_to_string(assistant_message.content)

    {content, usage_attrs}
  end

  defp rename_conversation(_scope, %{name: name}, _chain) when is_binary(name), do: :ok

  defp rename_conversation(scope, conversation, chain) do
    with {:ok, updated_conversation} <-
           AgentChat.rename_conversation_based_on_chain(scope, conversation, chain) do
      # notify UIs
      AgentChat.broadcast_conversation(
        conversation.id,
        {:conversation_renamed, updated_conversation}
      )
    end

    # Silently fail - naming is not critical
  end
end
