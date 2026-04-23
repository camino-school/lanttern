defmodule Lanttern.LLM.Tool do
  @moduledoc """
  Library-agnostic tool definition for LLM function calling.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          parameter_schema: keyword(),
          callback: (map() -> {:ok, term()} | {:error, term()})
        }

  @enforce_keys [:name, :description, :callback]
  defstruct [:name, :description, :callback, parameter_schema: []]
end
