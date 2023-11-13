defmodule LantternWeb.SchoolLive.Show do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  # alias Lanttern.Rubrics.Rubric

  # function components

  attr :students, :list, required: true

  def class_students(%{students: students} = assigns) when length(students) > 5 do
    assigns =
      assigns
      |> assign(:len, "+ #{length(students) - 3} students")
      |> assign(:students, students |> Enum.take(3))

    ~H"""
    <div class="flex flex-wrap items-center gap-1">
      <.person_badge :for={std <- @students} person={std} theme="cyan" />
      <span><%= @len %></span>
    </div>
    """
  end

  def class_students(%{students: []} = assigns) do
    ~H"""
    No students in this class
    """
  end

  def class_students(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-1">
      <.person_badge :for={std <- @students} person={std} theme="cyan" />
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    school =
      case socket.assigns.current_user.current_profile.type do
        "student" ->
          socket.assigns.current_user.current_profile.student.school

        "teacher" ->
          socket.assigns.current_user.current_profile.teacher.school
      end

    classes = Schools.list_user_classes(socket.assigns.current_user)

    {:ok,
     socket
     |> assign(:school, school)
     |> stream(:classes, classes)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # defp apply_action(socket, :edit, %{"id" => id}) do
  #   socket
  #   |> assign(:overlay_title, "Edit rubric")
  #   |> assign(:rubric, Rubrics.get_rubric!(id, preloads: :descriptors))
  # end

  # defp apply_action(socket, :new, _params) do
  #   socket
  #   |> assign(:overlay_title, "Create Rubric")
  #   |> assign(:rubric, %Rubric{})
  # end

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
