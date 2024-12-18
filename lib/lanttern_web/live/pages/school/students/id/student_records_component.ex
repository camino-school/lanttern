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

defmodule LantternWeb.StudentLive.StudentRecordsComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.Schools.Cycle

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, assign_classes_filter: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.StudentsRecords.StudentRecordOverlayComponent
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import LantternWeb.StudentsRecordsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center gap-4 p-4">
        <p class="flex-1 flex flex-wrap gap-2">
          <%= ngettext(
            "Showing 1 result for",
            "Showing %{count} results for",
            @students_records_length
          ) %>
          <%= if @selected_students != [] do %>
            <.badge
              :for={student <- @selected_students}
              on_remove={JS.push("remove_student_filter", target: @myself)}
              theme="primary"
            >
              <%= student.name %>
            </.badge>
          <% else %>
            <.badge><%= gettext("all students") %></.badge>
          <% end %>
          ,
          <%= if @selected_classes != [] do %>
            <.badge
              :for={class <- @selected_classes}
              on_remove={JS.push("remove_class_filter", value: %{"id" => class.id}, target: @myself)}
              theme="primary"
            >
              <%= class_with_cycle(class, @current_user) %>
            </.badge>
          <% else %>
            <.badge><%= gettext("all classes") %></.badge>
          <% end %>,
          <%= if @selected_student_record_types != [] do %>
            <.badge
              :for={type <- @selected_student_record_types}
              color_map={type}
              on_remove={JS.push("remove_type_filter", target: @myself)}
            >
              <%= type.name %>
            </.badge>
          <% else %>
            <.badge><%= gettext("all student record types") %></.badge>
          <% end %>
          <%= gettext("and") %>
          <%= if @selected_student_record_statuses != [] do %>
            <.badge
              :for={status <- @selected_student_record_statuses}
              color_map={status}
              on_remove={JS.push("remove_status_filter", target: @myself)}
            >
              <%= status.name %>
            </.badge>
          <% else %>
            <.badge><%= gettext("all statuses") %></.badge>
          <% end %>
        </p>
        <.action
          type="link"
          patch={"#{@base_path}?student_record=new"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New student record") %>
        </.action>
      </.action_bar>
      <.students_records_data_grid
        id="students-records"
        stream={@streams.students_records}
        show_empty_state_message={@students_records_length == 0}
        row_click={
          fn student_record ->
            JS.patch("#{@base_path}?student_record=#{student_record.id}")
          end
        }
        is_students_filter_active={@selected_students_ids != []}
        on_students_filter={JS.push("open_student_search_modal", target: @myself)}
        is_classes_filter_active={@selected_classes_ids != []}
        on_classes_filter={JS.exec("data-show", to: "#student-records-classes-filters-overlay")}
        is_type_filter_active={@selected_student_record_types_ids != []}
        on_type_filter={JS.exec("data-show", to: "#student-record-types-filter-modal")}
        is_status_filter_active={@selected_student_record_statuses_ids != []}
        on_status_filter={JS.exec("data-show", to: "#student-record-statuses-filter-modal")}
        current_user_or_cycle={@current_user}
      />
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
          />
        </form>
      </.modal>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="student-records-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter students records by class")}
        navigate={@base_path}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
      <.single_selection_filter_modal
        id="student-record-types-filter-modal"
        title={gettext("Filter students records by type")}
        use_color_map_as_active
        items={@student_record_types}
        selected_item_id={Enum.at(@selected_student_record_types_ids, 0)}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("filter_by_type", value: %{"id" => id})
            |> JS.exec("data-cancel", to: "#student-record-types-filter-modal")
          end
        }
      />
      <.single_selection_filter_modal
        id="student-record-statuses-filter-modal"
        title={gettext("Filter students records by status")}
        use_color_map_as_active
        items={@student_record_statuses}
        selected_item_id={Enum.at(@selected_student_record_statuses_ids, 0)}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("filter_by_status", value: %{"id" => id})
            |> JS.exec("data-cancel", to: "#student-record-statuses-filter-modal")
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
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

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
    |> assign_user_filters([:students, :student_record_types, :student_record_statuses])
    |> apply_assign_classes_filter()
    |> stream_students_records()
    |> assign(:show_student_search_modal, false)
    |> assign_base_path()
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

  defp assign_base_path(socket) do
    base_path = ~p"/school/students/#{socket.assigns.student}/student_records"
    assign(socket, :base_path, base_path)
  end

  defp assign_student_record_id(%{assigns: %{params: %{"student_record" => "new"}}} = socket),
    do: assign(socket, :student_record_id, :new)

  defp assign_student_record_id(%{assigns: %{params: %{"student_record" => id}}} = socket),
    do: assign(socket, :student_record_id, id)

  defp assign_student_record_id(socket),
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
end
