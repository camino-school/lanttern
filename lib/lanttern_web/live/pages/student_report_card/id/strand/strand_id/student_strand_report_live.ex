defmodule LantternWeb.StudentStrandReportLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Reporting

  # shared components
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(%{"id" => id, "strand_report_id" => strand_report_id}, _url, socket) do
    student_report_card =
      Reporting.get_student_report_card!(id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    strand_report =
      Reporting.get_strand_report!(strand_report_id,
        preloads: [strand: [:subjects, :years]]
      )

    strand_goals_student_entries =
      Assessments.list_strand_goals_student_entries(
        student_report_card.student.id,
        strand_report.strand.id
      )

    socket =
      socket
      |> assign(:student_report_card, student_report_card)
      |> assign(:strand_report, strand_report)
      |> assign(:strand_goals_student_entries, strand_goals_student_entries)

    {:noreply, socket}
  end
end
