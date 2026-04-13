defmodule Lanttern.LLMTest do
  @moduledoc """
  Unit tests for the `Lanttern.LLM` wrapper that exercise the parts of the
  module which are otherwise only covered through real ReqLLM calls.

  Tests mock `ReqLLM` at the boundary (entry point + response helpers) so
  that the custom tool loop and opts forwarding can be validated in
  isolation, without hitting a live provider.
  """

  use ExUnit.Case, async: true
  use Mimic

  alias Lanttern.LLM
  alias Lanttern.LLM.Response

  setup :set_mimic_from_context

  setup do
    Mimic.copy(ReqLLM)
    Mimic.copy(ReqLLM.Response)
    Mimic.copy(ReqLLM.Context)
    :ok
  end

  describe "generate_text/3 opt forwarding" do
    test "sets :receive_timeout to 5 minutes by default" do
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, opts ->
        assert Keyword.get(opts, :receive_timeout) == 5 * 60 * 1000
        {:ok, fake_final_response("ok")}
      end)

      Mimic.stub(ReqLLM.Response, :text, fn _ -> "ok" end)
      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{input_tokens: 1, output_tokens: 2} end)
      Mimic.stub(ReqLLM.Context, :to_list, fn _ -> [] end)

      assert {:ok, %Response{text: "ok"}} =
               LLM.generate_text("openai:gpt-4o", [%{role: :user, content: "hi"}])
    end

    test "honors a caller-supplied :receive_timeout" do
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, opts ->
        assert Keyword.get(opts, :receive_timeout) == 1_234
        {:ok, fake_final_response("ok")}
      end)

      Mimic.stub(ReqLLM.Response, :text, fn _ -> "ok" end)
      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{} end)
      Mimic.stub(ReqLLM.Context, :to_list, fn _ -> [] end)

      assert {:ok, %Response{}} =
               LLM.generate_text("openai:gpt-4o", [%{role: :user, content: "hi"}],
                 receive_timeout: 1_234
               )
    end

    test "propagates ReqLLM errors unchanged" do
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, _opts ->
        {:error, :something_blew_up}
      end)

      assert {:error, :something_blew_up} =
               LLM.generate_text("openai:gpt-4o", [%{role: :user, content: "hi"}])
    end
  end

  describe "generate_text_with_tools/4 tool loop" do
    test "returns :max_tool_iterations_exceeded when classify keeps asking for tools" do
      # Always say "call a tool" so the loop runs until the cap.
      Mimic.stub(ReqLLM, :generate_text, fn _model, _context, _opts ->
        {:ok, fake_tool_response()}
      end)

      Mimic.stub(ReqLLM.Response, :classify, fn _ ->
        %{type: :tool_calls, tool_calls: []}
      end)

      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{input_tokens: 1, output_tokens: 1} end)

      Mimic.stub(ReqLLM.Context, :execute_and_append_tools, fn ctx, _calls, _tools -> ctx end)

      tools = [LLM.tool("noop", "noop", [], fn _args -> {:ok, "ok"} end)]

      assert {:error, :max_tool_iterations_exceeded} =
               LLM.generate_text_with_tools(
                 "openai:gpt-4o",
                 [%{role: :user, content: "hi"}],
                 tools,
                 max_tool_iterations: 2
               )
    end

    test "falls back to default max_tool_iterations (10) when opt is absent" do
      # Count how many iterations actually happen before the cap bites.
      counter = :counters.new(1, [])

      Mimic.stub(ReqLLM, :generate_text, fn _model, _context, _opts ->
        :counters.add(counter, 1, 1)
        {:ok, fake_tool_response()}
      end)

      Mimic.stub(ReqLLM.Response, :classify, fn _ ->
        %{type: :tool_calls, tool_calls: []}
      end)

      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{} end)
      Mimic.stub(ReqLLM.Context, :execute_and_append_tools, fn ctx, _, _ -> ctx end)

      tools = [LLM.tool("noop", "noop", [], fn _args -> {:ok, "ok"} end)]

      assert {:error, :max_tool_iterations_exceeded} =
               LLM.generate_text_with_tools(
                 "openai:gpt-4o",
                 [%{role: :user, content: "hi"}],
                 tools
               )

      assert :counters.get(counter, 1) == 10
    end

    test "returns a final answer when classify says :final_answer on first call" do
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, _opts ->
        {:ok, fake_final_response("done")}
      end)

      Mimic.stub(ReqLLM.Response, :classify, fn _ -> %{type: :final_answer} end)
      Mimic.stub(ReqLLM.Response, :text, fn _ -> "done" end)
      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{input_tokens: 5, output_tokens: 7} end)
      Mimic.stub(ReqLLM.Context, :to_list, fn _ -> [] end)

      tools = [LLM.tool("noop", "noop", [], fn _args -> {:ok, "ok"} end)]

      assert {:ok, %Response{text: "done", usage: usage}} =
               LLM.generate_text_with_tools(
                 "openai:gpt-4o",
                 [%{role: :user, content: "hi"}],
                 tools
               )

      assert usage == %{input_tokens: 5, output_tokens: 7}
    end

    test "does NOT forward :max_tool_iterations down to ReqLLM.generate_text" do
      Mimic.expect(ReqLLM, :generate_text, fn _model, _context, opts ->
        refute Keyword.has_key?(opts, :max_tool_iterations)
        {:ok, fake_final_response("ok")}
      end)

      Mimic.stub(ReqLLM.Response, :classify, fn _ -> %{type: :final_answer} end)
      Mimic.stub(ReqLLM.Response, :text, fn _ -> "ok" end)
      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{} end)
      Mimic.stub(ReqLLM.Context, :to_list, fn _ -> [] end)

      assert {:ok, %Response{}} =
               LLM.generate_text_with_tools(
                 "openai:gpt-4o",
                 [%{role: :user, content: "hi"}],
                 [],
                 max_tool_iterations: 3
               )
    end
  end

  describe "generate_object/4 opt forwarding" do
    test "sets :receive_timeout to 5 minutes by default" do
      Mimic.expect(ReqLLM, :generate_object, fn _model, _prompt, _schema, opts ->
        assert Keyword.get(opts, :receive_timeout) == 5 * 60 * 1000
        {:ok, fake_object_response(%{"title" => "x"})}
      end)

      Mimic.stub(ReqLLM.Response, :object, fn _ -> %{"title" => "x"} end)
      Mimic.stub(ReqLLM.Response, :usage, fn _ -> %{} end)

      assert {:ok, %Response{object: %{"title" => "x"}}} =
               LLM.generate_object("openai:gpt-4o", "prompt", title: [type: :string])
    end
  end

  # Tiny fake responses — the struct is never inspected by the tests that use
  # these helpers because Response.text/classify/usage are stubbed.
  defp fake_final_response(_text), do: base_response()
  defp fake_tool_response, do: base_response()
  defp fake_object_response(_object), do: base_response()

  defp base_response do
    %ReqLLM.Response{
      id: "test-#{System.unique_integer([:positive])}",
      model: "openai:gpt-4o",
      context: ReqLLM.Context.new([])
    }
  end
end
