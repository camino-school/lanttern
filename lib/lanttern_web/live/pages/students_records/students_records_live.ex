defmodule LantternWeb.StudentsRecordsLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components

  alias LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Students records"))
      |> assign_user_filters([:student_record_types, :student_record_statuses])
      |> stream_students_records()

    {:ok, socket}
  end

  defp stream_students_records(socket) do
    %{
      current_user: %{current_profile: %{school_id: school_id}},
      selected_student_record_types_ids: types_ids,
      selected_student_record_statuses_ids: statuses_ids
    } = socket.assigns

    students_records =
      StudentsRecords.list_students_records(
        school_id: school_id,
        types_ids: types_ids,
        statuses_ids: statuses_ids,
        preloads: [:type, :status, :students]
      )

    socket
    |> stream(:students_records, students_records, reset: true)
    |> assign(:students_records_length, length(students_records))
  end

  @impl true
  def handle_params(params, _uri, socket) do
    student_record =
      case params do
        %{"edit" => "new"} ->
          %StudentRecord{students: []}

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
    student_record =
      StudentsRecords.get_student_record(id, preloads: [:students_relationships, :students])
      |> put_students_ids()

    case student_record do
      nil ->
        nil

      student_record ->
        if student_record.school_id == socket.assigns.current_user.current_profile.school_id,
          do: student_record
    end
  end

  defp put_students_ids(nil), do: nil

  defp put_students_ids(student_record) do
    students_ids =
      student_record.students_relationships
      |> Enum.map(& &1.student_id)

    %{student_record | students_ids: students_ids}
  end

  @impl true
  def handle_event("remove_type_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_student_record_types_ids, [])
      |> save_profile_filters([:student_record_types])
      |> assign_user_filters([:student_record_types])
      |> stream_students_records()

    {:noreply, socket}
  end

  def handle_event("remove_status_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_student_record_statuses_ids, [])
      |> save_profile_filters([:student_record_statuses])
      |> assign_user_filters([:student_record_statuses])
      |> stream_students_records()

    {:noreply, socket}
  end

  def handle_event("filter_by_type", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_student_record_types_ids, do: [], else: [id]

    socket =
      socket
      |> assign(:selected_student_record_types_ids, selected_ids)
      |> save_profile_filters([:student_record_types])
      |> assign_user_filters([:student_record_types])
      |> stream_students_records()

    {:noreply, socket}
  end

  def handle_event("filter_by_status", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_student_record_statuses_ids, do: [], else: [id]

    socket =
      socket
      |> assign(:selected_student_record_statuses_ids, selected_ids)
      |> save_profile_filters([:student_record_statuses])
      |> assign_user_filters([:student_record_statuses])
      |> stream_students_records()

    {:noreply, socket}
  end
end
