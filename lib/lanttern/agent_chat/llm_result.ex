defmodule Lanttern.AgentChat.LLMResult do
  @moduledoc """
  Result of an LLM chain run. Aggregates response text, token usage
  across tool call iterations, and conversation messages for rename.
  """

  @type t :: %__MODULE__{
          text: String.t(),
          usage: %{input_tokens: non_neg_integer(), output_tokens: non_neg_integer()},
          messages: [ReqLLM.Message.t()]
        }

  @enforce_keys [:text, :usage, :messages]
  defstruct [:text, :usage, :messages]
end
