defmodule LantternWeb.Admin.CycleLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  import LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage cycle records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="cycle-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:school_id]}
          type="select"
          label="School"
          prompt="Select school"
          options={@school_options}
        />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:start_at]} type="date" label="Start at" />
        <.input field={@form[:end_at]} type="date" label="End at" />
        <.input
          field={@form[:parent_cycle_id]}
          type="select"
          label="Parent cycle"
          prompt="Select parent cycle"
          options={@cycle_options}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Cycle</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cycle: cycle} = assigns, socket) do
    changeset = Schools.change_cycle(cycle)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:school_options, generate_school_options())
     |> assign(:cycle_options, generate_cycle_options())
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cycle" => cycle_params}, socket) do
    changeset =
      socket.assigns.cycle
      |> Schools.change_cycle(cycle_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"cycle" => cycle_params}, socket) do
    save_cycle(socket, socket.assigns.action, cycle_params)
  end

  defp save_cycle(socket, :edit, cycle_params) do
    case Schools.update_cycle(socket.assigns.cycle, cycle_params, preloads: :parent_cycle) do
      {:ok, cycle} ->
        notify_parent({:saved, cycle})

        {:noreply,
         socket
         |> put_flash(:info, "Cycle updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_cycle(socket, :new, cycle_params) do
    case Schools.create_cycle(cycle_params, preloads: :parent_cycle) do
      {:ok, cycle} ->
        notify_parent({:saved, cycle})

        {:noreply,
         socket
         |> put_flash(:info, "Cycle created successfully")
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
