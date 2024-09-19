defmodule LantternWeb.StudentsRecordsLive do
  alias Lanttern.StudentsRecords.StudentRecord
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords

  # shared components

  alias LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_students_records()
      |> assign(:page_title, gettext("Students records"))

    {:ok, socket}
  end

  defp stream_students_records(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    students_records =
      StudentsRecords.list_students_records(school_id: school_id, preloads: [:type, :status])

    socket
    |> stream(:students_records, students_records)
    |> assign(:students_records_length, length(students_records))
  end

  @impl true
  def handle_params(params, _uri, socket) do
    student_record =
      case params do
        %{"edit" => "new"} ->
          %StudentRecord{}

        %{"edit" => id} ->
          get_student_record_and_validate_permission(socket, id)

        _ ->
          nil
      end

    socket =
      assign(socket, :student_record, student_record)

    {:noreply, socket}
  end

  defp get_student_record_and_validate_permission(socket, id) do
    student_record = StudentsRecords.get_student_record(id)

    case student_record do
      nil ->
        nil

      student_record ->
        if student_record.school_id == socket.assigns.current_user.current_profile.school_id,
          do: student_record
    end
  end
end
