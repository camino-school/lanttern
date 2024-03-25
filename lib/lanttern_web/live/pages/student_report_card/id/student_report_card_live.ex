defmodule LantternWeb.StudentReportCardLive do
  alias Lanttern.GradesReports.StudentGradeReportEntry
  use LantternWeb, :live_view
  alias Lanttern.Repo

  alias Lanttern.GradesReports
  alias Lanttern.Reporting

  # shared components
  import LantternWeb.LearningContextComponents
  import LantternWeb.GradingComponents
  import LantternWeb.ReportingComponents
  import LantternWeb.GradesReportsComponents

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
  def handle_params(%{"id" => id} = params, _url, socket) do
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
      |> assign_is_showing_grade_details(params)

    {:noreply, socket}
  end

  defp assign_is_showing_grade_details(
         socket = %{assigns: %{student_grades_map: student_grades_map}},
         %{"grades_report_subject_id" => grs_id, "grades_report_cycle_id" => grc_id}
       ) do
    grc_id = String.to_integer(grc_id)
    grs_id = String.to_integer(grs_id)

    case student_grades_map[grc_id][grs_id] do
      %StudentGradeReportEntry{} = sgre ->
        sgre =
          sgre
          |> Repo.preload([
            :composition_ordinal_value,
            grades_report_subject: :subject,
            grades_report_cycle: :school_cycle
          ])

        socket
        |> assign(:student_grade_report_entry, sgre)
        |> assign(:is_showing_grade_details, true)

      _ ->
        assign(socket, :is_showing_grade_details, false)
    end
  end

  defp assign_is_showing_grade_details(socket, _),
    do: assign(socket, :is_showing_grade_details, false)

  # event handlers

  @impl true
  def handle_event("view_grade_details", params, socket) do
    %{
      "gradesreportcycleid" => grc_id,
      "gradesreportsubjectid" => grs_id
    } = params

    url_params =
      %{
        "grades_report_cycle_id" => grc_id,
        "grades_report_subject_id" => grs_id
      }

    {:noreply,
     push_patch(socket,
       to: ~p"/student_report_card/#{socket.assigns.student_report_card}?#{url_params}"
     )}
  end
end
