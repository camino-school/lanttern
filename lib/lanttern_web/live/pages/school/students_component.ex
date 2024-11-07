defmodule LantternWeb.SchoolLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Student
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, clear_profile_filters: 2]

  # shared components
  alias LantternWeb.Schools.StudentFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-6">
        <div class="flex items-end gap-6 mt-10 mb-4">
          <div class="flex-1">
            <p class="flex flex-wrap gap-2">
              <%= ngettext(
                "Showing 1 student in",
                "Showing %{count} students in",
                @students_length
              ) %>
              <%= if @selected_classes != [] do %>
                <.badge
                  :for={class <- @selected_classes}
                  on_remove={JS.push("remove_class_filter", target: @myself)}
                  theme="primary"
                >
                  <%= class.name %>
                </.badge>
              <% else %>
                <.badge><%= gettext("all classes") %></.badge>
              <% end %>
              <%!-- ,
            <%= if @selected_student_record_types != [] do %>
              <.badge
                :for={type <- @selected_student_record_types}
                color_map={type}
                on_remove={JS.push("remove_type_filter")}
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
                on_remove={JS.push("remove_status_filter")}
              >
                <%= status.name %>
              </.badge>
            <% else %>
              <.badge><%= gettext("all statuses") %></.badge>
            <% end %> --%>
            </p>
          </div>
          <.collection_action
            type="link"
            patch={~p"/school/students?new=true"}
            icon_name="hero-plus-circle"
          >
            <%= gettext("Add student") %>
          </.collection_action>
        </div>
      </.responsive_container>
      <.data_grid
        id="students"
        class="pb-10 mx-6"
        stream={@streams.students}
        row_click={fn student -> JS.navigate(~p"/school/students/#{student}") end}
        show_empty_state_message={
          if @students_length == 0,
            do: gettext("No students found for selected filters.")
        }
        sticky_header_offset="4rem"
      >
        <:col :let={student} label={gettext("Name")}>
          <%= student.name %>
        </:col>
        <:col
          :let={student}
          label={gettext("Classes")}
          template_col="max-content"
          on_filter={JS.exec("data-show", to: "#school-students-classes-filters-overlay")}
          filter_is_active={@selected_classes_ids != []}
        >
          <div class="flex flex-wrap gap-1">
            <.badge :for={class <- student.classes}><%= class.name %></.badge>
          </div>
        </:col>
        <:action :let={student}>
          <.button
            type="button"
            sr_text={gettext("Edit student")}
            icon_name="hero-pencil-mini"
            size="sm"
            theme="ghost"
            rounded
            phx-click={JS.patch(~p"/school/students?edit=#{student.id}")}
          />
        </:action>
      </.data_grid>

      <%!-- <div class="flex items-end justify-between gap-6 mt-10">
          <p class="font-display font-bold text-lg">
            <%= gettext("Showing students from") %><br />
            <.filter_text_button
              type={gettext("classes")}
              items={@selected_classes}
              on_click={JS.exec("data-show", to: "#school-students-classes-filters-overlay")}
            />
          </p>
          <div class="flex gap-4">
            <.collection_action
              :if={@is_school_manager}
              type="link"
              patch={~p"/school/classes?create_class=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Add class") %>
            </.collection_action>
            <.collection_action
              :if={@is_school_manager}
              type="link"
              patch={~p"/school/classes?create_student=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Add student") %>
            </.collection_action>
          </div>
        </div>
      </.responsive_container>
      <.responsive_grid id="school-classes" phx-update="stream" is_full_width>
        <.card_base
          :for={{dom_id, class} <- @streams.classes}
          id={dom_id}
          class="min-w-[16rem] sm:min-w-0 p-4"
        >
          <div class="flex items-center justify-between gap-4">
            <p class="font-display font-black"><%= class.name %> (<%= class.cycle.name %>)</p>
            <.button
              :if={@is_school_manager}
              type="link"
              icon_name="hero-pencil-mini"
              sr_text={gettext("Edit class")}
              rounded
              size="sm"
              theme="ghost"
              patch={~p"/school/classes?edit_class=#{class}"}
            />
          </div>
          <div class="flex flex-wrap gap-2 mt-4">
            <.badge :for={year <- class.years}>
              <%= year.name %>
            </.badge>
          </div>
          <%= if class.students != [] do %>
            <ol class="mt-4 text-sm leading-relaxed list-decimal list-inside">
              <li :for={std <- class.students} class="truncate">
                <.link
                  navigate={~p"/school/students/#{std}"}
                  class="hover:text-ltrn-subtle hover:underline"
                >
                  <%= std.name %>
                </.link>
              </li>
            </ol>
          <% else %>
            <.empty_state_simple class="mt-4">
              <%= gettext("No students in this class") %>
            </.empty_state_simple>
          <% end %>
        </.card_base>
      </.responsive_grid> --%>
      <.live_component
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="school-students-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter students by class")}
        filter_type={:classes}
        navigate={~p"/school/students"}
      />
      <%!-- <.live_component
        :if={@class}
        module={ClassFormOverlayComponent}
        id={:form}
        class={@class}
        title={@class_form_overlay_title}
        on_cancel={JS.patch(~p"/school/classes")}
        notify_parent
      /> --%>
      <.live_component
        :if={@student}
        module={StudentFormOverlayComponent}
        id="student-form-overlay"
        student={@student}
        title={@student_overlay_title}
        on_cancel={JS.patch(~p"/school/students")}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {StudentFormOverlayComponent, {:created, student}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Student created successfully")},
      push_navigate: [to: ~p"/school/students/#{student}"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(%{action: {StudentFormOverlayComponent, {:updated, student}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Student updated successfully")},
      push_patch: [to: ~p"/school/students"]
    ]

    socket =
      socket
      |> delegate_navigation(nav_opts)
      |> stream_insert(:students, student)

    {:ok, socket}
  end

  def update(%{action: {StudentFormOverlayComponent, {:deleted, student}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Student deleted successfully")},
      push_patch: [to: ~p"/school/students"]
    ]

    socket =
      socket
      |> delegate_navigation(nav_opts)
      |> stream_delete(:students, student)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_student()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:classes])
    |> stream_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_students(socket) do
    students =
      Schools.list_students(
        preloads: :classes,
        school_id: socket.assigns.current_user.current_profile.school_id,
        classes_ids: socket.assigns.selected_classes_ids
      )

    socket
    |> stream(:students, students, reset: true)
    |> assign(:students_length, length(students))
  end

  defp assign_student(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :student, nil)

  defp assign_student(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    student = %Student{
      school_id: socket.assigns.current_user.current_profile.school_id,
      classes: []
    }

    socket
    |> assign(:student, student)
    |> assign(:student_overlay_title, gettext("New student"))
  end

  defp assign_student(%{assigns: %{params: %{"edit" => student_id}}} = socket) do
    student = Schools.get_student(student_id, preloads: :classes)

    socket
    |> assign(:student, student)
    |> assign(:student_overlay_title, gettext("Edit student"))
  end

  defp assign_student(socket), do: assign(socket, :student, nil)

  @impl true
  def handle_event("remove_class_filter", _params, socket) do
    clear_profile_filters(socket.assigns.current_user, [:classes])

    socket =
      socket
      |> assign_user_filters([:classes])
      |> stream_students()

    {:noreply, socket}
  end
end
