defmodule LantternWeb.StudentReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  alias Lanttern.Identity.Profile
  alias Lanttern.Reporting
  alias Lanttern.Reporting.StudentReportCard
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # shared components
  alias LantternWeb.GradesReports.FinalGradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  import LantternWeb.AssessmentsComponents
  import LantternWeb.LearningContextComponents
  import LantternWeb.ReportingComponents
  import LantternWeb.GradesReportsComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    student_report_card =
      Reporting.get_student_report_card!(params["id"],
        preloads: [
          :student,
          report_card: :school_cycle
        ]
      )

    # check if user can view the student report
    check_if_user_has_access(socket.assigns.current_user, student_report_card)

    page_title = "#{student_report_card.student.name} • #{student_report_card.report_card.name}"

    cover_image_url =
      object_url_to_render_url(
        student_report_card.cover_image_url || student_report_card.report_card.cover_image_url,
        width: 1280,
        height: 640
      )

    is_staff_member = socket.assigns.current_user.current_profile.type == "staff"

    strand_reports_and_entries =
      Reporting.list_student_report_card_strand_reports_and_entries(
        student_report_card,
        include_strands_without_entries: is_staff_member
      )

    socket =
      socket
      |> assign(:student_report_card, student_report_card)
      |> assign(:cover_image_url, cover_image_url)
      |> stream_configure(
        :strand_reports_and_entries,
        dom_id: fn {strand_report, _entries} -> "strand-report-#{strand_report.id}" end
      )
      |> stream(:strand_reports_and_entries, strand_reports_and_entries)
      |> assign_grades_report()
      |> assign_students_grades_map()
      |> assign(:page_title, page_title)

    temporary_assigns = [
      grades_report: %{},
      student_grades_map: %{}
    ]

    {:ok, socket,
     layout: {LantternWeb.Layouts, :app_logged_in_blank}, temporary_assigns: temporary_assigns}
  end

  defp assign_grades_report(socket) do
    grades_report =
      case socket.assigns.student_report_card.report_card.grades_report_id do
        nil -> nil
        id -> GradesReports.get_grades_report(id, load_grid: true)
      end

    socket
    |> assign(:grades_report, grades_report)
  end

  defp assign_students_grades_map(socket) do
    student_grades_map =
      GradesReports.build_student_grades_map(socket.assigns.student_report_card.id)

    student_grades_report_entries_ids =
      student_grades_map
      |> Enum.map(fn {_, subjects_entries_map} -> subjects_entries_map end)
      |> Enum.flat_map(&Enum.map(&1, fn {_, entry} -> entry && entry.id end))
      |> Enum.filter(&Function.identity/1)

    student_grades_report_final_entries_ids =
      student_grades_map[:final]
      |> Enum.map(fn
        {_grades_report_subject_id, nil} -> nil
        {_grades_report_subject_id, final_entry} -> final_entry.id
      end)
      |> Enum.filter(&Function.identity/1)

    socket
    |> assign(:student_grades_map, student_grades_map)
    |> assign(:student_grades_report_entries_ids, student_grades_report_entries_ids)
    |> assign(:student_grades_report_final_entries_ids, student_grades_report_final_entries_ids)
  end

  defp check_if_user_has_access(current_user, %StudentReportCard{} = student_report_card) do
    # check if user can view the student report
    # guardian and students can only view their own reports if allow_access is true
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
  end

  @impl true
  def handle_params(params, _url, socket) do
    {sgre_id, sgrfe_id} =
      case params do
        %{"student_grades_report_entry_id" => sgre_id} ->
          sgre_id = String.to_integer(sgre_id)
          # guard against user manipulated ids
          if sgre_id in socket.assigns.student_grades_report_entries_ids,
            do: {sgre_id, nil},
            else: {nil, nil}

        %{"student_grades_report_final_entry_id" => sgrfe_id} ->
          sgrfe_id = String.to_integer(sgrfe_id)
          # guard against user manipulated ids
          if sgrfe_id in socket.assigns.student_grades_report_final_entries_ids,
            do: {nil, sgrfe_id},
            else: {nil, nil}

        _ ->
          {nil, nil}
      end

    socket =
      socket
      |> assign(:student_grades_report_entry_id, sgre_id)
      |> assign(:student_grades_report_final_entry_id, sgrfe_id)

    {:noreply, socket}
  end
end
