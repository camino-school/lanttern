defmodule Lanttern.LLM.Response do
  @moduledoc """
  Library-agnostic LLM response.

  Provides a stable struct that business logic and tests can depend on
  without coupling to the underlying LLM library (currently ReqLLM).

  ## Fields

  - `text` — the final assistant text response
  - `usage` — token counts (`%{input_tokens: n, output_tokens: n}`)
  - `object` — structured output map (from `generate_object/4`)
  - `messages` — conversation history for reference/display only.
    Limited to `:user`, `:assistant`, and `:system` turns; tool-call and
    tool-result entries are filtered out by `Lanttern.LLM` at the wrapper
    boundary.
  """

  @type role :: :user | :assistant | :system

  @type t :: %__MODULE__{
          text: String.t() | nil,
          usage: %{input_tokens: non_neg_integer(), output_tokens: non_neg_integer()},
          object: map() | nil,
          messages: [%{role: role(), content: String.t()}]
        }

  defstruct text: nil, usage: %{input_tokens: 0, output_tokens: 0}, object: nil, messages: []
end
