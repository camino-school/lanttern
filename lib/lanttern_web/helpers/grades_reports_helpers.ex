defmodule LantternWeb.GradesReportsHelpers do
  @moduledoc """
  Helper functions related to `GradesReports` context
  """

  use Gettext, backend: Lanttern.Gettext
  alias Lanttern.GradesReports

  @doc """
  Generate list of grades reports to use as `Phoenix.HTML.Form.options_for_select/2` arg

  View `GradesReports.list_grades_reports/1` for opts details.

  ## Examples

      iex> generate_grades_report_options()
      ["grades report name": 1, ...]
  """
  def generate_grades_report_options(opts \\ []) do
    GradesReports.list_grades_reports(opts)
    |> Enum.map(fn gr -> {gr.name, gr.id} end)
  end

  @doc """
  Format the results map returned by grades report batch
  calculation functions into a (human) readable message.
  """
  def build_calculation_results_message(%{} = results),
    do: build_calculation_results_message(Enum.map(results, & &1), [])

  defp build_calculation_results_message([], msgs),
    do: Enum.join(msgs, ", ")

  defp build_calculation_results_message([{_operation, 0} | results], msgs),
    do: build_calculation_results_message(results, msgs)

  defp build_calculation_results_message([{:created, count} | results], msgs) do
    msg = ngettext("1 grade created", "%{count} grades created", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:updated, count} | results], msgs) do
    msg = ngettext("1 grade updated", "%{count} grades updated", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:updated_with_manual, count} | results], msgs) do
    msg =
      ngettext(
        "1 grade partially updated (only composition, manual grade not changed)",
        "%{count} grades partially updated (only compositions, manual grades not changed)",
        count
      )

    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:deleted, count} | results], msgs) do
    msg = ngettext("1 grade removed", "%{count} grades removed", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:noop, count} | results], msgs) do
    msg =
      ngettext(
        "1 grade calculation skipped (no composition entries)",
        "%{count} grades skipped (no composition entries)",
        count
      )

    build_calculation_results_message(results, [msg | msgs])
  end
end
