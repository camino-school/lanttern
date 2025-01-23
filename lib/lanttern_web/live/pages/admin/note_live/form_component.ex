defmodule LantternWeb.Admin.NoteLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Notes
  import LantternWeb.IdentityHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage note records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="note-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:author_id]}
          type="select"
          label="Author"
          prompt="Select author"
          options={@profile_options}
        />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Note</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:profile_options, generate_profile_options())}
  end

  @impl true
  def update(%{note: note} = assigns, socket) do
    changeset = Notes.change_note(note)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"note" => note_params}, socket) do
    changeset =
      socket.assigns.note
      |> Notes.change_note(note_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"note" => note_params}, socket) do
    save_note(socket, socket.assigns.action, note_params)
  end

  defp save_note(socket, :edit, note_params) do
    case Notes.update_note(socket.assigns.note, note_params,
           preloads: [author: [:student, :staff_member]]
         ) do
      {:ok, note} ->
        notify_parent({:saved, note})

        {:noreply,
         socket
         |> put_flash(:info, "Note updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_note(socket, :new, note_params) do
    case Notes.create_note(note_params, preloads: [author: [:student, :staff_member]]) do
      {:ok, note} ->
        notify_parent({:saved, note})

        {:noreply,
         socket
         |> put_flash(:info, "Note created successfully")
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
