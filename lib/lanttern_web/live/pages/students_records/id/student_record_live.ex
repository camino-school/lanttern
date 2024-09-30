defmodule LantternWeb.StudentRecordLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords

  # shared components

  alias LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_student_record(params)

    {:ok, socket}
  end

  defp assign_student_record(socket, %{"id" => id}) do
    student_record =
      StudentsRecords.get_student_record(id,
        preloads: [:students, :students_relationships, :type, :status]
      )
      |> put_students_ids()

    page_title = student_record.name || gettext("Student record details")

    socket
    |> assign(:student_record, student_record)
    |> assign(:page_title, page_title)
  end

  defp put_students_ids(student_record) do
    students_ids =
      student_record.students_relationships
      |> Enum.map(& &1.student_id)

    %{student_record | students_ids: students_ids}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # @impl true
  # def handle_params(params, _uri, socket) do
  #   student_record =
  #     case params do
  #       %{"edit" => "new"} ->
  #         %StudentRecord{}

  #       %{"edit" => id} ->
  #         get_student_record_and_validate_permission(socket, id)

  #       _ ->
  #         nil
  #     end

  #   socket =
  #     assign(socket, :student_record, student_record)

  #   {:noreply, socket}
  # end

  # defp get_student_record_and_validate_permission(socket, id) do
  #   student_record = StudentsRecords.get_student_record(id)

  #   case student_record do
  #     nil ->
  #       nil

  #     student_record ->
  #       if student_record.school_id == socket.assigns.current_user.current_profile.school_id,
  #         do: student_record
  #   end
  # end
end
