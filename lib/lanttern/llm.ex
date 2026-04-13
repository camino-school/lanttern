defmodule Lanttern.LLM do
  @moduledoc """
  LLM client abstraction layer.

  Wraps the underlying LLM library (currently ReqLLM) so that business logic
  and tests never depend on library-specific types. If the library changes,
  only this module needs to be updated.

  ## Message format

  Messages are plain maps with `:role` and `:content` keys:

      [
        %{role: :system, content: "You are helpful"},
        %{role: :user, content: "Hello"}
      ]

  ## Usage

      # Simple text generation (ILP)
      {:ok, response} = Lanttern.LLM.generate_text("gpt-4o", messages)
      response.text

      # With tool calling loop (Agent Chat)
      {:ok, response} = Lanttern.LLM.generate_text_with_tools("gpt-4o", messages, tools)
      response.text
      response.messages  # conversation history (read-only, not round-trippable)

      # Structured output
      {:ok, response} = Lanttern.LLM.generate_object("gpt-4o", prompt, schema)
      response.object

  ## Options

  All public functions accept an optional trailing `opts` keyword list.
  Supported keys in addition to whatever the underlying library accepts:

    * `:receive_timeout` - HTTP read timeout in ms (default `#{5 * 60 * 1000}` =
      5 min). Matches the prior LangChain behavior for tool-heavy or long
      ILP revisions; ReqLLM's default would otherwise be as low as 30s.
    * `:max_tool_iterations` - cap on tool-call rounds in
      `generate_text_with_tools/4` (default `10`). Returns
      `{:error, :max_tool_iterations_exceeded}` when reached.

  ## Tool-result persistence (Agent Chat)

  `messages` on the returned response is a flat list of user/assistant/system
  text turns. Tool calls and tool results are NOT included — they live only
  inside the library's internal context during a single wrapper invocation.
  Conversations retrieved from the `agent_messages` table therefore will not
  contain tool-call history from previous runs; the model only ever sees the
  user/assistant transcript when a job resumes a conversation.
  """

  require Logger

  alias Lanttern.LLM.Response
  alias Lanttern.LLM.Tool

  @callback generate_text(String.t(), [map()], keyword()) ::
              {:ok, Response.t()} | {:error, term()}
  @callback generate_text_with_tools(String.t(), [map()], [Tool.t()], keyword()) ::
              {:ok, Response.t()} | {:error, term()}
  @callback generate_object(String.t(), String.t(), keyword(), keyword()) ::
              {:ok, Response.t()} | {:error, term()}

  @default_max_tool_iterations 10
  @default_receive_timeout_ms 5 * 60 * 1000

  # Keys that this wrapper consumes itself and must not be forwarded to ReqLLM
  # (which validates opts via NimbleOptions and would reject unknown keys).
  @wrapper_only_opts [:max_tool_iterations]

  # --- Message builders (plain maps) ---

  def system_message(content) when is_binary(content), do: %{role: :system, content: content}
  def user_message(content) when is_binary(content), do: %{role: :user, content: content}

  def assistant_message(content) when is_binary(content),
    do: %{role: :assistant, content: content}

  # --- Tool builder ---

  def tool(name, description, parameter_schema, callback) do
    %Tool{
      name: name,
      description: description,
      parameter_schema: parameter_schema,
      callback: callback
    }
  end

  # --- Simple text generation ---

  @doc """
  Generates text from an LLM without tool calling.

  Used by ILP revision and other simple single-shot calls.
  """
  def generate_text(model, messages, opts \\ []) do
    model = normalize_model(model)
    context = to_req_llm_context(messages)
    req_opts = opts |> put_default_timeout() |> forwardable_opts()

    case ReqLLM.generate_text(model, context, req_opts) do
      {:ok, response} ->
        {:ok,
         %Response{
           text: ReqLLM.Response.text(response),
           usage: normalize_usage(ReqLLM.Response.usage(response)),
           messages: to_plain_messages(response.context)
         }}

      {:error, _} = error ->
        error
    end
  end

  # --- Text generation with tool calling loop ---

  @doc """
  Generates text with automatic tool calling loop.

  When the LLM requests tool calls, executes them and re-sends the results
  until the LLM returns a final answer or `:max_tool_iterations` is reached
  (default `#{@default_max_tool_iterations}`).

  Returns `{:error, :max_tool_iterations_exceeded}` if the loop runs past
  the cap — in that case the partial conversation is discarded. Tune
  `opts[:max_tool_iterations]` for agents with legitimately long tool chains.
  """
  def generate_text_with_tools(model, messages, tools, opts \\ []) do
    model = normalize_model(model)
    context = to_req_llm_context(messages)
    req_tools = Enum.map(tools, &to_req_llm_tool/1)
    max_iterations = Keyword.get(opts, :max_tool_iterations, @default_max_tool_iterations)
    req_opts = opts |> put_default_timeout() |> forwardable_opts()

    run_tool_loop(model, context, req_tools, req_opts, max_iterations)
  end

  # --- Structured output ---

  @doc """
  Generates a structured object from an LLM using schema validation.

  Used for cases like conversation renaming where a specific data shape is needed.
  """
  def generate_object(model, prompt, schema, opts \\ []) do
    model = normalize_model(model)
    req_opts = opts |> put_default_timeout() |> forwardable_opts()

    case ReqLLM.generate_object(model, prompt, schema, req_opts) do
      {:ok, response} ->
        {:ok,
         %Response{
           object: ReqLLM.Response.object(response),
           usage: normalize_usage(ReqLLM.Response.usage(response))
         }}

      {:error, _} = error ->
        error
    end
  end

  # --- Private: tool call loop ---

  defp run_tool_loop(
         model,
         context,
         tools,
         opts,
         max_iterations,
         usage_acc \\ %{input_tokens: 0, output_tokens: 0},
         iteration \\ 0
       )

  defp run_tool_loop(_, _, _, _, max_iterations, _, iteration)
       when iteration >= max_iterations do
    Logger.warning(
      "LLM tool loop hit max_tool_iterations=#{max_iterations}; aborting with :max_tool_iterations_exceeded"
    )

    {:error, :max_tool_iterations_exceeded}
  end

  defp run_tool_loop(model, context, tools, opts, max_iterations, usage_acc, iteration) do
    tool_opts = if tools == [], do: opts, else: Keyword.put(opts, :tools, tools)

    case ReqLLM.generate_text(model, context, tool_opts) do
      {:ok, response} ->
        usage = merge_usage(usage_acc, ReqLLM.Response.usage(response))

        case ReqLLM.Response.classify(response) do
          %{type: :tool_calls, tool_calls: tool_calls} ->
            updated_context =
              ReqLLM.Context.execute_and_append_tools(response.context, tool_calls, tools)

            run_tool_loop(
              model,
              updated_context,
              tools,
              opts,
              max_iterations,
              usage,
              iteration + 1
            )

          %{type: :final_answer} ->
            {:ok,
             %Response{
               text: ReqLLM.Response.text(response) || "",
               usage: usage,
               messages: to_plain_messages(response.context)
             }}
        end

      {:error, _} = error ->
        error
    end
  end

  # --- Private: opt normalization ---

  defp put_default_timeout(opts),
    do: Keyword.put_new(opts, :receive_timeout, @default_receive_timeout_ms)

  defp forwardable_opts(opts), do: Keyword.drop(opts, @wrapper_only_opts)

  # --- Private: model normalization ---

  # ReqLLM/LLMDB requires "provider:model" format (e.g., "openai:gpt-4o").
  # Existing data may have bare model names from the LangChain era (e.g., "gpt-4o").
  # This function adds the default provider prefix when no separator is present.
  defp normalize_model(model) when is_binary(model) do
    if String.contains?(model, ":") or String.contains?(model, "@") do
      model
    else
      default_provider = Application.get_env(:lanttern, :default_llm_provider, "openai")
      "#{default_provider}:#{model}"
    end
  end

  # --- Private: conversions ---

  defp to_req_llm_context(messages) do
    req_messages =
      Enum.map(messages, fn
        %{role: :system, content: c} -> ReqLLM.Context.system(c)
        %{role: :user, content: c} -> ReqLLM.Context.user(c)
        %{role: :assistant, content: c} -> ReqLLM.Context.assistant(c)
      end)

    ReqLLM.Context.new(req_messages)
  end

  defp to_req_llm_tool(%Tool{} = tool) do
    ReqLLM.Tool.new!(
      name: tool.name,
      description: tool.description,
      parameter_schema: tool.parameter_schema,
      callback: tool.callback
    )
  end

  defp to_plain_messages(context) do
    context
    |> ReqLLM.Context.to_list()
    |> Enum.map(fn msg ->
      text =
        msg.content
        |> Enum.filter(&(&1.type == :text))
        |> Enum.map_join("", & &1.text)

      %{role: msg.role, content: text}
    end)
  end

  defp normalize_usage(nil), do: %{input_tokens: 0, output_tokens: 0}

  defp normalize_usage(usage) do
    %{
      input_tokens: Map.get(usage, :input_tokens, 0),
      output_tokens: Map.get(usage, :output_tokens, 0)
    }
  end

  defp merge_usage(acc, nil), do: acc

  defp merge_usage(acc, new) do
    %{
      input_tokens: acc.input_tokens + Map.get(new, :input_tokens, 0),
      output_tokens: acc.output_tokens + Map.get(new, :output_tokens, 0)
    }
  end
end
