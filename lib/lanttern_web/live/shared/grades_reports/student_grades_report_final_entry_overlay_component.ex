defmodule LantternWeb.GradesReports.StudentGradesReportFinalEntryOverlayComponent do
  @moduledoc """
  Renders an overlay with details of a `StudentGradesReportFinalEntry`
  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  # shared
  alias LantternWeb.GradesReports.StudentGradesReportFinalEntryFormComponent
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="student-grade-report-final-entry-overlay" show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Edit student grades report final entry") %></:title>
        <.metadata class="mb-4" icon_name="hero-user">
          <%= @student_grades_report_final_entry.student.name %>
        </.metadata>
        <.metadata class="mb-4" icon_name="hero-bookmark">
          <%= @student_grades_report_final_entry.grades_report_subject.subject.name %>
        </.metadata>
        <%!-- <.metadata class="mb-4" icon_name="hero-calendar">
          <%= @student_grades_report_final_entry.grades_report_cycle.school_cycle.name %>
        </.metadata> --%>
        <.live_component
          module={StudentGradesReportFinalEntryFormComponent}
          id={@student_grades_report_final_entry.id}
          student_grades_report_final_entry={@student_grades_report_final_entry}
          scale_id={@scale_id}
          navigate={@navigate}
          hide_submit
        />
        <div class="py-10">
          <h6 class="font-display font-bold"><%= gettext("Grade composition") %></h6>
          <p class="mt-4 mb-6 text-sm">
            <%= gettext(
              "Lanttern automatic grade calculation info based on configured grade composition"
            ) %> (<%= Timex.local(@student_grades_report_final_entry.composition_datetime)
            |> Timex.format!("{0D}/{0M}/{YYYY} {h24}:{m}") %>).
          </p>
          <.final_grade_composition_table student_grades_report_final_entry={
            @student_grades_report_final_entry
          } />
        </div>
        <:actions_left>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_student_grades_report_final_entry"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#student-grade-report-final-entry-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="student-grade-report-final-entry-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def handle_event("delete_student_grades_report_final_entry", _params, socket) do
    case GradesReports.delete_student_grades_report_final_entry(
           socket.assigns.student_grades_report_final_entry
         ) do
      {:ok, _student_grades_report_final_entry} ->
        socket =
          socket
          |> put_flash(:info, gettext("Student grade report final entry deleted"))
          |> push_navigate(to: socket.assigns.navigate)

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting student grade report final entry"))

        {:noreply, socket}
    end
  end
end
