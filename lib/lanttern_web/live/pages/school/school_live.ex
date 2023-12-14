defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

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
    {:ok,
     socket
     |> stream(:classes, Schools.list_user_classes(socket.assigns.current_user, preload: true))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, _live_action, _params), do: socket
end
