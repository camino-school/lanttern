defmodule LantternWeb.GradesReports.FinalGradeDetailsOverlayComponent do
  @moduledoc """
  Renders a final grade details overlay component.

  #### Expected external assigns

      attr :student_grades_report_final_entry_id, :integer
      attr :on_cancel, JS

  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  # shared components
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Final grade details") %></:title>
        <div class="flex items-center gap-6 mb-10">
          <div
            :if={@student_grades_report_final_entry.ordinal_value}
            class="self-stretch flex items-center p-6 rounded"
            style={create_color_map_style(@student_grades_report_final_entry.ordinal_value)}
          >
            <%= @student_grades_report_final_entry.ordinal_value.name %>
          </div>
          <div
            :if={@student_grades_report_final_entry.score}
            class="self-stretch flex items-center p-6 border border-ltrn-lighter rounded font-mono font-bold bg-ltrn-lightes"
          >
            <%= @student_grades_report_final_entry.score %>
          </div>
          <div class="flex-1">
            <.metadata icon_name="hero-bookmark">
              <span class="font-bold"><%= gettext("Subject") %>:</span>
              <%= Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                @student_grades_report_final_entry.grades_report_subject.subject.name
              ) %>
            </.metadata>
            <.metadata class="mt-4" icon_name="hero-calendar">
              <span class="font-bold"><%= gettext("Cycle") %>:</span>
              <%= @cycle_name %>
            </.metadata>
          </div>
        </div>

        <div
          :if={
            @student_grades_report_final_entry.pre_retake_ordinal_value ||
              @student_grades_report_final_entry.pre_retake_score
          }
          class="flex items-center gap-4 p-4 rounded mb-10 bg-ltrn-lightest"
        >
          <div
            :if={@student_grades_report_final_entry.pre_retake_ordinal_value}
            class="self-stretch flex items-center px-4 py-2 rounded text-sm opacity-70"
            style={
              create_color_map_style(@student_grades_report_final_entry.pre_retake_ordinal_value)
            }
          >
            <%= @student_grades_report_final_entry.pre_retake_ordinal_value.name %>
          </div>
          <div
            :if={@student_grades_report_final_entry.pre_retake_score}
            class="self-stretch flex items-center px-4 py-2 rounded font-mono font-bold text-sm opacity-70"
          >
            <%= @student_grades_report_final_entry.pre_retake_score %>
          </div>
          <p class="text-sm text-ltrn-subtle"><%= gettext("Grade before retake process") %></p>
        </div>
        <%= if @student_grades_report_final_entry.comment do %>
          <h6 class="mb-4 font-display font-bold"><%= gettext("Comment") %></h6>
          <.markdown text={@student_grades_report_final_entry.comment} size="sm" class="mb-10" />
        <% end %>
        <h6 class="mb-4 font-display font-bold"><%= gettext("Grade composition") %></h6>
        <.final_grade_composition_table student_grades_report_final_entry={
          @student_grades_report_final_entry
        } />
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  @impl true
  def update(assigns, socket) do
    sgrfe =
      GradesReports.get_student_grades_report_final_entry!(
        assigns.student_grades_report_final_entry_id,
        preloads: [
          :composition_ordinal_value,
          :pre_retake_ordinal_value,
          :ordinal_value,
          grades_report: :school_cycle,
          grades_report_subject: :subject
        ]
      )

    cycle_name = sgrfe.grades_report.school_cycle.name

    socket =
      socket
      |> assign(assigns)
      |> assign(:student_grades_report_final_entry, sgrfe)
      |> assign(:cycle_name, cycle_name)

    {:ok, socket}
  end
end
