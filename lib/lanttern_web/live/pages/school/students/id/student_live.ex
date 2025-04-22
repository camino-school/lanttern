defmodule LantternWeb.StudentLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # page components

  alias __MODULE__.AboutComponent
  alias __MODULE__.GradesReportsComponent
  alias __MODULE__.ILPComponent
  alias __MODULE__.StudentRecordsComponent
  alias __MODULE__.StudentReportCardsComponent

  # shared components

  alias LantternWeb.Schools.StudentFormOverlayComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_student(params)
      |> assign_is_school_manager()

    {:ok, socket, temporary_assigns: [student_grades_maps: %{}]}
  end

  defp assign_student(socket, params) do
    case Schools.get_student(params["id"],
           preloads: [:school, classes: [:cycle, :years]],
           load_email: true
         ) do
      %Student{} = student ->
        check_if_user_has_access(socket.assigns.current_user, student)

        socket
        |> assign(:student, student)
        |> assign(:page_title, student.name)

      _ ->
        raise(LantternWeb.NotFoundError)
    end
  end

  # check if user can view the student profile
  # staff members can view only students from their school
  defp check_if_user_has_access(current_user, student) do
    if student.school_id != current_user.current_profile.school_id,
      do: raise(LantternWeb.NotFoundError)
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
  def handle_info({StudentFormOverlayComponent, {:updated, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student updated successfully"))
      |> push_navigate(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info({StudentFormOverlayComponent, {:deactivated, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student deactivated successfully"))
      |> push_navigate(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info({StudentFormOverlayComponent, {:deleted, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student deleted successfully"))
      |> push_navigate(to: ~p"/school/classes")

    {:noreply, socket}
  end

  def handle_info({StudentFormOverlayComponent, {:reactivated, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student reactivated successfully"))
      |> push_navigate(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
