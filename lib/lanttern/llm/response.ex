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
    May contain `:tool` role entries that cannot be fed back into
    `generate_text/3` or `generate_text_with_tools/4`.
  """

  @type t :: %__MODULE__{
          text: String.t() | nil,
          usage: %{input_tokens: non_neg_integer(), output_tokens: non_neg_integer()},
          object: map() | nil,
          messages: [%{role: atom(), content: String.t()}]
        }

  defstruct text: nil, usage: %{input_tokens: 0, output_tokens: 0}, object: nil, messages: []
end
