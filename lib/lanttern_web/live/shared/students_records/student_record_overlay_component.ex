defmodule LantternWeb.StudentsRecords.StudentRecordOverlayComponent do
  @moduledoc """
  Renders an overlay with `StudentRecord` details and editing support
  """

  alias Lanttern.Repo
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.Schools
  alias Lanttern.Schools.StaffMember

  # shared

  alias LantternWeb.Schools.StaffMemberSearchComponent
  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.Schools.ClassesFieldComponent
  import LantternWeb.DateTimeHelpers, only: [format_local!: 1]
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import LantternWeb.StudentsRecordsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal :if={@student_record_id} id={@id} show on_cancel={@on_cancel}>
        <h5 class="mb-10 font-display font-black text-xl">
          <%= if @is_editing,
            do: gettext("Edit student record"),
            else: Map.get(@student_record || %{}, :name, gettext("Student record detail")) %>
        </h5>
        <%= if @is_editing do %>
          <.scroll_to_top overlay_id={@id} id="form-scroll-top" />
          <.form
            :if={@is_editing}
            id="student-record-form"
            for={@form}
            phx-change="validate"
            phx-submit="save"
            phx-target={@myself}
          >
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              <%= gettext("Oops, something went wrong! Please check the errors below.") %>
            </.error_block>
            <.input
              field={@form[:name]}
              type="text"
              label={gettext("Name")}
              class="mb-6"
              phx-debounce="1500"
              show_optional
            />
            <div class="flex gap-6 mb-6">
              <.input
                field={@form[:date]}
                type="date"
                label={gettext("Date")}
                class="flex-1"
                phx-debounce="1500"
              />
              <.input
                field={@form[:time]}
                type="time"
                label={gettext("Time")}
                class="flex-1"
                show_optional
                phx-debounce="1500"
              />
            </div>
            <div class="mb-6">
              <.label><%= gettext("Status") %></.label>
              <.badge_button_picker
                id="student-record-status-select"
                on_select={&JS.push("select_status", value: %{"id" => &1}, target: @myself)}
                items={@statuses}
                selected_ids={[@selected_status_id]}
                use_color_map_as_active
              />
              <div :if={@form.source.action in [:insert, :update]}>
                <.error :for={{msg, _} <- @form[:status_id].errors}><%= msg %></.error>
              </div>
            </div>
            <div class="mb-6">
              <.label><%= gettext("Tags") %></.label>
              <.badge_button_picker
                id="student-record-tag-select"
                on_select={
                  &(JS.push("select_tag", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-record-form"))
                }
                items={@tags}
                selected_ids={@selected_tags_ids}
                use_color_map_as_active
              />
              <div :if={@form.source.action in [:insert, :update]}>
                <.error :for={{msg, _} <- @form[:tags_ids].errors}><%= msg %></.error>
              </div>
            </div>
            <div class="mb-6">
              <.live_component
                module={StudentSearchComponent}
                id={"#{@id}-student-search"}
                notify_component={@myself}
                label={gettext("Students")}
                refocus_on_select="true"
                school_id={@current_user.current_profile.school_id}
              />
              <div :if={@selected_students != []} class="flex flex-wrap gap-2 mt-2">
                <.person_badge
                  :for={student <- @selected_students}
                  person={student}
                  theme="cyan"
                  on_remove={JS.push("remove_student", value: %{"id" => student.id}, target: @myself)}
                />
              </div>
              <div :if={@form.source.action in [:insert, :update]}>
                <.error :for={{msg, _} <- @form[:students_ids].errors}><%= msg %></.error>
              </div>
            </div>
            <.live_component
              module={ClassesFieldComponent}
              id="student-record-form-classes-picker"
              label={gettext("Classes")}
              school_id={@student_record.school_id}
              current_cycle={@current_user.current_profile.current_school_cycle}
              selected_classes_ids={@selected_classes_ids}
              notify_component={@myself}
              class="mb-6"
            />
            <.input
              field={@form[:description]}
              type="textarea"
              label={gettext("Description")}
              class="mb-1"
              phx-debounce="1500"
            />
            <.markdown_supported class="mb-6" />
            <div class="p-4 rounded-sm mb-6 bg-ltrn-staff-lightest">
              <p class="mb-6 font-bold text-ltrn-staff-dark">
                <%= gettext("Internal student record tracking") %>
              </p>
              <div class="mb-6">
                <.live_component
                  module={StaffMemberSearchComponent}
                  id="staff-member-search"
                  notify_component={@myself}
                  label={gettext("Assignees")}
                  refocus_on_select="true"
                  school_id={@current_user.current_profile.school_id}
                />
                <div :if={@selected_assignees != []} class="flex flex-wrap gap-2 mt-2">
                  <.person_badge
                    :for={assignee <- @selected_assignees}
                    person={assignee}
                    theme="staff"
                    on_remove={
                      JS.push("remove_assignee", value: %{"id" => assignee.id}, target: @myself)
                    }
                  />
                </div>
                <div :if={@form.source.action in [:insert, :update]}>
                  <.error :for={{msg, _} <- @form[:assignees_ids].errors}><%= msg %></.error>
                </div>
              </div>
              <.input
                field={@form[:internal_notes]}
                type="textarea"
                label={gettext("Internal notes")}
                class="mb-1"
                phx-debounce="1500"
              />
              <.markdown_supported class="mb-6" />
              <div class="p-2 rounded-sm mt-10 -mx-2 -mb-2 bg-ltrn-staff-lighter">
                <.input
                  field={@form[:shared_with_school]}
                  type="toggle"
                  theme="staff"
                  label={gettext("Visible to all school staff")}
                />
              </div>
            </div>
            <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
              <%= gettext("Oops, something went wrong! Please check the errors below.") %>
            </.error_block>
            <div class="flex items-center justify-end gap-6">
              <.action
                type="button"
                theme="subtle"
                size="md"
                phx-click={
                  if(is_nil(@student_record.id), do: @on_cancel, else: %JS{})
                  |> JS.push("cancel_edit", target: @myself)
                }
              >
                <%= gettext("Cancel") %>
              </.action>
              <.action type="submit" theme="primary" size="md" icon_name="hero-check">
                <%= gettext("Save") %>
              </.action>
            </div>
          </.form>
        <% else %>
          <.scroll_to_top overlay_id={@id} id="details-scroll-top" />
          <%= if @student_record do %>
            <div class="pb-6 border-b border-ltrn-light">
              <div class="flex items-center gap-4">
                <div class="flex items-center gap-2 font-bold text-ltrn-subtle">
                  <.icon name="hero-hashtag-mini" class="w-5 h-5 text-ltrn-subtle" />
                  <%= @student_record.id %>
                </div>
                <div class="flex items-center gap-2">
                  <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
                  <%= Timex.format!(@student_record.date, "{Mfull} {0D}, {YYYY}") %>
                </div>
                <div :if={@student_record.time} class="flex items-center gap-2">
                  <.icon name="hero-clock-mini" class="w-5 h-5 text-ltrn-subtle" />
                  <%= @student_record.time %>
                </div>
              </div>
              <div class="md:flex items-center gap-4 mt-4">
                <div class="flex items-center gap-2">
                  <span><%= gettext("Status") %>:</span>
                  <.status_badge status={@student_record.status} />
                </div>
                <div class="flex items-center gap-2 mt-4 md:mt-0">
                  <span><%= gettext("Tags") %>:</span>
                  <div class="flex flex-wrap gap-2">
                    <.badge :for={tag <- @student_record.tags} color_map={tag}>
                      <%= tag.name %>
                    </.badge>
                  </div>
                </div>
              </div>
            </div>
            <div class="md:flex items-start gap-4 mt-6">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <.icon name="hero-user-group-mini" class="text-ltrn-subtle" />
                  <p><%= gettext("Students") %></p>
                </div>
                <div class="flex flex-wrap gap-2 mt-4">
                  <.person_badge
                    :for={student <- @student_record.students}
                    person={student}
                    theme="cyan"
                    size="sm"
                    id={"student-#{student.id}"}
                    navigate={~p"/school/students/#{student.id}/student_records"}
                  />
                </div>
              </div>
              <div :if={@student_record.classes != []} class="flex-1 mt-4 md:mt-0">
                <div class="flex items-center gap-2">
                  <.icon name="hero-rectangle-group-mini" class="text-ltrn-subtle" />
                  <p><%= gettext("Classes") %></p>
                </div>
                <div class="flex flex-wrap gap-2 mt-4">
                  <.badge :for={class <- @student_record.classes} id={"class-#{class.id}"}>
                    <%= class_with_cycle(class, @current_user) %>
                  </.badge>
                </div>
              </div>
            </div>
            <h3 class="mt-10 font-display font-black text-2xl">
              <%= gettext("Record description") %>
            </h3>
            <.markdown text={@student_record.description} class="mt-6" />
            <div class="p-4 rounded-sm mt-10 bg-ltrn-staff-lightest">
              <p class="mb-6 font-bold text-ltrn-staff-dark">
                <%= gettext("Internal student record tracking") %>
              </p>
              <div class="flex items-center gap-2">
                <span class="text-ltrn-subtle"><%= gettext("Created by") %></span>
                <.person_badge
                  person={@student_record.created_by_staff_member}
                  theme="staff"
                  navigate={
                    ~p"/school/staff/#{@student_record.created_by_staff_member}/students_records"
                  }
                />
              </div>
              <div :if={@student_record.assignees != []} class="flex items-center gap-2 mt-4">
                <span class="text-ltrn-subtle"><%= gettext("Assigned to") %></span>
                <div class="flex flex-wrap items-center gap-2">
                  <.person_badge
                    :for={assignee <- @student_record.assignees}
                    person={assignee}
                    theme="staff"
                    navigate={~p"/school/staff/#{assignee}/students_records"}
                  />
                </div>
              </div>
              <div :if={@student_record.internal_notes} class="mt-10">
                <h3 class="font-display font-black text-xl text-ltrn-staff-dark">
                  <%= gettext("Internal notes") %>
                </h3>
                <.markdown text={@student_record.internal_notes} class="mt-6" />
              </div>
              <div
                class="inline-flex items-center gap-2 p-2 rounded-full mt-4 text-xs"
                style={create_color_map_style(@student_record.status)}
              >
                <.closed_status_info student_record={@student_record} />
              </div>
              <div
                :if={@student_record.shared_with_school}
                class="flex items-center gap-2 p-2 rounded-sm mt-4 text-ltrn-staff-dark bg-ltrn-staff-lighter"
              >
                <.icon name="hero-globe-americas-mini" />
                <%= gettext("This record is visible to all school staff") %>
              </div>
            </div>
            <%= if @is_deleted do %>
              <.error_block class="mt-10">
                <%= gettext("This record was deleted") %>
              </.error_block>
            <% else %>
              <div
                :if={@has_delete_permissions || @has_update_permissions}
                class="flex justify-between gap-4 mt-10"
              >
                <div>
                  <.action
                    :if={@has_delete_permissions}
                    type="button"
                    icon_name="hero-x-circle-mini"
                    phx-click={JS.push("delete", target: @myself)}
                    theme="subtle"
                    data-confirm={gettext("Are you sure?")}
                  >
                    <%= gettext("Delete") %>
                  </.action>
                </div>
                <.action
                  :if={@has_update_permissions}
                  type="button"
                  icon_name="hero-pencil-mini"
                  phx-click={JS.push("edit", target: @myself)}
                >
                  <%= gettext("Edit record") %>
                </.action>
              </div>
            <% end %>
          <% else %>
            <.empty_state><%= gettext("Student record not found") %></.empty_state>
          <% end %>
        <% end %>
      </.modal>
    </div>
    """
  end

  attr :student_record, StudentRecord, required: true
  attr :class, :any, default: nil

  defp closed_status_info(
         %{student_record: %{status: %{is_closed: true}, closed_at: nil}} = assigns
       ) do
    ~H"""
    <.icon name="hero-check-circle-mini" />
    <p><%= gettext("Closed on creation") %></p>
    """
  end

  defp closed_status_info(
         %{
           student_record: %{
             status: %{is_closed: true},
             closed_at: %DateTime{},
             closed_by_staff_member: %StaffMember{},
             duration_until_close: %Duration{}
           }
         } = assigns
       ) do
    ~H"""
    <.icon name="hero-check-circle-mini" />
    <%= gettext("Closed by %{staff_member} on %{datetime} (%{days} days since creation)",
      staff_member: @student_record.closed_by_staff_member.name,
      datetime: format_local!(@student_record.closed_at),
      days: @student_record.duration_until_close.day
    ) %>
    """
  end

  defp closed_status_info(assigns) do
    days_since_creation =
      DateTime.diff(
        DateTime.utc_now(),
        DateTime.from_naive!(assigns.student_record.inserted_at, "Etc/UTC"),
        :day
      )

    assigns = assign(assigns, :days_since_creation, days_since_creation)

    ~H"""
    <%= gettext("Created on %{datetime}", datetime: format_local!(@student_record.inserted_at)) %>
    <%= ngettext("(Open for 1 day)", "(Open for %{count} days)", @days_since_creation) %>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:is_editing, false)
      |> assign(:is_deleted, false)
      |> assign(:form_initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
    selected_students =
      (socket.assigns.selected_students ++ [student])
      |> Enum.uniq()

    selected_students_ids = selected_students |> Enum.map(& &1.id)

    # also add selected classes ids if possible
    student_classes_ids =
      Schools.list_classes_for_students_in_date([student.id], socket.assigns.student_record.date)
      |> Enum.map(& &1.id)

    selected_classes_ids =
      (socket.assigns.selected_classes_ids ++ student_classes_ids)
      |> Enum.uniq()

    # basically a manual "validate" event to update students ids
    params =
      socket.assigns.form.params
      |> Map.put("students_ids", selected_students_ids)

    form =
      socket.assigns.student_record
      |> StudentsRecords.change_student_record(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> assign(:selected_students, selected_students)
      |> assign(:selected_students_ids, selected_students_ids)
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> assign(:form, form)

    {:ok, socket}
  end

  def update(
        %{action: {ClassesFieldComponent, {:changed, selected_classes_ids}}},
        socket
      ),
      do: {:ok, assign(socket, :selected_classes_ids, selected_classes_ids)}

  def update(%{action: {StaffMemberSearchComponent, {:selected, assignee}}}, socket) do
    selected_assignees =
      (socket.assigns.selected_assignees ++ [assignee])
      |> Enum.uniq()

    selected_assignees_ids = selected_assignees |> Enum.map(& &1.id)

    # basically a manual "validate" event to update assignees ids
    params =
      socket.assigns.form.params
      |> Map.put("assignees_ids", selected_assignees_ids)

    form =
      socket.assigns.student_record
      |> StudentsRecords.change_student_record(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> assign(:selected_assignees, selected_assignees)
      |> assign(:selected_assignees_ids, selected_assignees_ids)
      |> assign(:form, form)

    {:ok, socket}
  end

  def update(%{student_record_id: nil} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:student_record, nil)
      |> assign(:is_editing, false)
      |> assign(:is_deleted, false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_student_record()
      |> assign_has_update_permissions()
      |> assign_has_delete_permissions()

    {:ok, socket}
  end

  defp assign_student_record(%{assigns: %{student_record_id: :new}} = socket) do
    student_record =
      %StudentRecord{
        school_id: socket.assigns.current_user.current_profile.school_id,
        students: [],
        classes: [],
        status: nil,
        tags: [],
        assignees: [],
        date: Date.utc_today()
      }
      |> struct(Map.get(socket.assigns, :new_record_initial_fields, %{}))

    socket
    |> assign(:student_record, student_record)
    |> initialize_form()
    |> assign_form()
    |> assign(:is_editing, true)
  end

  defp assign_student_record(%{assigns: %{student_record_id: id}} = socket) do
    student_record =
      StudentsRecords.get_student_record(id,
        check_profile_permissions: socket.assigns.current_user.current_profile,
        preloads: [
          :students,
          :status,
          :tags,
          :created_by_staff_member,
          :closed_by_staff_member,
          :assignees,
          [classes: :cycle]
        ]
      )
      |> case do
        nil ->
          nil

        student_record ->
          # prevent user from viewing students records from other schools
          if student_record.school_id == socket.assigns.current_user.current_profile.school_id,
            do: student_record
      end

    assign(socket, :student_record, student_record)
  end

  defp assign_student_record(socket),
    do: assign(socket, :student_record, nil)

  defp assign_form(socket) do
    # we'll need students/classes/assignees relationships for changeset
    student_record =
      socket.assigns.student_record
      |> Repo.preload([
        :students_relationships,
        :classes_relationships,
        :assignees_relationships,
        :tags_relationships
      ])

    changeset = StudentsRecords.change_student_record(student_record)

    socket
    |> assign(:student_record, student_record)
    |> assign(:form, to_form(changeset))
    |> assign(:selected_tags_ids, Enum.map(student_record.tags, & &1.id))
    |> assign(:selected_status_id, student_record.status_id)
    |> assign_selected_students()
    |> assign_selected_classes_ids()
    |> assign_selected_assignees()
  end

  defp assign_selected_students(socket) do
    selected_students = socket.assigns.student_record.students
    selected_students_ids = selected_students |> Enum.map(& &1.id)

    socket
    |> assign(:selected_students, selected_students)
    |> assign(:selected_students_ids, selected_students_ids)
  end

  defp assign_selected_classes_ids(socket) do
    selected_classes_ids =
      socket.assigns.student_record.classes
      |> Enum.map(& &1.id)

    assign(socket, :selected_classes_ids, selected_classes_ids)
  end

  defp assign_selected_assignees(socket) do
    selected_assignees = socket.assigns.student_record.assignees
    selected_assignees_ids = selected_assignees |> Enum.map(& &1.id)

    socket
    |> assign(:selected_assignees, selected_assignees)
    |> assign(:selected_assignees_ids, selected_assignees_ids)
  end

  defp assign_has_update_permissions(socket) do
    has_update_permissions =
      StudentsRecords.profile_has_student_record_update_permissions?(
        socket.assigns.student_record,
        socket.assigns.current_user.current_profile
      )

    assign(socket, :has_update_permissions, has_update_permissions)
  end

  defp assign_has_delete_permissions(socket) do
    has_delete_permissions =
      StudentsRecords.profile_has_student_record_delete_permissions?(
        socket.assigns.student_record,
        socket.assigns.current_user.current_profile
      )

    assign(socket, :has_delete_permissions, has_delete_permissions)
  end

  # event handlers

  @impl true
  def handle_event("edit", _, socket) do
    socket =
      socket
      |> initialize_form()
      |> assign_form()
      |> assign(:is_editing, true)

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("remove_student", %{"id" => id}, socket) do
    selected_students =
      socket.assigns.selected_students
      |> Enum.filter(&(&1.id != id))

    selected_students_ids = selected_students |> Enum.map(& &1.id)

    socket =
      socket
      |> assign(:selected_students, selected_students)
      |> assign(:selected_students_ids, selected_students_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("remove_assignee", %{"id" => id}, socket) do
    selected_assignees =
      socket.assigns.selected_assignees
      |> Enum.filter(&(&1.id != id))

    selected_assignees_ids = selected_assignees |> Enum.map(& &1.id)

    socket =
      socket
      |> assign(:selected_assignees, selected_assignees)
      |> assign(:selected_assignees_ids, selected_assignees_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_tag", %{"id" => id}, socket) do
    selected_tags_ids =
      if id in socket.assigns.selected_tags_ids do
        Enum.filter(socket.assigns.selected_tags_ids, &(&1 != id))
      else
        [id | socket.assigns.selected_tags_ids]
      end

    socket =
      socket
      |> assign(:selected_tags_ids, selected_tags_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_status", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:selected_status_id, id)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("validate", %{"student_record" => student_record_params}, socket),
    do: {:noreply, assign_validated_form(socket, student_record_params)}

  def handle_event("save", %{"student_record" => student_record_params}, socket) do
    student_record_params =
      inject_extra_params(socket, student_record_params)

    save_student_record(socket, socket.assigns.student_record.id, student_record_params)
  end

  def handle_event("delete", _, socket) do
    StudentsRecords.delete_student_record(
      socket.assigns.student_record,
      check_profile_permissions: socket.assigns.current_user.current_profile,
      log_profile_id: socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, _student_record} ->
        # we notify using the assigned student record,
        # which already has preloaded fields
        notify(__MODULE__, {:deleted, socket.assigns.student_record}, socket.assigns)

        socket =
          socket
          |> assign(:is_deleted, true)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp initialize_form(%{assigns: %{form_initialized: false}} = socket) do
    socket
    |> assign_statuses()
    |> assign_tags()
    |> assign(:form_initialized, true)
  end

  defp initialize_form(socket), do: socket

  defp assign_statuses(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    statuses = StudentsRecords.list_student_record_statuses(school_id: school_id)
    assign(socket, :statuses, statuses)
  end

  defp assign_tags(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    tags = StudentsRecords.list_student_record_tags(school_id: school_id)
    assign(socket, :tags, tags)
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.student_record
      |> StudentsRecords.change_student_record(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.current_user.current_profile.school_id)
    |> Map.put("tags_ids", socket.assigns.selected_tags_ids)
    |> Map.put("status_id", socket.assigns.selected_status_id)
    |> Map.put("students_ids", socket.assigns.selected_students_ids)
    |> Map.put("classes_ids", socket.assigns.selected_classes_ids)
    |> Map.put("assignees_ids", socket.assigns.selected_assignees_ids)
  end

  defp save_student_record(socket, nil, student_record_params) do
    # when creating student record, inject current user as creator
    student_record_params =
      student_record_params
      |> Map.put(
        "created_by_staff_member_id",
        socket.assigns.current_user.current_profile.staff_member_id
      )

    StudentsRecords.create_student_record(
      student_record_params,
      log_profile_id: socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, student_record} ->
        # preload students and classes
        student_record =
          student_record
          |> Ecto.reset_fields([
            :students,
            :classes,
            :status,
            :tags,
            :created_by_staff_member,
            :assignees
          ])
          |> Repo.preload([
            :students,
            :status,
            :tags,
            :created_by_staff_member,
            :assignees,
            [classes: :cycle]
          ])

        notify(__MODULE__, {:created, student_record}, socket.assigns)

        socket =
          socket
          |> assign(:student_record, student_record)
          |> assign(:is_editing, false)
          # don't need to check, as we're creating a new record
          |> assign(:has_update_permissions, true)
          |> assign(:has_delete_permissions, true)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_student_record(socket, _id, student_record_params) do
    # when updating student record with closed status, inject current user
    selected_status =
      Enum.find(socket.assigns.statuses, &(&1.id == socket.assigns.selected_status_id))

    student_record_params =
      if selected_status.is_closed do
        student_record_params
        |> Map.put(
          "closed_by_staff_member_id",
          socket.assigns.current_user.current_profile.staff_member_id
        )
      else
        student_record_params
      end

    StudentsRecords.update_student_record(
      socket.assigns.student_record,
      student_record_params,
      check_profile_permissions: socket.assigns.current_user.current_profile,
      log_profile_id: socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, student_record} ->
        # preload students and classes
        student_record =
          student_record
          |> Ecto.reset_fields([
            :students,
            :classes,
            :status,
            :tags,
            :created_by_staff_member,
            :closed_by_staff_member,
            :assignees
          ])
          |> Repo.preload([
            :students,
            :status,
            :tags,
            :created_by_staff_member,
            :closed_by_staff_member,
            :assignees,
            [classes: :cycle]
          ])

        notify(__MODULE__, {:updated, student_record}, socket.assigns)

        socket =
          socket
          |> assign(:student_record, student_record)
          |> assign(:is_editing, false)
          |> assign_has_update_permissions()
          |> assign_has_delete_permissions()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
