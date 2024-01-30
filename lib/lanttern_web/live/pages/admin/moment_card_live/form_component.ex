defmodule LantternWeb.Admin.MomentCardLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Moments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage moment_card records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="moment_card-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:moment_id]} type="number" label="Moment id" />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:position]} type="number" label="Position" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Moment card</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{moment_card: moment_card} = assigns, socket) do
    changeset = Moments.change_moment_card(moment_card)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"moment_card" => moment_card_params}, socket) do
    changeset =
      socket.assigns.moment_card
      |> Moments.change_moment_card(moment_card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"moment_card" => moment_card_params}, socket) do
    save_moment_card(socket, socket.assigns.action, moment_card_params)
  end

  defp save_moment_card(socket, :edit, moment_card_params) do
    case Moments.update_moment_card(socket.assigns.moment_card, moment_card_params) do
      {:ok, moment_card} ->
        notify_parent({:saved, moment_card})

        {:noreply,
         socket
         |> put_flash(:info, "Moment card updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_moment_card(socket, :new, moment_card_params) do
    case Moments.create_moment_card(moment_card_params) do
      {:ok, moment_card} ->
        notify_parent({:saved, moment_card})

        {:noreply,
         socket
         |> put_flash(:info, "Moment card created successfully")
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
