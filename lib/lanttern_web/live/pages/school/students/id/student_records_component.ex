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

  alias Lanttern.Filters
  alias Lanttern.StudentsRecords
  alias Lanttern.Schools

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.Schools.StaffMemberSearchComponent
  alias LantternWeb.StudentsRecords.StudentRecordOverlayComponent
  import LantternWeb.StudentsRecordsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center gap-4 p-4">
        <div class="flex-1 flex flex-wrap items-center gap-4">
          <.icon name="hero-funnel-mini" class="text-ltrn-subtle" />
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
          <.badge
            :for={tag <- @selected_student_record_tags}
            color_map={tag}
            on_click={JS.exec("data-show", to: "#student-record-tag-filter-modal")}
            on_remove={JS.push("remove_tag_filter", value: %{"id" => tag.id}, target: @myself)}
          >
            <%= tag.name %>
          </.badge>
          <.action
            :if={@selected_student_record_tags == []}
            type="button"
            icon_name="hero-chevron-down-mini"
            phx-click={JS.exec("data-show", to: "#student-record-tag-filter-modal")}
          >
            <%= gettext("Tags") %>
          </.action>
          <%= if @selected_student_record_assignees == [] do %>
            <.action
              type="button"
              icon_name="hero-chevron-down-mini"
              phx-click={JS.push("open_assignee_search_modal", target: @myself)}
            >
              <%= gettext("Assignee") %>
            </.action>
          <% else %>
            <.badge
              :for={assignee <- @selected_student_record_assignees}
              on_remove={JS.push("remove_assignee_filter", target: @myself)}
              theme="staff"
            >
              <%= assignee.name %>
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
      <.responsive_container class="p-4">
        <div class="flex items-center justify-between gap-4 mb-4">
          <p>
            <%= ngettext(
              "Showing 1 result for selected filters",
              "Showing %{count} results for selected filters",
              @students_records_length
            ) %>
          </p>
          <div class="relative">
            <.action type="button" id="select-view-dropdown-button" icon_name="hero-eye-mini">
              <%= case @current_student_record_view do
                "all" -> gettext("All records")
                "open" -> gettext("Only open")
              end %>
            </.action>
            <.dropdown_menu
              id="select-view-dropdown"
              button_id="select-view-dropdown-button"
              z_index="30"
              position="right"
            >
              <:item
                text={gettext("All records, newest first")}
                on_click={JS.push("set_view", value: %{"view" => "all"}, target: @myself)}
              />
              <:item
                text={gettext("Only open, oldest first")}
                on_click={JS.push("set_view", value: %{"view" => "open"}, target: @myself)}
              />
            </.dropdown_menu>
          </div>
        </div>
        <.students_records_list
          id="students-records"
          stream={@streams.students_records}
          show_empty_state_message={@students_records_length == 0}
          student_navigate={
            fn
              student when student.id != @student.id ->
                ~p"/school/students/#{student}/student_records"

              _ ->
                nil
            end
          }
          staff_navigate={
            fn staff_member_id -> ~p"/school/staff/#{staff_member_id}/students_records" end
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
      <.selection_filter_modal
        id="student-record-status-filter-modal"
        title={gettext("Filter student records by status")}
        use_color_map_as_active
        items={@student_record_statuses}
        selected_items_ids={@selected_student_record_statuses_ids}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("filter_by_status", value: %{"id" => id}, target: @myself)
            |> JS.exec("data-cancel", to: "#student-record-status-filter-modal")
          end
        }
      />
      <.selection_filter_modal
        id="student-record-tag-filter-modal"
        title={gettext("Filter student records by tag")}
        use_color_map_as_active
        items={@student_record_tags}
        selected_items_ids={@selected_student_record_tags_ids}
        on_cancel={%JS{}}
        on_select={
          fn id ->
            JS.push("toggle_tag_filter", value: %{"id" => id}, target: @myself)
          end
        }
        on_save={
          JS.push("filter_by_tag", target: @myself)
          |> JS.exec("data-cancel", to: "#student-record-tag-filter-modal")
        }
      />
      <.modal
        :if={@show_assignee_search_modal}
        id="assignee-search-modal"
        show
        on_cancel={JS.push("close_assignee_search_modal", target: @myself)}
      >
        <h5 class="mb-10 font-display font-black text-xl">
          <%= gettext("Filter records by assignee") %>
        </h5>
        <form>
          <.live_component
            module={StaffMemberSearchComponent}
            id="assignee-search-modal-search"
            notify_component={@myself}
            label={gettext("Type the name of the assignee")}
            school_id={@current_user.current_profile.school_id}
          />
        </form>
      </.modal>
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
      |> assign(:show_assignee_search_modal, false)
      |> assign(:new_record_initial_fields, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StaffMemberSearchComponent, {:selected, staff_member}}}, socket) do
    socket =
      socket
      |> assign(:selected_student_record_assignees_ids, [staff_member.id])
      |> save_profile_filters([:student_record_assignees])
      |> assign_user_filters([:student_record_assignees])
      |> stream_students_records(true)
      |> assign(:show_assignee_search_modal, false)

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
      :student_record_tags,
      :student_record_statuses,
      :student_record_assignees,
      :student_record_view
    ])
    |> stream_students_records()
    |> assign_base_path()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_students_records(socket, reset \\ false) do
    %{
      current_user: %{current_profile: profile},
      selected_student_record_tags_ids: tags_ids,
      selected_student_record_statuses_ids: statuses_ids,
      selected_student_record_assignees_ids: assignees_ids,
      current_student_record_view: view
    } = socket.assigns

    {keyset, len} =
      if reset,
        do: {nil, 0},
        else: {socket.assigns[:keyset], socket.assigns[:students_records_length] || 0}

    page =
      StudentsRecords.list_students_records_page(
        check_profile_permissions: profile,
        students_ids: [socket.assigns.student.id],
        tags_ids: tags_ids,
        statuses_ids: statuses_ids,
        assignees_ids: assignees_ids,
        view: view,
        preloads: [
          :tags,
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
    base_path = ~p"/school/students/#{socket.assigns.student}/student_records"
    assign(socket, :base_path, base_path)
  end

  defp assign_student_record_id(%{assigns: %{params: %{"student_record" => "new"}}} = socket) do
    # build new record initial fields based on current filters
    students_ids = [socket.assigns.student.id]
    classes = Schools.list_classes_for_students_in_date(students_ids, Date.utc_today())

    tags_ids =
      case socket.assigns.selected_student_record_tags do
        tags when is_list(tags) -> Enum.map(tags, & &1.id)
        _ -> []
      end

    status_id =
      case socket.assigns.selected_student_record_statuses do
        [status] -> status.id
        _ -> nil
      end

    new_record_initial_fields =
      %{
        students: [socket.assigns.student],
        classes: classes,
        tags_ids: tags_ids,
        status_id: status_id
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

  def handle_event("filter_by_tag", _, socket) do
    socket =
      socket
      |> save_profile_filters([:student_record_tags])
      |> assign_user_filters([:student_record_tags])
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
end
