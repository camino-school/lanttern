defmodule LantternWeb.Admin.StudentRecordTypeLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage student_record_type records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="student_record_type-form"
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
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:bg_color]} type="text" label="Bg color" />
        <.input field={@form[:text_color]} type="text" label="Text color" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Student record type</.button>
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

    {:ok, socket}
  end

  @impl true
  def update(%{student_record_type: student_record_type} = assigns, socket) do
    changeset = StudentsRecords.change_student_record_type(student_record_type)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"student_record_type" => student_record_type_params}, socket) do
    changeset =
      socket.assigns.student_record_type
      |> StudentsRecords.change_student_record_type(student_record_type_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"student_record_type" => student_record_type_params}, socket) do
    save_student_record_type(socket, socket.assigns.action, student_record_type_params)
  end

  defp save_student_record_type(socket, :edit, student_record_type_params) do
    case StudentsRecords.update_student_record_type(
           socket.assigns.student_record_type,
           student_record_type_params
         ) do
      {:ok, student_record_type} ->
        notify_parent({:saved, student_record_type})

        {:noreply,
         socket
         |> put_flash(:info, "Student record type updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_record_type(socket, :new, student_record_type_params) do
    case StudentsRecords.create_student_record_type(student_record_type_params) do
      {:ok, student_record_type} ->
        notify_parent({:saved, student_record_type})

        {:noreply,
         socket
         |> put_flash(:info, "Student record type created successfully")
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
