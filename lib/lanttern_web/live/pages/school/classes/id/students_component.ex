defmodule LantternWeb.ClassLive.StudentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.Schools.StudentFormOverlayComponent
  import LantternWeb.SchoolsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between gap-6 p-4">
        <div class="flex gap-4">
          {ngettext("1 active student", "%{count} active students", @students_length)}
          <span class="text-ltrn-subtle">
            {ngettext(
              "1 deactivated student",
              "%{count} deactivated students",
              @deactivated_students_length
            )}
          </span>
        </div>
        <.action
          :if={@is_school_manager}
          type="link"
          patch={~p"/school/classes/#{@class}/students?new_student=true"}
          icon_name="hero-plus-circle-mini"
        >
          {gettext("Add student")}
        </.action>
      </div>
      <.fluid_grid id="active-students" phx-update="stream" is_full_width class="p-4">
        <.student_card
          :for={{dom_id, student} <- @streams.students}
          id={dom_id}
          student={student}
          navigate={~p"/school/students/#{student}"}
          show_edit={@is_school_manager}
          edit_patch={~p"/school/classes/#{@class}/students?edit_student=#{student.id}"}
        />
        <.deactivated_student_card
          :for={{dom_id, student} <- @streams.deactivated_students}
          id={dom_id}
          student={student}
          navigate={~p"/school/students/#{student}"}
          show_actions={@is_school_manager}
          on_reactivate={JS.push("reactivate", value: %{"id" => student.id}, target: @myself)}
          on_delete={JS.push("delete", value: %{"id" => student.id}, target: @myself)}
        />
      </.fluid_grid>
      <.live_component
        :if={@student}
        module={StudentFormOverlayComponent}
        id="student-form-overlay"
        student={@student}
        current_cycle={@current_user.current_profile.current_school_cycle}
        title={@student_overlay_title}
        on_cancel={JS.patch(~p"/school/classes/#{@class}/students")}
        close_path={~p"/school/classes/#{@class}/students"}
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
  def update(%{action: {StudentFormOverlayComponent, {action, _staff_member}}}, socket)
      when action in [:created, :updated, :deactivated] do
    message =
      case action do
        :created -> gettext("Student created successfully")
        :updated -> gettext("Student updated successfully")
        :deactivated -> gettext("Student deactivated successfully")
      end

    socket =
      socket
      |> delegate_navigation(
        put_flash: {:info, message},
        push_navigate: [to: ~p"/school/classes/#{socket.assigns.class}/students"]
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
    |> stream_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_students(socket) do
    cycle_id =
      socket.assigns.current_user.current_profile.current_school_cycle.id

    all_students =
      Schools.list_students(
        school_id: socket.assigns.current_user.current_profile.school_id,
        load_email: true,
        classes_ids: [socket.assigns.class.id],
        load_profile_picture_from_cycle_id: cycle_id,
        preloads: :tags
      )

    students =
      all_students
      |> Enum.filter(fn student ->
        is_nil(student.deactivated_at)
      end)

    deactivated_students =
      all_students
      |> Enum.filter(fn student ->
        not is_nil(student.deactivated_at)
      end)

    socket
    |> stream(:students, students, reset: true)
    |> assign(:students_length, length(students))
    |> stream(:deactivated_students, deactivated_students, reset: true)
    |> assign(:deactivated_students_length, length(deactivated_students))
    |> assign(:students_ids, Enum.map(all_students, & &1.id))
  end

  defp assign_student(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :student, nil)

  defp assign_student(%{assigns: %{params: %{"new_student" => "true"}}} = socket) do
    student = %Student{
      school_id: socket.assigns.current_user.current_profile.school_id,
      classes: [socket.assigns.class]
    }

    socket
    |> assign(:student, student)
    |> assign(:student_overlay_title, gettext("New student"))
  end

  defp assign_student(%{assigns: %{params: %{"edit_student" => student_id}}} = socket) do
    student = Schools.get_student(student_id, preloads: :classes, load_email: true)

    socket
    |> assign(:student, student)
    |> assign(:student_overlay_title, gettext("Edit student"))
  end

  defp assign_student(socket), do: assign(socket, :student, nil)

  # event handlers

  @impl true
  def handle_event("reactivate", %{"id" => id}, socket) do
    if id in socket.assigns.students_ids do
      student = Schools.get_student!(id)

      case Schools.reactivate_student(student) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{student} reactivated", student: student.name)
            )
            |> push_navigate(to: ~p"/school/classes/#{socket.assigns.class}/students")

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to reactivate student"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid student"))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    if id in socket.assigns.students_ids do
      student = Schools.get_student!(id)

      case Schools.delete_student(student) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{student} deleted", student: student.name)
            )
            |> push_navigate(to: ~p"/school/classes/#{socket.assigns.class}/students")

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete student"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid student"))}
    end
  end
end
