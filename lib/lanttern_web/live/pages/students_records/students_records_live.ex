defmodule LantternWeb.StudentsRecordsLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.Schools.Cycle

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, assign_classes_filter: 2, save_profile_filters: 2]

  import LantternWeb.PersonalizationHelpers, only: [profile_has_permission?: 2]

  # shared components

  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    if !profile_has_permission?(socket.assigns.current_user.current_profile, "wcd"),
      do: raise(LantternWeb.NotFoundError)

    socket =
      socket
      |> assign(:page_title, gettext("Students records"))
      |> assign_user_filters([:students, :student_record_types, :student_record_statuses])
      |> apply_assign_classes_filter()
      |> stream_students_records()
      |> assign(:show_student_search_modal, false)

    {:ok, socket}
  end

  defp apply_assign_classes_filter(socket) do
    assign_classes_filter_opts =
      case socket.assigns.current_user.current_profile do
        %{current_school_cycle: %Cycle{} = cycle} -> [cycles_ids: [cycle.id]]
        _ -> []
      end

    assign_classes_filter(socket, assign_classes_filter_opts)
  end

  defp stream_students_records(socket, reset \\ false) do
    %{
      current_user: %{current_profile: %{school_id: school_id}},
      selected_students_ids: students_ids,
      selected_classes_ids: classes_ids,
      selected_student_record_types_ids: types_ids,
      selected_student_record_statuses_ids: statuses_ids
    } = socket.assigns

    {keyset, len} =
      if reset,
        do: {nil, 0},
        else: {socket.assigns[:keyset], socket.assigns[:students_records_length] || 0}

    page =
      StudentsRecords.list_students_records_page(
        school_id: school_id,
        students_ids: students_ids,
        classes_ids: classes_ids,
        types_ids: types_ids,
        statuses_ids: statuses_ids,
        preloads: [:type, :status, :students, [classes: :cycle]],
        first: 20,
        after: keyset
      )

    %{
      results: students_records,
      keyset: keyset,
      has_next: has_next
    } = page

    len = len + length(students_records)

    socket
    |> stream(:students_records, students_records, reset: reset)
    |> assign(:students_records_length, len)
    |> assign(:has_next, has_next)
    |> assign(:keyset, keyset)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    student_record =
      case params do
        %{"edit" => "new"} ->
          %StudentRecord{
            students: socket.assigns.selected_students,
            students_ids: socket.assigns.selected_students_ids,
            date: Date.utc_today()
          }

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
      StudentsRecords.get_student_record(id,
        preloads: [:students_relationships, :students, :classes_relationships, :classes]
      )
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
  def handle_event("remove_student_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_students_ids, [])
      |> save_profile_filters([:students])
      |> assign_user_filters([:students])
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("remove_class_filter", %{"id" => class_id}, socket) do
    selected_classes_ids =
      socket.assigns.selected_classes_ids
      |> Enum.filter(&(&1 != class_id))

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> save_profile_filters([:classes])
      |> apply_assign_classes_filter()
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("remove_type_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_student_record_types_ids, [])
      |> save_profile_filters([:student_record_types])
      |> assign_user_filters([:student_record_types])
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("remove_status_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_student_record_statuses_ids, [])
      |> save_profile_filters([:student_record_statuses])
      |> assign_user_filters([:student_record_statuses])
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("open_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, true)}

  def handle_event("close_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, false)}

  def handle_event("filter_by_type", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_student_record_types_ids, do: [], else: [id]

    socket =
      socket
      |> assign(:selected_student_record_types_ids, selected_ids)
      |> save_profile_filters([:student_record_types])
      |> assign_user_filters([:student_record_types])
      |> stream_students_records(true)

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
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("load_more", _, socket),
    do: {:noreply, stream_students_records(socket)}

  # info handlers

  @impl true
  def handle_info({StudentSearchComponent, {:selected, student}}, socket) do
    socket =
      socket
      |> assign(:selected_students_ids, [student.id])
      |> save_profile_filters([:students])
      |> assign_user_filters([:students])
      |> stream_students_records(true)
      |> assign(:show_student_search_modal, false)

    {:noreply, socket}
  end

  def handle_info({StudentRecordFormOverlayComponent, {:created, _student_record}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student record created successfully"))
      |> push_navigate(to: ~p"/students_records")

    {:noreply, socket}
  end

  def handle_info({StudentRecordFormOverlayComponent, {:updated, _student_record}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student record updated successfully"))
      |> push_navigate(to: ~p"/students_records")

    {:noreply, socket}
  end

  def handle_info({StudentRecordFormOverlayComponent, {:deleted, _student_record}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student record deleted successfully"))
      |> push_navigate(to: ~p"/students_records")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: socket
end
