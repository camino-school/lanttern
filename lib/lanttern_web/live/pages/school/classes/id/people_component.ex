defmodule LantternWeb.ClassLive.PeopleComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # shared
  alias LantternWeb.Schools.ClassStaffMemberFormOverlayComponent
  alias LantternWeb.Schools.StudentFormOverlayComponent
  import LantternWeb.SchoolsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <section id="staff-section">
        <div class="p-4">
          <h3 class="font-display font-bold text-lg">{gettext("Staff")}</h3>
          <div class="mt-2">
            {ngettext("1 staff member", "%{count} staff members", @staff_members_length)}
          </div>
        </div>
        <%= if @staff_members_length == 0 do %>
          <.empty_state class="px-4 py-10">
            {gettext("No staff members linked to this class")}
          </.empty_state>
        <% else %>
          <.fluid_grid id="staff-members" phx-update="stream" is_full_width class="p-4">
            <.staff_member_card
              :for={{dom_id, staff} <- @streams.staff_members}
              id={dom_id}
              staff_member={staff}
              navigate={~p"/school/staff/#{staff}/classes"}
              class_role={staff.class_role}
              on_edit={
                @is_school_manager &&
                  JS.push("edit_class_staff_member",
                    value: %{"id" => staff.class_staff_member_id},
                    target: @myself
                  )
              }
            />
          </.fluid_grid>
        <% end %>
      </section>

      <section id="students-section" class="mt-10">
        <div class="p-4">
          <h3 class="font-display font-bold text-lg">{gettext("Students")}</h3>
          <div class="flex justify-between gap-6 mt-2">
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
              patch={~p"/school/classes/#{@class}/people?new_student=true"}
              icon_name="hero-plus-circle-mini"
            >
              {gettext("Add student")}
            </.action>
          </div>
        </div>
        <.fluid_grid id="active-students" phx-update="stream" is_full_width class="p-4">
          <.student_card
            :for={{dom_id, student} <- @streams.students}
            id={dom_id}
            student={student}
            navigate={~p"/school/students/#{student}"}
            show_edit={@is_school_manager}
            edit_patch={~p"/school/classes/#{@class}/people?edit_student=#{student.id}"}
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
      </section>
      <.live_component
        :if={@class_staff_member}
        module={ClassStaffMemberFormOverlayComponent}
        id="edit-class-staff-member-overlay"
        class_staff_member={@class_staff_member}
        current_scope={@current_scope}
        on_cancel={JS.push("cancel_edit_class_staff_member", target: @myself)}
        notify_component={@myself}
      />
      <.live_component
        :if={@student}
        module={StudentFormOverlayComponent}
        id="student-form-overlay"
        student={@student}
        current_user={@current_user}
        current_scope={@current_scope}
        current_cycle={@current_user.current_profile.current_school_cycle}
        title={@student_overlay_title}
        on_cancel={JS.patch(~p"/school/classes/#{@class}/people")}
        close_path={~p"/school/classes/#{@class}/people"}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, initialized: false, class_staff_member: nil)}
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
        push_navigate: [to: ~p"/school/classes/#{socket.assigns.class}/people"]
      )

    {:ok, socket}
  end

  def update(
        %{action: {ClassStaffMemberFormOverlayComponent, {:updated, _updated_csm}}},
        socket
      ) do
    socket =
      socket
      |> stream_class_staff_members()
      |> assign(:class_staff_member, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Role updated successfully")})

    {:ok, socket}
  end

  def update(%{action: {ClassStaffMemberFormOverlayComponent, {:deleted, _csm}}}, socket) do
    socket =
      socket
      |> stream_class_staff_members()
      |> assign(:class_staff_member, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Removed from class successfully")})

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
    |> stream_class_staff_members()
    |> stream_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_class_staff_members(socket) do
    staff_members =
      Schools.list_class_staff_members(
        socket.assigns.current_scope,
        socket.assigns.class.id,
        load_email: true
      )

    socket
    |> stream(:staff_members, staff_members, reset: true)
    |> assign(:staff_members_length, length(staff_members))
  end

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
  def handle_event("edit_class_staff_member", %{"id" => id}, socket) do
    csmr = Schools.get_class_staff_member!(socket.assigns.current_scope, id, preloads: :class)
    {:noreply, assign(socket, :class_staff_member, csmr)}
  end

  def handle_event("cancel_edit_class_staff_member", _params, socket) do
    {:noreply, assign(socket, :class_staff_member, nil)}
  end

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
            |> push_navigate(to: ~p"/school/classes/#{socket.assigns.class}/people")

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
            |> push_navigate(to: ~p"/school/classes/#{socket.assigns.class}/people")

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete student"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid student"))}
    end
  end
end
