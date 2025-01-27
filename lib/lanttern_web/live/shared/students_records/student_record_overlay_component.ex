defmodule LantternWeb.StudentsRecords.StudentRecordOverlayComponent do
  @moduledoc """
  Renders an overlay with `StudentRecord` details and editing support
  """

  alias Lanttern.Repo
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.Schools

  # shared

  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.Schools.ClassesFieldComponent
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]

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
              <.label><%= gettext("Record type") %></.label>
              <.badge_button_picker
                id="student-record-type-select"
                on_select={
                  &(JS.push("select_type", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-record-form"))
                }
                items={@types}
                selected_ids={[@selected_type_id]}
                use_color_map_as_active
              />
              <div :if={@form.source.action in [:insert, :update]}>
                <.error :for={{msg, _} <- @form[:type_id].errors}><%= msg %></.error>
              </div>
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
              <.live_component
                module={StudentSearchComponent}
                id="student-search"
                notify_component={@myself}
                label={gettext("Students")}
                refocus_on_select="true"
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
            <div class="pb-6 border-b border-ltrn-light mb-6">
              <div class="flex items-center gap-4 mb-4">
                <div class="flex items-center gap-2">
                  <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
                  <%= Timex.format!(@student_record.date, "{Mfull} {0D}, {YYYY}") %>
                </div>
                <div :if={@student_record.time} class="flex items-center gap-2">
                  <.icon name="hero-clock-mini" class="w-5 h-5 text-ltrn-subtle" />
                  <%= @student_record.time %>
                </div>
              </div>
              <div class="flex items-center gap-4">
                <div class="flex items-center gap-2">
                  <span><%= gettext("Type") %>:</span>
                  <.badge color_map={@student_record.type}>
                    <%= @student_record.type.name %>
                  </.badge>
                </div>
                <div class="flex items-center gap-2">
                  <span><%= gettext("Status") %>:</span>
                  <.badge color_map={@student_record.status}>
                    <%= @student_record.status.name %>
                  </.badge>
                </div>
              </div>
            </div>
            <div class="flex items-start gap-4">
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
              <div :if={@student_record.classes != []} class="flex-1">
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
            <.markdown text={@student_record.description} class="mt-6" />
            <%= if @is_deleted do %>
              <.error_block class="mt-10">
                <%= gettext("This record was deleted") %>
              </.error_block>
            <% else %>
              <div class="flex justify-between gap-4 mt-10">
                <.action
                  type="button"
                  icon_name="hero-x-circle-mini"
                  phx-click={JS.push("delete", target: @myself)}
                  theme="subtle"
                  data-confirm={gettext("Are you sure?")}
                >
                  <%= gettext("Delete") %>
                </.action>
                <.action
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

    {:ok, socket}
  end

  defp assign_student_record(%{assigns: %{student_record_id: :new}} = socket) do
    student_record =
      %StudentRecord{
        school_id: socket.assigns.current_user.current_profile.school_id,
        students: [],
        classes: [],
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
        preloads: [
          :students,
          :type,
          :status,
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
    # we'll need students and classes relationships for changeset
    student_record =
      socket.assigns.student_record
      |> Repo.preload([:students_relationships, :classes_relationships])

    changeset = StudentsRecords.change_student_record(student_record)

    socket
    |> assign(:student_record, student_record)
    |> assign(:form, to_form(changeset))
    |> assign(:selected_type_id, student_record.type_id)
    |> assign(:selected_status_id, student_record.status_id)
    |> assign_selected_students()
    |> assign_selected_classes_ids()
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

  def handle_event("select_type", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:selected_type_id, id)
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
      inject_school_type_status_and_students_in_params(socket, student_record_params)

    save_student_record(socket, socket.assigns.student_record.id, student_record_params)
  end

  def handle_event("delete", _, socket) do
    StudentsRecords.delete_student_record(
      socket.assigns.student_record,
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
    |> assign_types()
    |> assign_statuses()
    |> assign(:form_initialized, true)
  end

  defp initialize_form(socket), do: socket

  defp assign_types(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    types = StudentsRecords.list_student_record_types(school_id: school_id)
    assign(socket, :types, types)
  end

  defp assign_statuses(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    statuses = StudentsRecords.list_student_record_statuses(school_id: school_id)
    assign(socket, :statuses, statuses)
  end

  defp assign_validated_form(socket, params) do
    params = inject_school_type_status_and_students_in_params(socket, params)

    changeset =
      socket.assigns.student_record
      |> StudentsRecords.change_student_record(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp inject_school_type_status_and_students_in_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.current_user.current_profile.school_id)
    |> Map.put("type_id", socket.assigns.selected_type_id)
    |> Map.put("status_id", socket.assigns.selected_status_id)
    |> Map.put("students_ids", socket.assigns.selected_students_ids)
    |> Map.put("classes_ids", socket.assigns.selected_classes_ids)
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
          |> Ecto.reset_fields([:students, :classes, :status, :type])
          |> Repo.preload([:students, :status, :type, [classes: :cycle]])

        notify(__MODULE__, {:created, student_record}, socket.assigns)

        socket =
          socket
          |> assign(:student_record, student_record)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_student_record(socket, _id, student_record_params) do
    StudentsRecords.update_student_record(
      socket.assigns.student_record,
      student_record_params,
      log_profile_id: socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, student_record} ->
        # preload students and classes
        student_record =
          student_record
          |> Ecto.reset_fields([:students, :classes, :status, :type])
          |> Repo.preload([:students, :status, :type, [classes: :cycle]])

        notify(__MODULE__, {:updated, student_record}, socket.assigns)

        socket =
          socket
          |> assign(:student_record, student_record)
          |> assign(:is_editing, false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
