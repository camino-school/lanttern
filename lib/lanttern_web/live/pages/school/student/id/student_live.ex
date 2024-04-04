defmodule LantternWeb.StudentLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  # lifecycle

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Schools.get_student(id, preloads: [classes: [:cycle, :years]]) do
      student
      when is_nil(student) or
             student.school_id != socket.assigns.current_user.current_profile.school_id ->
        socket
        |> put_flash(:error, "Couldn't find student")
        |> redirect(to: ~p"/school")

      student ->
        socket
        |> assign(:student_name, student.name)
        |> stream(:classes, student.classes)
        |> assign(:page_title, student.name)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket
end
