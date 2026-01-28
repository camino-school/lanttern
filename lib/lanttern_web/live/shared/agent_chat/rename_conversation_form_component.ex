defmodule LantternWeb.AgentChat.RenameConversationFormComponent do
  @moduledoc """
  Renders a rename `Conversation` form
  """

  use LantternWeb, :live_component

  alias Lanttern.AgentChat

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Rename conversation")}
          class="mb-6"
          phx-debounce="1500"
        />
        <div class="flex justify-end gap-2 mt-10">
          <.button
            type="button"
            theme="ghost"
            phx-click={@on_cancel}
          >
            {gettext("Cancel")}
          </.button>
          <.button type="submit">
            {gettext("Save")}
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{conversation: conversation} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(AgentChat.change_conversation_name(assigns.current_scope, conversation))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"conversation" => params}, socket) do
    changeset =
      AgentChat.change_conversation_name(
        socket.assigns.current_scope,
        socket.assigns.conversation,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"conversation" => params}, socket) do
    case AgentChat.rename_conversation(
           socket.assigns.current_scope,
           socket.assigns.conversation,
           params["name"]
         ) do
      {:ok, conversation} ->
        notify(__MODULE__, {:conversation_renamed, conversation}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
