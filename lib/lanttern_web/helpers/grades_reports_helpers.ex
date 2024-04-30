defmodule LantternWeb.GradesReportsHelpers do
  @moduledoc """
  Helper functions related to `GradesReports` context
  """

  alias Lanttern.GradesReports

  @doc """
  Generate list of grades reports to use as `Phoenix.HTML.Form.options_for_select/2` arg

  ## Examples

      iex> generate_grades_report_options()
      ["grades report name": 1, ...]
  """
  def generate_grades_report_options() do
    GradesReports.list_grades_reports()
    |> Enum.map(fn gr -> {gr.name, gr.id} end)
  end
end
