defmodule LantternWeb.TaxonomyHelpers do
  alias Lanttern.Taxonomy

  @doc """
  Generate list of subjects to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_subject_options()
      ["subject name": 1, ...]
  """
  def generate_subject_options() do
    Taxonomy.list_subjects()
    |> Enum.map(fn s -> ["#{s.name}": s.id] end)
    |> Enum.concat()
  end

  @doc """
  Generate list of years to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_year_options()
      ["year name": 1, ...]
  """
  def generate_year_options() do
    Taxonomy.list_years()
    |> Enum.map(fn y -> ["#{y.name}": y.id] end)
    |> Enum.concat()
  end
end
