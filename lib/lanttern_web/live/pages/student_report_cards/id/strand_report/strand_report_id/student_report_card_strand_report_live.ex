defmodule LantternWeb.StudentReportCardStrandReportLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Profile
  alias Lanttern.Notes
  alias Lanttern.Notes.Note
  alias Lanttern.Reporting

  alias LantternWeb.Notes.NoteComponent
  alias LantternWeb.Reporting.StrandReportAssessmentComponent
  alias LantternWeb.Reporting.StrandReportMomentsComponent
  alias LantternWeb.Reporting.StrandReportOverviewComponent

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]
  import LantternWeb.ReportingComponents

  @tabs %{
    "assessment" => :assessment,
    "moments" => :moments,
    "overview" => :overview,
    "student_notes" => :student_notes
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_student_report_card(params)
      # check if user can view the strand report
      |> check_if_user_has_access()
      |> assign_strand_report(params)
      |> assign_student_note()
      |> assign_is_student()
      |> assign_allow_access()

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  defp assign_student_report_card(socket, params) do
    %{"student_report_card_id" => id} = params

    student_report_card =
      Reporting.get_student_report_card!(id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    assign(socket, :student_report_card, student_report_card)
  end

  defp check_if_user_has_access(%{assigns: %{student_report_card: nil}} = _socket),
    do: raise(LantternWeb.NotFoundError)

  defp check_if_user_has_access(socket) do
    %{current_user: current_user, student_report_card: student_report_card} = socket.assigns
    # check if user can view the student strand report
    # guardian and students can only view their own reports
    # staff members can view only reports from their school

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

      %Profile{type: "staff", school_id: school_id}
      when school_id == report_card_student_school_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end

    socket
  end

  defp assign_strand_report(socket, params) do
    %{"strand_report_id" => strand_report_id} = params
    student_report_card = socket.assigns.student_report_card

    strand_report =
      Reporting.get_strand_report!(strand_report_id,
        preloads: [strand: [:subjects, :years]],
        check_if_has_moments: true
      )

    cover_image_url =
      object_url_to_render_url(
        strand_report.cover_image_url || strand_report.strand.cover_image_url,
        width: 1280,
        height: 640
      )

    page_title =
      "#{strand_report.strand.name} • #{student_report_card.student.name} • #{student_report_card.report_card.name}"

    socket
    |> assign(:strand_report, strand_report)
    |> assign(:cover_image_url, cover_image_url)
    |> assign(:page_title, page_title)
  end

  defp assign_student_note(socket) do
    student_id = socket.assigns.student_report_card.student_id
    strand_id = socket.assigns.strand_report.strand_id

    note =
      Notes.get_student_note(student_id, strand_id: strand_id)

    assign(socket, :note, note)
  end

  defp assign_is_student(socket) do
    # flag to control student notes UI
    is_student = socket.assigns.current_user.current_profile.type == "student"

    assign(socket, :is_student, is_student)
  end

  defp assign_allow_access(socket) do
    allow_access =
      case {socket.assigns.current_user.current_profile.type, socket.assigns.student_report_card} do
        {"student", %{allow_student_access: true}} -> true
        {"guardian", %{allow_guardian_access: true}} -> true
        _ -> false
      end

    assign(socket, :allow_access, allow_access)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_current_tab(params)

    {:noreply, socket}
  end

  defp assign_current_tab(socket, %{"tab" => "moments"}) do
    current_tab =
      if socket.assigns.strand_report.has_moments, do: :moments, else: :overview

    assign(socket, :current_tab, current_tab)
  end

  defp assign_current_tab(socket, %{"tab" => "student_notes"}) do
    current_tab =
      case {socket.assigns.note, socket.assigns.current_user.current_profile} do
        {_, %{type: "student"}} -> :student_notes
        {%Note{}, _} -> :student_notes
        _ -> :overview
      end

    assign(socket, :current_tab, current_tab)
  end

  defp assign_current_tab(socket, %{"tab" => tab}),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :overview))

  defp assign_current_tab(socket, _params),
    do: assign(socket, :current_tab, :overview)
end
