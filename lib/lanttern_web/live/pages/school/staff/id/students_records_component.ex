# I was trying to simply copy/paste the students records live code, and see where
# we would need to adjust to work here. Some improvements that I detected:
#
# the student search is inside a modal and form handled by the component.
# maybe we can create a student search overlay to simplify implementation
#
# there will be a lot of duplicated code... but a the same time, there are some
# changes to be implemented here (e.g. the current student is always part of the filter).
# I don't know if extracting the data grid + filter will work (I tried to do this, but
# I stopped as soon as I noticed I was adding a lot of complexity to customize to this context)

defmodule LantternWeb.StaffMemberLive.StudentsRecordsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Filters
  alias Lanttern.StudentsRecords
  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle

  # shared components
  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.StudentsRecords.StudentRecordOverlayComponent

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, assign_classes_filter: 2, save_profile_filters: 2]

  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import LantternWeb.StudentsRecordsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center gap-4 p-4">
        <div class="flex-1 flex flex-wrap items-center gap-6">
          <.icon name="hero-funnel-mini" class="text-ltrn-subtle" />
          <div class="relative">
            <.action type="button" id="select-view-dropdown-button" icon_name="hero-chevron-down-mini">
              <%= case @current_student_record_staff_member_view do
                "created_by" ->
                  gettext("Created by %{staff_member}", staff_member: @staff_member_first_name)

                "assigned_to" ->
                  gettext("Assigned to %{staff_member}", staff_member: @staff_member_first_name)
              end %>
            </.action>
            <.dropdown_menu
              id="select-view-dropdown"
              button_id="select-view-dropdown-button"
              z_index="30"
            >
              <:item
                text={gettext("Created by %{staff_member}", staff_member: @staff_member_first_name)}
                on_click={
                  JS.push("set_staff_member_view", value: %{"view" => "created_by"}, target: @myself)
                }
              />
              <:item
                text={gettext("Assigned to %{staff_member}", staff_member: @staff_member_first_name)}
                on_click={
                  JS.push("set_staff_member_view", value: %{"view" => "assigned_to"}, target: @myself)
                }
              />
            </.dropdown_menu>
          </div>
          <%= if @selected_students == [] do %>
            <.action
              type="button"
              icon_name="hero-chevron-down-mini"
              phx-click={JS.push("open_student_search_modal", target: @myself)}
            >
              <%= gettext("Student") %>
            </.action>
          <% else %>
            <.badge
              :for={student <- @selected_students}
              on_remove={JS.push("remove_student_filter", target: @myself)}
              theme="primary"
            >
              <%= student.name %>
            </.badge>
          <% end %>
          <%= if @selected_classes == [] do %>
            <.action
              type="button"
              icon_name="hero-chevron-down-mini"
              phx-click={JS.exec("data-show", to: "#students-records-classes-filters-overlay")}
            >
              <%= gettext("Classes") %>
            </.action>
          <% else %>
            <.badge
              :for={class <- @selected_classes}
              on_remove={JS.push("remove_class_filter", value: %{"id" => class.id}, target: @myself)}
              theme="primary"
            >
              <%= class_with_cycle(class, @current_user) %>
            </.badge>
          <% end %>
          <%= if @selected_student_record_statuses == [] do %>
            <.action
              type="button"
              icon_name="hero-chevron-down-mini"
              phx-click={JS.exec("data-show", to: "#student-record-status-filter-modal")}
            >
              <%= gettext("Status") %>
            </.action>
          <% else %>
            <.badge
              :for={status <- @selected_student_record_statuses}
              color_map={status}
              on_remove={JS.push("remove_status_filter", target: @myself)}
            >
              <%= status.name %>
            </.badge>
          <% end %>
          <%= if @selected_student_record_types == [] do %>
            <.action
              type="button"
              icon_name="hero-chevron-down-mini"
              phx-click={JS.exec("data-show", to: "#student-record-type-filter-modal")}
            >
              <%= gettext("Type") %>
            </.action>
          <% else %>
            <.badge
              :for={type <- @selected_student_record_types}
              color_map={type}
              on_remove={JS.push("remove_type_filter", target: @myself)}
            >
              <%= type.name %>
            </.badge>
          <% end %>
        </div>
        <.action
          type="link"
          patch={"#{@base_path}?student_record=new"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New student record") %>
        </.action>
      </.action_bar>
      <p :if={@students_records_length > 0} class="p-4 text-center">
        <%= ngettext(
          "Showing 1 result for selected filters",
          "Showing %{count} results for selected filters",
          @students_records_length
        ) %>
      </p>
      <.responsive_container class="p-4">
        <.students_records_list
          id="students-records"
          stream={@streams.students_records}
          show_empty_state_message={@students_records_length == 0}
          student_navigate={fn student -> ~p"/school/students/#{student}/student_records" end}
          staff_navigate={
            fn
              staff_member_id when staff_member_id != @staff_member.id ->
                ~p"/school/staff/#{staff_member_id}/students_records"

              _ ->
                nil
            end
          }
          details_patch={fn student_record -> "#{@base_path}?student_record=#{student_record.id}" end}
          current_user_or_cycle={@current_user}
        />
      </.responsive_container>
      <div :if={@has_next} class="flex justify-center pb-10">
        <.button theme="ghost" phx-click="load_more" phx-target={@myself} class="mt-6">
          <%= gettext("Load more records") %>
        </.button>
      </div>
      <.modal
        :if={@show_student_search_modal}
        id="student-search-modal"
        show
        on_cancel={JS.push("close_student_search_modal", target: @myself)}
      >
        <h5 class="mb-10 font-display font-black text-xl">
          <%= gettext("Filter records by student") %>
        </h5>
        <form>
          <.live_component
            module={StudentSearchComponent}
            id="student-search-modal-search"
            notify_component={@myself}
            label={gettext("Type the name of the student")}
            school_id={@current_user.current_profile.school_id}
          />
        </form>
      </.modal>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="students-records-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter students records by class")}
        navigate={~p"/school/staff/#{@staff_member.id}/students_records"}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
      <.single_selection_filter_modal
        id="student-record-status-filter-modal"
        title={gettext("Filter students records by status")}
        use_color_map_as_active
        items={@student_record_statuses}
        selected_item_id={Enum.at(@selected_student_record_statuses_ids, 0)}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("filter_by_status", value: %{"id" => id}, target: @myself)
            |> JS.exec("data-cancel", to: "#student-record-status-filter-modal")
          end
        }
      />
      <.single_selection_filter_modal
        id="student-record-type-filter-modal"
        title={gettext("Filter students records by type")}
        use_color_map_as_active
        items={@student_record_types}
        selected_item_id={Enum.at(@selected_student_record_types_ids, 0)}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("filter_by_type", value: %{"id" => id}, target: @myself)
            |> JS.exec("data-cancel", to: "#student-record-type-filter-modal")
          end
        }
      />
      <.live_component
        module={StudentRecordOverlayComponent}
        student_record_id={@student_record_id}
        id="student-record-overlay"
        current_user={@current_user}
        on_cancel={JS.patch(@base_path)}
        notify_component={@myself}
        new_record_initial_fields={@new_record_initial_fields}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:new_record_initial_fields, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
    socket =
      socket
      |> assign(:selected_students_ids, [student.id])
      |> save_profile_filters([:students])
      |> assign_user_filters([:students])
      |> stream_students_records(true)
      |> assign(:show_student_search_modal, false)

    {:ok, socket}
  end

  def update(%{action: {StudentRecordOverlayComponent, {:created, student_record}}}, socket) do
    socket =
      socket
      |> stream_insert(:students_records, student_record, at: 0)
      |> assign(:students_records_length, socket.assigns.students_records_length + 1)

    {:ok, socket}
  end

  def update(%{action: {StudentRecordOverlayComponent, {:updated, student_record}}}, socket) do
    socket =
      socket
      |> stream_insert(:students_records, student_record)

    {:ok, socket}
  end

  def update(%{action: {StudentRecordOverlayComponent, {:deleted, student_record}}}, socket) do
    socket =
      socket
      |> stream_delete(:students_records, student_record)
      |> assign(:students_records_length, socket.assigns.students_records_length - 1)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_student_record_id()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([
      :students,
      :student_record_types,
      :student_record_statuses,
      :student_record_staff_member_view
    ])
    |> apply_assign_classes_filter()
    |> stream_students_records()
    |> assign(:show_student_search_modal, false)
    |> assign_base_path()
    |> assign_staff_member_first_name()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

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
      selected_student_record_types_ids: types_ids,
      selected_student_record_statuses_ids: statuses_ids
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
        types_ids: types_ids,
        statuses_ids: statuses_ids,
        owner_id:
          if(socket.assigns.current_student_record_staff_member_view == "created_by",
            do: socket.assigns.staff_member.id
          ),
        assignees_ids:
          if(socket.assigns.current_student_record_staff_member_view == "assigned_to",
            do: [socket.assigns.staff_member.id]
          ),
        preloads: [
          :type,
          :status,
          :students,
          :created_by_staff_member,
          :assignees,
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

  defp assign_base_path(socket) do
    base_path = ~p"/school/staff/#{socket.assigns.staff_member}/students_records"
    assign(socket, :base_path, base_path)
  end

  defp assign_staff_member_first_name(socket) do
    staff_member_first_name =
      socket.assigns.staff_member.name
      |> String.split()
      |> List.first()

    assign(socket, :staff_member_first_name, staff_member_first_name)
  end

  defp assign_student_record_id(%{assigns: %{params: %{"student_record" => "new"}}} = socket) do
    # build new record initial fields based on current filters
    students_ids = Enum.map(socket.assigns.selected_students, & &1.id)

    classes =
      (socket.assigns.selected_classes ++
         Schools.list_classes_for_students_in_date(students_ids, Date.utc_today()))
      |> Enum.uniq_by(& &1.id)

    type_id =
      case socket.assigns.selected_student_record_types do
        [type] -> type.id
        _ -> nil
      end

    status_id =
      case socket.assigns.selected_student_record_statuses do
        [status] -> status.id
        _ -> nil
      end

    new_record_initial_fields =
      %{
        students: socket.assigns.selected_students,
        classes: classes,
        type_id: type_id,
        status_id: status_id,
        assignees: [socket.assigns.staff_member]
      }

    socket
    |> assign(:student_record_id, :new)
    |> assign(:new_record_initial_fields, new_record_initial_fields)
  end

  defp assign_student_record_id(%{assigns: %{params: %{"student_record" => id}}} = socket),
    do: assign(socket, :student_record_id, id)

  defp assign_student_record_id(socket),
    do: assign(socket, :student_record_id, nil)

  @impl true
  def handle_event("set_staff_member_view", %{"view" => view}, socket) do
    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{student_record_staff_member_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_student_record_staff_member_view, view)
          |> stream_students_records(true)

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

  def handle_event("open_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, true)}

  def handle_event("close_student_search_modal", _, socket),
    do: {:noreply, assign(socket, :show_student_search_modal, false)}

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
end
