defmodule LantternWeb.Admin.StudentRecordLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias LantternWeb.StudentsRecordsHelpers
  alias LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage student_record records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="student_record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:school_id]}
          type="select"
          label="Select school"
          options={@school_options}
          prompt="No school selected"
          class="mb-4"
        />
        <.input
          field={@form[:created_by_staff_member_id]}
          type="select"
          label="Select created by staff member"
          options={@staff_member_options}
          prompt="No staff member selected"
          class="mb-4"
        />
        <.input
          field={@form[:students_ids]}
          type="select"
          multiple
          label="Select students"
          options={@student_options}
          prompt="No student selected"
          class="mb-4"
        />
        <.input
          field={@form[:type_id]}
          type="select"
          label="Select type"
          options={@type_options}
          prompt="No type selected"
          class="mb-4"
        />
        <.input
          field={@form[:status_id]}
          type="select"
          label="Select status"
          options={@status_options}
          prompt="No status selected"
          class="mb-4"
        />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:time]} type="time" label="Time" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Student record</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:school_options, SchoolsHelpers.generate_school_options())
      |> assign(:staff_member_options, SchoolsHelpers.generate_staff_member_options())
      |> assign(:student_options, SchoolsHelpers.generate_student_options())
      |> assign(:type_options, StudentsRecordsHelpers.generate_student_record_type_options())
      |> assign(:status_options, StudentsRecordsHelpers.generate_student_record_status_options())

    {:ok, socket}
  end

  @impl true
  def update(%{student_record: student_record} = assigns, socket) do
    changeset = StudentsRecords.change_student_record(student_record)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"student_record" => student_record_params}, socket) do
    changeset =
      socket.assigns.student_record
      |> StudentsRecords.change_student_record(student_record_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"student_record" => student_record_params}, socket) do
    save_student_record(socket, socket.assigns.action, student_record_params)
  end

  defp save_student_record(socket, :edit, student_record_params) do
    case StudentsRecords.update_student_record(
           socket.assigns.student_record,
           student_record_params
         ) do
      {:ok, student_record} ->
        student_record = student_record |> Lanttern.Repo.preload(:students)
        notify_parent({:saved, student_record})

        {:noreply,
         socket
         |> put_flash(:info, "Student record updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_record(socket, :new, student_record_params) do
    case StudentsRecords.create_student_record(student_record_params) do
      {:ok, student_record} ->
        student_record = student_record |> Lanttern.Repo.preload(:students)
        notify_parent({:saved, student_record})

        {:noreply,
         socket
         |> put_flash(:info, "Student record created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
