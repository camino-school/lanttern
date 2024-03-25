defmodule LantternWeb.StudentReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  alias Lanttern.Reporting

  # shared components
  import LantternWeb.LearningContextComponents
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_configure(
        :strand_reports_and_entries,
        dom_id: fn {strand_report, _entries} -> "strand-report-#{strand_report.id}" end
      )

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    student_report_card =
      Reporting.get_student_report_card!(id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    strand_reports_and_entries =
      Reporting.list_student_report_card_strand_reports_and_entries(student_report_card)

    socket =
      socket
      |> assign(:student_report_card, student_report_card)
      |> stream(:strand_reports_and_entries, strand_reports_and_entries)
      |> assign_new(:grades_report, fn %{student_report_card: student_report_card} ->
        case student_report_card.report_card.grades_report_id do
          nil -> nil
          id -> Reporting.get_grades_report(id, load_grid: true)
        end
      end)
      |> assign_new(:student_grades_map, fn %{student_report_card: student_report_card} ->
        GradesReports.build_student_grades_map(student_report_card.id)
      end)

    {:noreply, socket}
  end
end
