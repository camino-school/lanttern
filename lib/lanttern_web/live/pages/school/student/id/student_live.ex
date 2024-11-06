defmodule LantternWeb.StudentLive do
  alias Lanttern.GradesReports
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.FinalGradeDetailsOverlayComponent
  alias LantternWeb.Schools.StudentFormOverlayComponent
  import LantternWeb.GradesReportsComponents
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    student = Schools.get_student(params["id"], preloads: [classes: [:cycle, :years]])
    check_if_user_has_access(socket.assigns.current_user, student)

    socket =
      socket
      |> assign(:student, student)
      |> assign(:page_title, student.name)
      |> stream_student_report_cards()
      |> stream_grades_reports()

    {:ok, socket, temporary_assigns: [student_grades_maps: %{}]}
  end

  # check if user can view the student profile
  # teachers can view only students from their school
  defp check_if_user_has_access(current_user, %Student{} = student) do
    if student.school_id != current_user.current_profile.school_id,
      do: raise(LantternWeb.NotFoundError)
  end

  defp check_if_user_has_access(_current_user, nil),
    do: raise(LantternWeb.NotFoundError)

  defp stream_student_report_cards(socket) do
    student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.student.id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    socket
    |> stream(:student_report_cards, student_report_cards)
    |> assign(:has_student_report_cards, student_report_cards != [])
  end

  defp stream_grades_reports(socket) do
    student_id = socket.assigns.student.id

    grades_reports =
      GradesReports.list_student_grades_reports_grids(student_id)

    grades_reports_ids = Enum.map(grades_reports, & &1.id)

    student_grades_maps =
      GradesReports.build_student_grades_maps(student_id, grades_reports_ids)

    student_grades_report_entries_ids =
      student_grades_maps
      |> Enum.map(fn {_, cycle_and_subjects_map} -> cycle_and_subjects_map end)
      |> Enum.flat_map(&Enum.map(&1, fn {_, subjects_entries_map} -> subjects_entries_map end))
      |> Enum.flat_map(&Enum.map(&1, fn {_, entry} -> entry && entry.id end))
      |> Enum.filter(&Function.identity/1)

    student_grades_report_final_entries_ids =
      student_grades_maps
      |> Enum.map(fn {_, cycle_and_subjects_map} -> cycle_and_subjects_map[:final] end)
      |> Enum.flat_map(&Enum.map(&1, fn {_, entry} -> entry && entry.id end))
      |> Enum.filter(&Function.identity/1)

    socket
    |> stream(:grades_reports, grades_reports)
    |> assign(:has_grades_reports, grades_reports != [])
    |> assign(:student_grades_maps, student_grades_maps)
    |> assign(:student_grades_report_entries_ids, student_grades_report_entries_ids)
    |> assign(:student_grades_report_final_entries_ids, student_grades_report_final_entries_ids)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_is_editing(params)
      |> assign_student_grades_report_entry(params)

    {:noreply, socket}
  end

  defp assign_is_editing(socket, %{"edit" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  defp assign_student_grades_report_entry(socket, %{"student_grades_report_entry_id" => sgre_id}) do
    sgre_id = String.to_integer(sgre_id)

    # guard against user manipulated ids
    sgre_id =
      if sgre_id in socket.assigns.student_grades_report_entries_ids,
        do: sgre_id

    socket
    |> assign(:student_grades_report_entry_id, sgre_id)
    |> assign(:student_grades_report_final_entry_id, nil)
  end

  defp assign_student_grades_report_entry(socket, %{
         "student_grades_report_final_entry_id" => sgrfe_id
       }) do
    sgrfe_id = String.to_integer(sgrfe_id)

    # guard against user manipulated ids
    sgrfe_id =
      if sgrfe_id in socket.assigns.student_grades_report_final_entries_ids,
        do: sgrfe_id

    socket
    |> assign(:student_grades_report_entry_id, nil)
    |> assign(:student_grades_report_final_entry_id, sgrfe_id)
  end

  defp assign_student_grades_report_entry(socket, _params) do
    socket
    |> assign(:student_grades_report_entry_id, nil)
    |> assign(:student_grades_report_final_entry_id, nil)
  end

  @impl true
  def handle_info({StudentFormOverlayComponent, {:updated, student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student updated successfully"))
      |> push_navigate(to: ~p"/school/student/#{student}")

    {:noreply, socket}
  end

  def handle_info({StudentFormOverlayComponent, {:deleted, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student deleted successfully"))
      |> push_navigate(to: ~p"/school")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: socket
end
