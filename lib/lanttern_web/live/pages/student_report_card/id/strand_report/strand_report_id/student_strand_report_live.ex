defmodule LantternWeb.StudentStrandReportLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Profile
  alias Lanttern.Reporting
  alias Lanttern.Reporting.StudentReportCard
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # page components
  alias LantternWeb.StudentStrandReportLive.MomentsComponent
  alias LantternWeb.StudentStrandReportLive.AssessmentComponent
  alias LantternWeb.StudentStrandReportLive.StudentNotesComponent

  # shared components
  import LantternWeb.ReportingComponents

  @tabs %{
    "overview" => :overview,
    "assessment" => :assessment,
    "student_notes" => :student_notes
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{"id" => id, "strand_report_id" => strand_report_id} = params

    student_report_card =
      Reporting.get_student_report_card!(id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    # check if user can view the student report
    check_if_user_has_access(socket.assigns.current_user, student_report_card)

    strand_report =
      Reporting.get_strand_report!(strand_report_id,
        preloads: [strand: [:subjects, :years]]
      )

    cover_image_url =
      object_url_to_render_url(
        strand_report.cover_image_url || strand_report.strand.cover_image_url,
        width: 1280,
        height: 640
      )

    page_title =
      "#{strand_report.strand.name} • #{student_report_card.student.name} • #{student_report_card.report_card.name}"

    # flag to control student notes UI
    is_student =
      student_report_card.student_id == socket.assigns.current_user.current_profile.student_id

    socket =
      socket
      |> assign(:student_report_card, student_report_card)
      |> assign(:strand_report, strand_report)
      |> assign(:cover_image_url, cover_image_url)
      |> assign(:page_title, page_title)
      |> assign(:is_student, is_student)
      |> assign(:params, params)
      |> assign_current_tab(params)

    {:noreply, socket}
  end

  defp check_if_user_has_access(current_user, %StudentReportCard{} = student_report_card) do
    # check if user can view the student strand report
    # guardian and students can only view their own reports
    # teachers can view only reports from their school

    report_card_student_id = student_report_card.student_id
    report_card_student_school_id = student_report_card.student.school_id
    allow_student_access = student_report_card.allow_student_access
    allow_guardian_access = student_report_card.allow_guardian_access

    case current_user.current_profile do
      %Profile{type: "guardian", guardian_of_student_id: student_id}
      when student_id == report_card_student_id and allow_guardian_access ->
        nil

      %Profile{type: "student", student_id: student_id}
      when student_id == report_card_student_id and allow_student_access ->
        nil

      %Profile{type: "teacher", school_id: school_id}
      when school_id == report_card_student_school_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end
  end

  defp assign_current_tab(socket, %{"tab" => tab}),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :overview))

  defp assign_current_tab(socket, _params),
    do: assign(socket, :current_tab, :overview)
end
