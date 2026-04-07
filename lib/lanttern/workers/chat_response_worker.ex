defmodule Lanttern.ChatResponseWorker do
  @moduledoc """
  Oban worker that processes LLM requests for agent chat conversations.

  This worker handles the complete lifecycle of generating an AI response:

  1. **Message retrieval** - Fetches the conversation with all existing messages
  2. **Options building** - Constructs chain options from job args (e.g., `agent_id`, `lesson_template_id`)
  3. **LLM execution** - Runs the LLM with the configured model and options
  4. **Data persistence** - Saves the assistant's response as a new conversation message
  5. **UI notification** - Broadcasts updates via PubSub so connected LiveViews can update

  Additionally, for new conversations without a name, it triggers an automatic
  rename based on the conversation content.

  ## Job arguments

  Required:
  - `user_id` - The user initiating the chat
  - `conversation_id` - The conversation to continue

  Optional:
  - `model` - Override the LLM (falls back to school config, then application config)
  - `agent_id` - Specific agent configuration to use
  - `lesson_template_id` - Lesson template for lesson-specific chats
  - `strand_id` - Strand context for chats
  - `lesson_id` - Lesson context for chats
  - `enabled_functions` - List of functions the LLM will have access to
  """

  use Oban.Worker, queue: :ai, max_attempts: 3, unique: true

  alias Lanttern.AgentChat
  alias Lanttern.AgentChat.LLMResult
  alias Lanttern.Identity
  alias Lanttern.Identity.Scope
  alias Lanttern.SchoolConfig
  alias Lanttern.SchoolConfig.AiConfig

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "user_id" => user_id,
      "conversation_id" => conversation_id
    } = args

    opts = build_opts(Map.to_list(args))

    scope =
      Identity.get_user!(user_id, preload_current_profile: true)
      |> Scope.for_user()

    model = resolve_model(args, scope)

    conversation = AgentChat.get_conversation(scope, conversation_id)
    messages = AgentChat.list_conversation_messages(scope, conversation)

    with {:ok, %LLMResult{} = result} <- AgentChat.run_llm_chain(scope, messages, model, opts),
         usage_attrs = %{
           prompt_tokens: result.usage.input_tokens,
           completion_tokens: result.usage.output_tokens,
           model: model
         },
         {:ok, %{message: assistant_message}} <-
           AgentChat.add_assistant_message(conversation_id, result.text, usage_attrs) do
      AgentChat.mark_conversation_idle(scope, conversation)

      # notify UIs
      AgentChat.broadcast_conversation(conversation_id, {:message_added, assistant_message})

      # Trigger rename for unnamed conversations
      rename_conversation(scope, conversation, result, model)

      :ok
    else
      error ->
        AgentChat.mark_conversation_idle(scope, conversation, "Failed to get AI response")

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

  defp build_opts(opts, [{"enabled_functions", enabled_functions} | args])
       when is_list(enabled_functions) do
    [{:enabled_functions, enabled_functions} | opts]
    |> build_opts(args)
  end

  defp build_opts(opts, [_ | args]), do: build_opts(opts, args)

  defp resolve_model(args, scope) do
    case {args, SchoolConfig.get_ai_config(scope)} do
      {%{"model" => model}, _} when is_binary(model) and model != "" ->
        model

      {_, %AiConfig{base_model: model}} when is_binary(model) and model != "" ->
        model

      _ ->
        Application.get_env(:lanttern, :default_llm_model, "gpt-5-nano")
    end
  end

  defp rename_conversation(_scope, %{name: name}, _result, _model) when is_binary(name), do: :ok

  defp rename_conversation(scope, conversation, result, model) do
    with {:ok, updated_conversation} <-
           AgentChat.rename_conversation_from_result(scope, conversation, result, model) do
      # notify UIs
      AgentChat.broadcast_conversation(
        conversation.id,
        {:conversation_renamed, updated_conversation}
      )
    end

    # Silently fail - naming is not critical
  end
end
