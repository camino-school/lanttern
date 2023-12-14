defmodule LantternWeb.ClassLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  # lifecycle

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case Schools.get_class(id, preloads: :students) do
      class
      when is_nil(class) or
             class.school_id != socket.assigns.current_user.current_profile.school.id ->
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
