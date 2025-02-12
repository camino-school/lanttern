defmodule LantternWeb.ArchivedMessagesLive do
  use LantternWeb, :live_view

  alias Lanttern.MessageBoard

  import LantternWeb.DateTimeHelpers

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    page_title =
      gettext(
        "%{school}'s archived messages",
        school: socket.assigns.current_user.current_profile.school_name
      )

    socket =
      socket
      |> assign_is_communication_manager()
      |> stream_messages()
      |> assign(:page_title, page_title)

    {:ok, socket}
  end

  defp assign_is_communication_manager(socket) do
    is_communication_manager =
      "communication_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_communication_manager, is_communication_manager)
  end

  defp stream_messages(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    messages =
      MessageBoard.list_messages(
        school_id: school_id,
        archived: true
      )

    socket
    |> stream(:messages, messages)
    |> assign(:messages_count, length(messages))
    |> assign(:messages_ids, Enum.map(messages, & &1.id))
  end

  # event handlers

  @impl true
  def handle_event("unarchive", %{"id" => id}, socket) do
    if id in socket.assigns.messages_ids do
      message = MessageBoard.get_message!(id)

      case MessageBoard.unarchive_message(message) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{message} unarchived", message: message.name)
            )
            |> stream_delete(:messages, message)
            |> assign(:messages_count, socket.assigns.messages_count - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to unarchive message"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid message"))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    if id in socket.assigns.messages_ids do
      message = MessageBoard.get_message!(id)

      case MessageBoard.delete_message(message) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{message} deleted", message: message.name)
            )
            |> stream_delete(:messages, message)
            |> assign(:messages_count, socket.assigns.messages_count - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete message"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid message"))}
    end
  end
end
