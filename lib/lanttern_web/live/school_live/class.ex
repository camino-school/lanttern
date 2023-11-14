defmodule LantternWeb.SchoolLive.Class do
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
    case Schools.get_class(id, preloads: :students) do
      class when is_nil(class) or class.school_id != socket.assigns.user_school.id ->
        socket
        |> put_flash(:error, "Couldn't find class")
        |> redirect(to: ~p"/school")

      class ->
        socket
        |> assign(:class_name, class.name)
        |> stream(:students, class.students)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket
end
