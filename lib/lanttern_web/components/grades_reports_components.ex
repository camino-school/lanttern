defmodule LantternWeb.GradesReportsComponents do
  use Phoenix.Component

  import LantternWeb.Gettext

  alias Lanttern.GradesReports.StudentGradeReportEntry

  @doc """
  Renders a grade composition table.
  """
  attr :student_grade_report_entry, StudentGradeReportEntry, required: true
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def grade_composition_table(assigns) do
    ~H"""
    <div id={@id} class="w-full overflow-x-auto">
      <table class={["w-full rounded font-mono text-xs bg-ltrn-lightest", @class]}>
        <thead>
          <tr>
            <th class="p-2 text-left"><%= gettext("Strand") %></th>
            <th class="p-2 text-left"><%= gettext("Curriculum") %></th>
            <th class="p-2 text-left"><%= gettext("Assessment") %></th>
            <th class="p-2 text-right"><%= gettext("Weight") %></th>
            <th class="p-2 text-right"><%= gettext("Normalized value") %></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={component <- @student_grade_report_entry.composition}>
            <td class="p-2">
              <span :if={component.strand_type}>
                (<%= component.strand_type %>)
              </span>
              <%= component.strand_name %>
            </td>
            <td class="p-2">
              (<%= component.curriculum_component_name %>) <%= component.curriculum_item_name %>
            </td>
            <td class="p-2">
              <%= component.ordinal_value_name ||
                :erlang.float_to_binary(component.score, decimals: 2) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(component.weight, decimals: 1) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(
                component.normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
          <tr class="font-bold bg-ltrn-lighter">
            <td colspan="2" class="p-2">
              <%= gettext("Final grade") %>
            </td>
            <td class="p-2">
              <%= case @student_grade_report_entry.composition_ordinal_value do
                nil ->
                  :erlang.float_to_binary(
                    @student_grade_report_entry.composition_score,
                    decimals: 2
                  )

                ov ->
                  ov.name
              end %>
            </td>
            <td colspan="2" class="p-2 text-right">
              <%= :erlang.float_to_binary(
                @student_grade_report_entry.composition_normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
