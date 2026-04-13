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

  All functions accept an optional trailing `opts` keyword list
  (e.g., `generate_text("gpt-4o", messages, timeout: 30_000)`).
  """

  alias Lanttern.LLM.Response
  alias Lanttern.LLM.Tool

  @callback generate_text(String.t(), [map()], keyword()) ::
              {:ok, Response.t()} | {:error, term()}
  @callback generate_text_with_tools(String.t(), [map()], [Tool.t()], keyword()) ::
              {:ok, Response.t()} | {:error, term()}
  @callback generate_object(String.t(), String.t(), keyword(), keyword()) ::
              {:ok, Response.t()} | {:error, term()}

  @max_tool_iterations 10

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

    case ReqLLM.generate_text(model, context, opts) do
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
  until the LLM returns a final answer or max iterations (#{@max_tool_iterations}) is reached.
  """
  def generate_text_with_tools(model, messages, tools, opts \\ []) do
    model = normalize_model(model)
    context = to_req_llm_context(messages)
    req_tools = Enum.map(tools, &to_req_llm_tool/1)

    run_tool_loop(model, context, req_tools, opts)
  end

  # --- Structured output ---

  @doc """
  Generates a structured object from an LLM using schema validation.

  Used for cases like conversation renaming where a specific data shape is needed.
  """
  def generate_object(model, prompt, schema, opts \\ []) do
    model = normalize_model(model)

    case ReqLLM.generate_object(model, prompt, schema, opts) do
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
         usage_acc \\ %{input_tokens: 0, output_tokens: 0},
         iteration \\ 0
       )

  defp run_tool_loop(_, _, _, _, _, iteration)
       when iteration >= @max_tool_iterations do
    {:error, :max_tool_iterations_exceeded}
  end

  defp run_tool_loop(model, context, tools, opts, usage_acc, iteration) do
    tool_opts = if tools == [], do: opts, else: Keyword.put(opts, :tools, tools)

    case ReqLLM.generate_text(model, context, tool_opts) do
      {:ok, response} ->
        usage = merge_usage(usage_acc, ReqLLM.Response.usage(response))

        case ReqLLM.Response.classify(response) do
          %{type: :tool_calls, tool_calls: tool_calls} ->
            updated_context =
              ReqLLM.Context.execute_and_append_tools(response.context, tool_calls, tools)

            run_tool_loop(model, updated_context, tools, opts, usage, iteration + 1)

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
