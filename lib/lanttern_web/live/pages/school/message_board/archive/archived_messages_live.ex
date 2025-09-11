defmodule LantternWeb.ArchivedMessagesLive do
  use LantternWeb, :live_view

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.Repo
  require Logger

  import Ecto.Query, warn: false

  import LantternWeb.MessageBoard.Components

  import LantternWeb.FiltersHelpers, only: [assign_classes_filter: 2]

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
      |> apply_assign_classes_filter()
      |> stream_messages()
      |> assign(:page_title, page_title)

    {:ok, socket}
  end

  defp assign_is_communication_manager(socket) do
    is_communication_manager =
      "communication_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_communication_manager, is_communication_manager)
  end

  defp apply_assign_classes_filter(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle
    assign_classes_filter_opts = [cycles_ids: [current_cycle.id]]
    assign_classes_filter(socket, assign_classes_filter_opts)
  end

  defp stream_messages(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    # load sections and preload only archived messages per section
    messages_query =
      from(m in Message,
        where: not is_nil(m.archived_at),
        order_by: m.position,
        preload: [:classes]
      )

    sections =
      from(s in Section, where: s.school_id == ^school_id, order_by: s.position)
      |> Repo.all()
      |> Repo.preload(messages: messages_query)
      |> Enum.filter(fn section -> length(section.messages) > 0 end)

    messages = Enum.flat_map(sections, & &1.messages)

    # also include archived messages that don't belong to any section
    unsectioned_messages =
      from(m in Message,
        where: is_nil(m.section_id) and not is_nil(m.archived_at) and m.school_id == ^school_id,
        order_by: m.position,
        preload: [:classes]
      )
      |> Repo.all()

    all_messages = messages ++ unsectioned_messages

    socket
    |> assign(:sections, sections)
    |> assign(:unsectioned_messages, unsectioned_messages)
    |> assign(:messages_count, length(all_messages))
    |> assign(:messages_ids, Enum.map(all_messages, & &1.id))
    |> tap(fn s ->
      Logger.debug("[ArchivedMessagesLive] messages_count=#{inspect(s.assigns.messages_count)} messages_ids=#{inspect(s.assigns.messages_ids)} is_comm=#{inspect(s.assigns.is_communication_manager)}")
    end)
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
            |> put_flash(:info, gettext("%{message} unarchived", message: message.name))
            |> stream_messages()

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
            |> put_flash(:info, gettext("%{message} deleted", message: message.name))
            |> stream_messages()

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete message"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid message"))}
    end
  end

  @impl true
  def handle_params(%{"card" => card_id}, _uri, socket) do
    card_message = MessageBoard.get_message!(card_id)
    {:noreply, assign(socket, :card_message, card_message)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :card_message, nil)}
  end
end
