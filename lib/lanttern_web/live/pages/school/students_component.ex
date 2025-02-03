defmodule LantternWeb.SchoolLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.Schools.StudentFormOverlayComponent
  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2, save_profile_filters: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between gap-6 p-4">
        <div class="flex gap-4">
          <.action
            type="button"
            phx-click={JS.exec("data-show", to: "#school-students-classes-filters-overlay")}
            icon_name="hero-chevron-down-mini"
          >
            <%= format_action_items_text(@selected_classes, gettext("All classes")) %>
          </.action>
          <%= ngettext("1 active student", "%{count} active students", @students_length) %>
          <.action type="link" theme="subtle" navigate={~p"/school/students/deactivated"}>
            <%= gettext("View deactivated students") %>
          </.action>
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
      <.fluid_grid id="students" phx-update="stream" is_full_width class="p-4">
        <.card_base
          :for={{dom_id, student} <- @streams.students}
          id={dom_id}
          class="flex items-center gap-4 p-4"
        >
          <.profile_picture
            picture_url={student.profile_picture_url}
            profile_name={student.name}
            size="lg"
          />
          <div class="min-w-0 flex-1">
            <.link navigate={~p"/school/students/#{student}"} class="font-bold hover:text-ltrn-subtle">
              <%= student.name %>
            </.link>
            <div class="flex flex-wrap gap-1 mt-2">
              <.badge :for={class <- student.classes}><%= class.name %></.badge>
            </div>
            <div
              :if={student.email}
              class="mt-2 text-xs text-ltrn-subtle truncate"
              title={student.email}
            >
              <%= student.email %>
            </div>
          </div>
          <.button
            :if={@is_school_manager}
            type="link"
            icon_name="hero-pencil-mini"
            sr_text={gettext("Edit student")}
            rounded
            size="sm"
            theme="ghost"
            patch={~p"/school/students?edit=#{student.id}"}
          />
        </.card_base>
      </.fluid_grid>
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

  def update(%{action: {StudentFormOverlayComponent, {action, _staff_member}}}, socket)
      when action in [:updated, :deactivated] do
    message =
      case action do
        :updated -> gettext("Student updated successfully")
        :deactivated -> gettext("Student deactivated successfully")
      end

    socket =
      socket
      |> delegate_navigation(
        put_flash: {:info, message},
        push_navigate: [to: ~p"/school/students"]
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

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> apply_assign_classes_filter()
    |> stream_students()
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
    cycle_id =
      socket.assigns.current_user.current_profile.current_school_cycle.id

    students =
      Schools.list_students(
        school_id: socket.assigns.current_user.current_profile.school_id,
        load_email: true,
        classes_ids: socket.assigns.selected_classes_ids,
        preload_classes_from_cycle_id: cycle_id,
        load_profile_picture_from_cycle_id: cycle_id,
        only_active: true
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
