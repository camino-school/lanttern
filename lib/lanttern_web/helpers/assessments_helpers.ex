defmodule LantternWeb.AssessmentsHelpers do
  alias Lanttern.Assessments

  @doc """
  Generate list of assessment poiints to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_assessment_point_options()
      ["assessment point name": 1, ...]
  """
  def generate_assessment_point_options() do
    Assessments.list_assessment_points()
    |> Enum.map(fn ap -> ["#{ap.name}": ap.id] end)
    |> Enum.concat()
  end
end
