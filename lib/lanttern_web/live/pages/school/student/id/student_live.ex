defmodule LantternWeb.StudentLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  # lifecycle

  def mount(_params, _session, socket) do
    user_school =
      case socket.assigns.current_user.current_profile.type do
        "student" ->
          socket.assigns.current_user.current_profile.student.school

        "teacher" ->
          socket.assigns.current_user.current_profile.teacher.school
      end

    {:ok,
     socket
     |> assign(:user_school, user_school)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Schools.get_student(id, preloads: [classes: [:cycle, :years]]) do
      student when is_nil(student) or student.school_id != socket.assigns.user_school.id ->
        socket
        |> put_flash(:error, "Couldn't find student")
        |> redirect(to: ~p"/school")

      student ->
        socket
        |> assign(:student_name, student.name)
        |> stream(:classes, student.classes)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket
end
