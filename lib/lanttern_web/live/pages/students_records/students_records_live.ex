defmodule LantternWeb.StudentsRecordsLive do
  use LantternWeb, :live_view

  alias Lanttern.Filters
  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.StudentsRecords

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, assign_classes_filter: 2, save_profile_filters: 2]

  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import LantternWeb.StudentsRecordsComponents

  # shared components

  alias LantternWeb.Schools.StaffMemberSearchComponent
  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.StudentsRecords.StudentRecordOverlayComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Student records"))
      |> assign_user_filters([
        :students,
        :student_record_tags,
        :student_tags,
        :student_record_statuses,
        :student_record_assignees,
        :student_record_view
      ])
      |> apply_assign_classes_filter()
      |> stream_students_records()
      |> assign(:show_student_search_modal, false)
      |> assign(:show_assignee_search_modal, false)
      |> assign(:new_record_initial_fields, nil)
      |> assign_has_full_access()

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
      current_user: %{current_profile: profile},
      selected_students_ids: students_ids,
      selected_classes_ids: classes_ids,
      selected_student_record_tags_ids: tags_ids,
      selected_student_tags_ids: student_tags_ids,
      selected_student_record_statuses_ids: statuses_ids,
      selected_student_record_assignees_ids: assignees_ids
    } = socket.assigns

    {keyset, len} =
      if reset,
        do: {nil, 0},
        else: {socket.assigns[:keyset], socket.assigns[:students_records_length] || 0}

    page =
      StudentsRecords.list_students_records_page(
        check_profile_permissions: profile,
        students_ids: students_ids,
        classes_ids: classes_ids,
        tags_ids: tags_ids,
        student_tags_ids: student_tags_ids,
        statuses_ids: statuses_ids,
        assignees_ids: assignees_ids,
        view: socket.assigns.current_student_record_view,
        load_students_tags: true,
        preloads: [
          :tags,
          :status,
          :created_by_staff_member,
          :assignees,
          :students,
          [classes: :cycle]
        ],
        first: 50,
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

  defp assign_has_full_access(socket) do
    has_full_access =
      "students_records_full_access" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :has_full_access, has_full_access)
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, assign_student_record_id(socket, params)}

  defp assign_student_record_id(socket, %{"student_record" => "new"}) do
    # build new record initial fields based on current filters
    students_ids = Enum.map(socket.assigns.selected_students, & &1.id)

    classes =
      (socket.assigns.selected_classes ++
         Schools.list_classes_for_students_in_date(students_ids, Date.utc_today()))
      |> Enum.uniq_by(& &1.id)

    status_id =
      case socket.assigns.selected_student_record_statuses do
        [status] -> status.id
        _ -> nil
      end

    new_record_initial_fields =
      %{
        students: socket.assigns.selected_students,
        classes: classes,
        tags: socket.assigns.selected_student_record_tags,
        status_id: status_id
      }

    socket
    |> assign(:student_record_id, :new)
    |> assign(:new_record_initial_fields, new_record_initial_fields)
  end

  defp assign_student_record_id(socket, %{"student_record" => id}),
    do: assign(socket, :student_record_id, id)

  defp assign_student_record_id(socket, _params),
    do: assign(socket, :student_record_id, nil)

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

  def handle_event("remove_tag_filter", %{"id" => tag_id}, socket) do
    selected_tags_ids =
      socket.assigns.selected_student_record_tags_ids
      |> Enum.filter(&(&1 != tag_id))

    socket =
      socket
      |> assign(:selected_student_record_tags_ids, selected_tags_ids)
      |> save_profile_filters([:student_record_tags])
      |> assign_user_filters([:student_record_tags])
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("remove_student_tag_filter", %{"id" => tag_id}, socket) do
    selected_tags_ids =
      socket.assigns.selected_student_tags_ids
      |> Enum.filter(&(&1 != tag_id))

    socket =
      socket
      |> assign(:selected_student_tags_ids, selected_tags_ids)
      |> save_profile_filters([:student_tags])
      |> assign_user_filters([:student_tags])
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

  def handle_event("remove_assignee_filter", _, socket) do
    socket =
      socket
      |> assign(:selected_student_record_assignees_ids, [])
      |> save_profile_filters([:student_record_assignees])
      |> assign_user_filters([:student_record_assignees])
      |> stream_students_records(true)

    {:noreply, socket}
  end

  def handle_event("open_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, true)}

  def handle_event("close_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, false)}

  def handle_event("toggle_tag_filter", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_student_record_tags_ids,
        do: Enum.filter(socket.assigns.selected_student_record_tags_ids, &(&1 != id)),
        else: [id | socket.assigns.selected_student_record_tags_ids]

    socket =
      socket
      |> assign(:selected_student_record_tags_ids, selected_ids)

    {:noreply, socket}
  end

  def handle_event("toggle_student_tag_filter", %{"id" => id}, socket) do
    selected_ids =
      if id in socket.assigns.selected_student_tags_ids,
        do: Enum.filter(socket.assigns.selected_student_tags_ids, &(&1 != id)),
        else: [id | socket.assigns.selected_student_tags_ids]

    socket =
      socket
      |> assign(:selected_student_tags_ids, selected_ids)

    {:noreply, socket}
  end

  def handle_event("filter_by_tag", _, socket) do
    socket =
      socket
      |> save_profile_filters([:student_record_tags, :student_tags])
      |> assign_user_filters([:student_record_tags, :student_tags])
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

  def handle_event("open_assignee_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_assignee_search_modal, true)}

  def handle_event("close_assignee_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_assignee_search_modal, false)}

  def handle_event("set_view", %{"view" => view}, socket) do
    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{student_record_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_student_record_view, view)
          |> stream_students_records(true)

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
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

  def handle_info({StaffMemberSearchComponent, {:selected, staff_member}}, socket) do
    socket =
      socket
      |> assign(:selected_student_record_assignees_ids, [staff_member.id])
      |> save_profile_filters([:student_record_assignees])
      |> assign_user_filters([:student_record_assignees])
      |> stream_students_records(true)
      |> assign(:show_assignee_search_modal, false)

    {:noreply, socket}
  end

  def handle_info({StudentRecordOverlayComponent, {:created, student_record}}, socket) do
    socket =
      socket
      |> stream_insert(:students_records, student_record, at: 0)
      |> assign(:students_records_length, socket.assigns.students_records_length + 1)

    {:noreply, socket}
  end

  def handle_info({StudentRecordOverlayComponent, {:updated, student_record}}, socket) do
    socket =
      socket
      |> stream_insert(:students_records, student_record)

    {:noreply, socket}
  end

  def handle_info({StudentRecordOverlayComponent, {:deleted, student_record}}, socket) do
    socket =
      socket
      |> stream_delete(:students_records, student_record)
      |> assign(:students_records_length, socket.assigns.students_records_length - 1)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: socket
end
