defmodule LantternWeb.Schools.GuardianFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Guardian

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={LantternWeb.CoreComponents.OverlayComponent}
      id="guardian-form-overlay"
      on_close={@on_cancel}
    >
      <div class="w-full max-w-md">
        <.header>
          {@title}
        </.header>

        <.simple_form
          for={@form}
          id="guardian-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="mt-6"
        >
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            placeholder={gettext("Enter guardian name")}
          />

          <:actions>
            <.button
              :if={@guardian.id}
              type="button"
              theme="ghost"
              phx-click="delete"
              phx-target={@myself}
              onclick="return confirm('Are you sure?')"
            >
              {gettext("Delete")}
            </.button>
            <.button phx-disable-with={gettext("Saving...")}>
              {gettext("Save")}
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </.live_component>
    """
  end

  @impl true
  def update(%{guardian: guardian} = assigns, socket) do
    changeset = Schools.change_guardian(guardian)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"guardian" => params}, socket) do
    changeset =
      socket.assigns.guardian
      |> Schools.change_guardian(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"guardian" => params}, socket) do
    save_guardian(socket, socket.assigns.guardian.id, params)
  end

  def handle_event("delete", _params, socket) do
    case Schools.delete_guardian(socket.assigns.guardian) do
      {:ok, guardian} ->
        notify_parent({:deleted, guardian})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp save_guardian(socket, nil, params) do
    case Schools.create_guardian(params) do
      {:ok, guardian} ->
        notify_parent({:created, guardian})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_guardian(socket, _id, params) do
    case Schools.update_guardian(socket.assigns.guardian, params) do
      {:ok, guardian} ->
        notify_parent({:updated, guardian})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg) do
    send(self(), {__MODULE__, msg})
  end
end
