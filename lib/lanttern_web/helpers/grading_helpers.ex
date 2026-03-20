defmodule LantternWeb.GradingHelpers do
  @moduledoc """
  Helper functions related to `Grading` context
  """

  alias Lanttern.Grading
  # alias Lanttern.Identity.Scope

  @doc """
  Generate list of scales to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  Accepts `list_opts` arg, which will be forwarded to `Grading.list_scales/1`.

  ## Examples

      iex> generate_scale_options()
      ["scale name": 1, ...]
  """
  def generate_scale_options(list_opts \\ []) do
    Grading.list_scales(list_opts)
    |> Enum.map(fn s -> {s.name, s.id} end)
  end

  # def generate_scale_options(%Scope{} = scope, list_opts \\ []) do
  #   Grading.list_scales(scope, list_opts)
  #   |> Enum.map(fn s -> {s.name, s.id} end)
  # end
end
