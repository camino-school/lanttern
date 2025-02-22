defmodule LantternWeb.Admin.StudentRecordTagLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage student_record_tag records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="student_record_tag-form"
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
          <.button phx-disable-with="Saving...">Save Student record tag</.button>
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
  def update(%{student_record_tag: student_record_tag} = assigns, socket) do
    changeset = StudentsRecords.change_student_record_tag(student_record_tag)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tag" => student_record_tag_params}, socket) do
    changeset =
      socket.assigns.student_record_tag
      |> StudentsRecords.change_student_record_tag(student_record_tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tag" => student_record_tag_params}, socket) do
    save_student_record_tag(socket, socket.assigns.action, student_record_tag_params)
  end

  defp save_student_record_tag(socket, :edit, student_record_tag_params) do
    case StudentsRecords.update_student_record_tag(
           socket.assigns.student_record_tag,
           student_record_tag_params
         ) do
      {:ok, student_record_tag} ->
        notify_parent({:saved, student_record_tag})

        {:noreply,
         socket
         |> put_flash(:info, "Student record tag updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_record_tag(socket, :new, student_record_tag_params) do
    case StudentsRecords.create_student_record_tag(student_record_tag_params) do
      {:ok, student_record_tag} ->
        notify_parent({:saved, student_record_tag})

        {:noreply,
         socket
         |> put_flash(:info, "Student record tag created successfully")
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
