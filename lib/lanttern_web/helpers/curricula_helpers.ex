defmodule LantternWeb.CurriculaHelpers do
  @moduledoc """
  Helper functions related to `Curricula` context
  """

  alias Lanttern.Curricula

  @doc """
  Generate list of curricula to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_curriculum_options()
      ["item name": 1, ...]
  """
  def generate_curriculum_options() do
    Curricula.list_curricula()
    |> Enum.map(fn c -> {c.name, c.id} end)
  end

  @doc """
  Generate list of curriculum components to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_curriculum_component_options()
      ["curriculum component name": 1, ...]
  """
  def generate_curriculum_component_options() do
    Curricula.list_curriculum_components()
    |> Enum.map(fn c -> {c.name, c.id} end)
  end

  @doc """
  Generate list of curriculum items to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_curriculum_item_options()
      ["item name": 1, ...]
  """
  def generate_curriculum_item_options() do
    Curricula.list_curriculum_items()
    |> Enum.map(fn i -> {i.name, i.id} end)
  end
end
