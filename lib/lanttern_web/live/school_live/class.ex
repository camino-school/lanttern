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

  defp apply_action(socket, :class, %{"id" => id}) do
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

  # # event handlers

  # def handle_event("delete", %{"id" => id}, socket) do
  #   rubric = Rubrics.get_rubric!(id)
  #   {:ok, _} = Rubrics.delete_rubric(rubric)

  #   socket =
  #     socket
  #     |> stream_delete(:rubrics, rubric)
  #     |> update(:results, &(&1 - 1))

  #   {:noreply, socket}
  # end

  # # info handlers

  # def handle_info({LantternWeb.RubricsLive.FormComponent, {:created, rubric}}, socket) do
  #   rubric = Rubrics.get_full_rubric!(rubric.id)

  #   socket =
  #     socket
  #     |> stream_insert(:rubrics, rubric)
  #     |> update(:results, &(&1 + 1))

  #   {:noreply, socket}
  # end

  # def handle_info({LantternWeb.RubricsLive.FormComponent, {:updated, rubric}}, socket) do
  #   rubric = Rubrics.get_full_rubric!(rubric.id)
  #   {:noreply, stream_insert(socket, :rubrics, rubric)}
  # end
end
