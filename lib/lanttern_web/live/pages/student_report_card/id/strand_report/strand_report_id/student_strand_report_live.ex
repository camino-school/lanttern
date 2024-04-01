defmodule LantternWeb.StudentStrandReportLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Identity.Profile
  alias Lanttern.Reporting
  import LantternWeb.SupabaseHelpers, only: [object_url_to_render_url: 2]

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

    # check if user can view the student strand report
    # guardian and students can only view their own reports
    # teachers can view only reports from their school

    report_card_student_id = student_report_card.student_id
    report_card_student_school_id = student_report_card.student.school_id

    case socket.assigns.current_user.current_profile do
      %Profile{type: "guardian", guardian_of_student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Profile{type: "student", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Profile{type: "teacher", school_id: school_id}
      when school_id == report_card_student_school_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end

    strand_report =
      Reporting.get_strand_report!(strand_report_id,
        preloads: [strand: [:subjects, :years]]
      )

    strand_goals_student_entries =
      Assessments.list_strand_goals_student_entries(
        student_report_card.student.id,
        strand_report.strand.id
      )

    cover_image_url =
      object_url_to_render_url(
        strand_report.cover_image_url || strand_report.strand.cover_image_url,
        width: 1280,
        height: 640
      )

    socket =
      socket
      |> assign(:student_report_card, student_report_card)
      |> assign(:strand_report, strand_report)
      |> assign(:strand_goals_student_entries, strand_goals_student_entries)
      |> assign(:cover_image_url, cover_image_url)

    {:noreply, socket}
  end
end
