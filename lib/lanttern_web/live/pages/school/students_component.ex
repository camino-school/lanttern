defmodule LantternWeb.SchoolLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.Schools.StudentFormOverlayComponent
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2, save_profile_filters: 2]
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-6 p-4">
        <div class="flex-1 flex flex-wrap items-center gap-2">
          <p>
            <%= ngettext(
              "Showing 1 student in",
              "Showing %{count} students in",
              @students_length
            ) %>
          </p>
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
          <% end %>
        </div>
        <.action
          :if={@is_school_manager}
          type="link"
          patch={~p"/school/students?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("Add student") %>
        </.action>
      </div>
      <div class="bg-white">
        <.data_grid
          id="students"
          stream={@streams.students}
          row_click={fn student -> JS.navigate(~p"/school/students/#{student}") end}
          show_empty_state_message={
            if @students_length == 0,
              do: gettext("No students found for selected filters.")
          }
          sticky_header_offset="7rem"
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
              <.badge :for={class <- student.classes}>
                <%= class_with_cycle(class, @current_user) %>
              </.badge>
            </div>
          </:col>
          <:action :let={student} :if={@is_school_manager}>
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
        <.data_grid
          :if={@no_class_students_length > 0}
          id="no-class-students"
          stream={@streams.no_class_students}
          row_click={fn student -> JS.navigate(~p"/school/students/#{student}") end}
          sticky_header_offset="7rem"
          class={["mt-10", if(@selected_classes_ids != [], do: "hidden")]}
        >
          <:col
            :let={student}
            label={
              ngettext(
                "1 student not linked to any class",
                "%{count} students not linked to any class",
                @no_class_students_length
              )
            }
          >
            <%= student.name %>
          </:col>
          <:action :let={student} :if={@is_school_manager}>
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
      </div>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="school-students-classes-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter students by class")}
        navigate={~p"/school/students"}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
      />
      <.live_component
        :if={@student}
        module={StudentFormOverlayComponent}
        id="student-form-overlay"
        student={@student}
        current_cycle={@current_user.current_profile.current_school_cycle}
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
    socket =
      delegate_navigation(socket,
        put_flash: {:info, gettext("Student created successfully")},
        push_navigate: [to: ~p"/school/students/#{student}"]
      )

    {:ok, socket}
  end

  def update(%{action: {StudentFormOverlayComponent, {:updated, student}}}, socket) do
    current_student_has_classes = length(socket.assigns.student.classes) > 0
    edited_student_has_classes = length(student.classes) > 0

    socket =
      case {current_student_has_classes, edited_student_has_classes} do
        {true, false} ->
          socket
          |> assign(:students_length, socket.assigns.students_length - 1)
          |> assign(:no_class_students_length, socket.assigns.no_class_students_length + 1)
          |> stream_delete(:students, student)
          |> stream_insert(:no_class_students, student)

        {false, true} ->
          socket
          |> assign(:no_class_students_length, socket.assigns.no_class_students_length - 1)
          |> stream_delete(:no_class_students, student)
          |> stream_updated_student_with_class(student, already_in_list: false)

        {true, true} ->
          stream_updated_student_with_class(socket, student, already_in_list: true)

        {false, false} ->
          stream_insert(socket, :no_class_students, student)
      end
      |> delegate_navigation(
        put_flash: {:info, gettext("Student updated successfully")},
        push_patch: [to: ~p"/school/students"]
      )

    {:ok, socket}
  end

  def update(%{action: {StudentFormOverlayComponent, {:deleted, student}}}, socket) do
    socket =
      if length(student.classes) > 0 do
        socket
        |> assign(:students_length, socket.assigns.students_length - 1)
        |> stream_delete(:students, student)
      else
        socket
        |> assign(:no_class_students_length, socket.assigns.no_class_students_length - 1)
        |> stream_delete(:no_class_students, student)
      end
      |> delegate_navigation(
        put_flash: {:info, gettext("Student deleted successfully")},
        push_patch: [to: ~p"/school/students"]
      )

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

  # this function handles the correct operation (insert or delete)
  # based on student classes and selected classes filter.
  # when calling this function, we already know that the student is linked to a class
  defp stream_updated_student_with_class(socket, student, already_in_list: already_in_list) do
    student_classes_ids = Enum.map(student.classes, & &1.id)

    is_inserting =
      case socket.assigns.selected_classes_ids do
        [] -> true
        ids -> Enum.any?(student_classes_ids, &(&1 in ids))
      end

    case {is_inserting, already_in_list} do
      {true, true} ->
        stream_insert(socket, :students, student)

      {true, false} ->
        socket
        |> stream_insert(:students, student)
        |> assign(:students_length, socket.assigns.students_length + 1)

      {false, true} ->
        socket
        |> stream_delete(:students, student)
        |> assign(:students_length, socket.assigns.students_length - 1)

      {false, false} ->
        socket
    end
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> apply_assign_classes_filter()
    |> stream_students()
    |> stream_no_class_students()
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

  defp stream_students(socket) do
    students =
      Schools.list_students(
        preloads: [classes: :cycle],
        school_id: socket.assigns.current_user.current_profile.school_id,
        classes_ids: socket.assigns.selected_classes_ids,
        only_in_some_class: true
      )

    socket
    |> stream(:students, students, reset: true)
    |> assign(:students_length, length(students))
  end

  defp stream_no_class_students(socket) do
    no_class_students =
      Schools.list_students(
        school_id: socket.assigns.current_user.current_profile.school_id,
        only_in_some_class: false
      )

    socket
    |> stream(:no_class_students, no_class_students, reset: true)
    |> assign(:no_class_students_length, length(no_class_students))
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
  def handle_event("remove_class_filter", %{"id" => class_id}, socket) do
    selected_classes_ids =
      socket.assigns.selected_classes_ids
      |> Enum.filter(&(&1 != class_id))

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> save_profile_filters([:classes])
      |> apply_assign_classes_filter()
      |> stream_students()

    {:noreply, socket}
  end
end
