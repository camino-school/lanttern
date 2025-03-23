defmodule Lanttern.ExOpenAIStub do
  @moduledoc """
  Stub for `ExOpenAI`-dependent tests.
  """

  defmodule Responses do
    @moduledoc """
    `ExOpenAI.Responses` stub
    """
    def create_response(_input, _model) do
      {:ok,
       %ExOpenAI.Components.Response{
         output: [
           %{
             content: [
               %{
                 text: "This is a stub response."
               }
             ]
           }
         ],
         # copilot generated
         error: nil,
         id: "stub-id",
         instructions: nil,
         metadata: nil,
         tools: [],
         object: "thread.run",
         created_at: 1_234_567_890,
         model: "gpt-4",
         temperature: 0.7,
         top_p: 1,
         incomplete_details: nil,
         parallel_tool_calls: false,
         tool_choice: nil
       }}
    end
  end
end
