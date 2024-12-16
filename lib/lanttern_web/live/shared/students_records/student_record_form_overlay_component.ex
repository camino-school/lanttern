defmodule LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentRecord` form
  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.Schools

  # shared

  alias LantternWeb.Schools.StudentSearchComponent
  alias LantternWeb.Schools.ClassesFieldComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="student-record-form-overlay" show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="student-record-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
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
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
            show_optional
          />
          <.input
            field={@form[:description]}
            type="textarea"
            label={gettext("Description")}
            class="mb-1"
            phx-debounce="1500"
          />
          <.markdown_supported class="mb-6" />
        </.form>
        <:actions_left :if={@student_record.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#student-record-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="student-record-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_delete, false)
      |> assign(:initialized, false)

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
      Schools.list_classes_ids_for_student_in_date(student.id, socket.assigns.student_record.date)

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

  def update(%{student_record: %StudentRecord{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_selected_students()
      |> assign_selected_classes_ids()
      |> assign_form()
      |> assign_types()
      |> assign_statuses()
      |> assign(:initialized, true)

    {:ok, socket}
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

  defp assign_form(socket) do
    student_record = socket.assigns.student_record
    changeset = StudentsRecords.change_student_record(student_record)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_type_id, student_record.type_id)
    |> assign(:selected_status_id, student_record.status_id)
  end

  defp assign_types(%{assigns: %{initialized: false}} = socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    types = StudentsRecords.list_student_record_types(school_id: school_id)
    assign(socket, :types, types)
  end

  defp assign_types(socket), do: socket

  defp assign_statuses(%{assigns: %{initialized: false}} = socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    statuses = StudentsRecords.list_student_record_statuses(school_id: school_id)
    assign(socket, :statuses, statuses)
  end

  defp assign_statuses(socket), do: socket

  # event handlers

  @impl true
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
      {:ok, student_record} ->
        notify(__MODULE__, {:deleted, student_record}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
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
    StudentsRecords.create_student_record(
      student_record_params,
      log_profile_id: socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, student_record} ->
        notify(__MODULE__, {:created, student_record}, socket.assigns)
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
        notify(__MODULE__, {:updated, student_record}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
