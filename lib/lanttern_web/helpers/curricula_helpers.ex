defmodule LantternWeb.CurriculaHelpers do
  alias Lanttern.Curricula

  @doc """
  Generate list of curricula to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_curriculum_options()
      ["item name": 1, ...]
  """
  def generate_curriculum_options() do
    Curricula.list_curricula()
    |> Enum.map(fn c -> ["#{c.name}": c.id] end)
    |> Enum.concat()
  end

  @doc """
  Generate list of curriculum items to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_curriculum_item_options()
      ["item name": 1, ...]
  """
  def generate_curriculum_item_options() do
    Curricula.list_items()
    |> Enum.map(fn i -> ["#{i.name}": i.id] end)
    |> Enum.concat()
  end
end
