defmodule LantternWeb.StudentLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # page components

  alias __MODULE__.StudentReportCardsComponent
  alias __MODULE__.GradesReportsComponent

  # shared components

  alias LantternWeb.Schools.StudentFormOverlayComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    student = Schools.get_student(params["id"], preloads: [classes: [:cycle, :years]])
    check_if_user_has_access(socket.assigns.current_user, student)

    socket =
      socket
      |> assign(:student, student)
      |> stream_grades_reports()
      |> assign_is_school_manager()
      |> assign(:page_title, student.name)

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

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_is_editing(params)

    {:noreply, socket}
  end

  defp assign_is_editing(%{assigns: %{is_school_manager: true}} = socket, %{"edit" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  @impl true
  def handle_info({StudentFormOverlayComponent, {:updated, student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student updated successfully"))
      |> push_navigate(to: ~p"/school/students/#{student}")

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
