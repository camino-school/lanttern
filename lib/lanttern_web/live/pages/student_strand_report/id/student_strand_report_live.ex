defmodule LantternWeb.StudentStrandReportLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Profile
  alias Lanttern.Reporting
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # page components
  alias LantternWeb.StudentStrandReportLive.StudentNotesComponent

  # shared components
  alias LantternWeb.Reporting.StrandReportOverviewComponent
  alias LantternWeb.Reporting.StrandReportAssessmentComponent
  alias LantternWeb.Reporting.StrandReportMomentsComponent

  @tabs %{
    "overview" => :overview,
    "assessment" => :assessment,
    "moments" => :moments,
    "student_notes" => :student_notes
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:student_report_card, nil)
      |> assign(:initialized, false)

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_student_report_card(params)
      # check if user can view the strand report
      |> check_if_user_has_access()
      |> assign_strand_report(params)
      |> assign_is_student()
      |> assign(:params, params)
      |> assign_current_tab(params)
      |> assign(:initialized, true)

    {:noreply, socket}
  end

  defp assign_student_report_card(%{assigns: %{initialized: false}} = socket, params) do
    %{"strand_report_id" => strand_report_id} = params

    # don't need to worry with other profile types
    # (handled by :ensure_authenticated_student_or_guardian in router)
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_report_card =
      Reporting.get_student_report_card_by_student_and_strand_report(student_id, strand_report_id,
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    assign(socket, :student_report_card, student_report_card)
  end

  defp assign_student_report_card(socket, _params), do: socket

  defp check_if_user_has_access(%{assigns: %{student_report_card: nil}} = _socket),
    do: raise(LantternWeb.NotFoundError)

  defp check_if_user_has_access(socket) do
    %{current_user: current_user, student_report_card: student_report_card} = socket.assigns
    # check if user can view the student strand report
    # guardian and students can only view their own reports

    report_card_student_id = student_report_card.student_id

    case current_user.current_profile do
      %Profile{type: "guardian", guardian_of_student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Profile{type: "student", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end

    socket
  end

  defp assign_strand_report(%{assigns: %{initialized: false}} = socket, params) do
    %{"strand_report_id" => strand_report_id} = params
    student_report_card = socket.assigns.student_report_card

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

    socket
    |> assign(:strand_report, strand_report)
    |> assign(:cover_image_url, cover_image_url)
    |> assign(:page_title, page_title)
  end

  defp assign_strand_report(socket, _params), do: socket

  defp assign_is_student(socket) do
    # flag to control student notes UI
    is_student =
      socket.assigns.student_report_card.student_id ==
        socket.assigns.current_user.current_profile.student_id

    assign(socket, :is_student, is_student)
  end

  defp assign_current_tab(socket, %{"tab" => tab}),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :overview))

  defp assign_current_tab(socket, _params),
    do: assign(socket, :current_tab, :overview)
end
