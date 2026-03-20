defmodule Lanttern.ReqLLMStub do
  @moduledoc """
  Stub for `ReqLLM`-dependent tests.
  """

  def generate_text(_model, _context, _opts \\ []) do
    {:ok,
     %ReqLLM.Response{
       id: "stub-id",
       model: "stub-model",
       context: ReqLLM.Context.new([]),
       message: %ReqLLM.Message{
         role: :assistant,
         content: [ReqLLM.Message.ContentPart.text("This is a stub response.")]
       }
     }}
  end
end
