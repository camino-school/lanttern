defmodule LantternWeb.Admin.StrandLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage strand records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="strand-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Strand</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    changeset = LearningContext.change_strand(strand)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"strand" => strand_params}, socket) do
    changeset =
      socket.assigns.strand
      |> LearningContext.change_strand(strand_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"strand" => strand_params}, socket) do
    save_strand(socket, socket.assigns.action, strand_params)
  end

  defp save_strand(socket, :edit, strand_params) do
    case LearningContext.update_strand(socket.assigns.strand, strand_params) do
      {:ok, strand} ->
        notify_parent({:saved, strand})

        {:noreply,
         socket
         |> put_flash(:info, "Strand updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_strand(socket, :new, strand_params) do
    case LearningContext.create_strand(strand_params) do
      {:ok, strand} ->
        notify_parent({:saved, strand})

        {:noreply,
         socket
         |> put_flash(:info, "Strand created successfully")
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
