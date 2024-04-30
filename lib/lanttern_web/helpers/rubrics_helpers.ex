defmodule LantternWeb.RubricsHelpers do
  @moduledoc """
  Helper functions related to `Rubrics` context
  """

  alias Lanttern.Rubrics

  @doc """
  Generate list of rubrics to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  Accepts `list_opts` arg, which will be forwarded to `Rubrics.list_rubrics/1`.

  ## Examples

      iex> generate_rubric_options()
      ["(#1) rubric criteria": 1, ...]
  """
  def generate_rubric_options(list_opts \\ []) do
    Rubrics.list_rubrics(list_opts)
    |> Enum.map(fn r -> {"(##{r.id}) #{r.criteria}", r.id} end)
  end
end
