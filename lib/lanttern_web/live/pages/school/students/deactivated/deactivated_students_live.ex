defmodule LantternWeb.DeactivatedStudentsLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    page_title =
      gettext(
        "%{school}'s deactivated students",
        school: socket.assigns.current_user.current_profile.school_name
      )

    socket =
      socket
      |> assign_is_school_manager()
      |> stream_students()
      |> assign(:page_title, page_title)

    {:ok, socket}
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  defp stream_students(socket) do
    cycle_id =
      socket.assigns.current_user.current_profile.current_school_cycle.id

    students =
      Schools.list_students(
        school_id: socket.assigns.current_user.current_profile.school_id,
        load_email: true,
        preload_classes_from_cycle_id: cycle_id,
        load_profile_picture_from_cycle_id: cycle_id,
        only_deactivated: true
      )

    socket
    |> stream(:students, students)
    |> assign(:students_length, length(students))
    |> assign(:students_ids, Enum.map(students, &"#{&1.id}"))
  end

  # event handlers

  @impl true
  def handle_event("reactivate", %{"id" => id}, socket) do
    if id in socket.assigns.students_ids do
      student = Schools.get_student!(id)

      case Schools.reactivate_student(student) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{student} reactivated", student: student.name)
            )
            |> stream_delete(:students, student)
            |> assign(:students_length, socket.assigns.students_length - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to reactivate student"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid student"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if id in socket.assigns.students_ids do
      student = Schools.get_student!(id)

      case Schools.delete_student(student) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{student} deleted", student: student.name)
            )
            |> stream_delete(:students, student)
            |> assign(:students_length, socket.assigns.students_length - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete student"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid student"))}
    end
  end
end
