defmodule LantternWeb.LearningContextHelpers do
  @moduledoc """
  Helper functions related to `LearningContext` context
  """

  alias Lanttern.LearningContext

  @doc """
  Generate list of strands to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_strand_options()
      [{"strand name", 1}, ...]
  """
  def generate_strand_options() do
    LearningContext.list_strands()
    |> Enum.map(fn s -> {s.name, s.id} end)
  end
end
