defmodule LantternWeb.GradingHelpers do
  alias Lanttern.Grading

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

  @doc """
  Generate list of ordinal values to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  ## Examples

      iex> generate_ordinal_value_options()
      ["ordinal value name": 1, ...]
  """
  def generate_ordinal_value_options() do
    Grading.list_ordinal_values()
    |> Enum.map(fn ov -> {ov.name, ov.id} end)
  end

  @doc """
  Generate list of grading compositions to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  ## Examples

      iex> generate_composition_options()
      ["composition name": 1, ...]
  """
  def generate_composition_options() do
    Grading.list_compositions()
    |> Enum.map(fn c -> {c.name, c.id} end)
  end

  @doc """
  Generate list of grading composition components to use as `Phoenix.HTML.Form.options_for_select/2` arg.

  ## Examples

      iex> generate_component_options()
      ["component name": 1, ...]
  """
  def generate_component_options() do
    Grading.list_composition_components()
    |> Enum.map(fn c -> {c.name, c.id} end)
  end
end
