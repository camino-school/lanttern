defmodule LantternWeb.LessonChatLive do
  use LantternWeb, :live_view

  alias Lanttern.AgentChat
  alias Lanttern.LearningContext
  alias Lanttern.Lessons

  # shared
  alias LantternWeb.AgentChat.ConversationComponent
  alias LantternWeb.AgentChat.RenameConversationFormComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_lesson(params)
      |> assign_strand()
      |> assign_conversations()
      |> assign(:conversation, nil)
      |> assign(:is_renaming_conversation, false)

    {:ok, socket}
  end

  defp assign_lesson(socket, %{"lesson_id" => id}) do
    Lessons.get_lesson(id, preloads: [:moment])
    |> case do
      lesson when is_nil(lesson) ->
        raise(LantternWeb.NotFoundError)

      lesson ->
        socket
        |> assign(:lesson, lesson)
        |> assign(:page_title, "#{gettext("Chat")} | #{lesson.name}")
    end
  end

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.lesson.strand_id,
        preloads: [:subjects, :years, :moments]
      )

    socket
    |> assign(:strand, strand)
  end

  defp assign_conversations(socket) do
    conversations =
      AgentChat.list_conversations(
        socket.assigns.current_scope,
        strand_id: socket.assigns.strand.id,
        lesson_id: socket.assigns.lesson.id
      )

    assign(socket, :conversations, conversations)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    if connected?(socket) do
      unsubscribe_all()
    end

    assign(socket, :conversation, nil)
  end

  defp apply_action(socket, :show, %{"conversation_id" => id}) do
    case AgentChat.get_conversation(socket.assigns.current_scope, id) do
      nil ->
        socket
        |> put_flash(:error, gettext("Conversation not found"))
        |> push_navigate(to: ~p"/strands/lesson/#{socket.assigns.lesson}/chat")

      conversation ->
        if connected?(socket) do
          unsubscribe_all()
          AgentChat.subscribe_conversation(conversation.id)
        end

        assign(socket, :conversation, conversation)
    end
  end

  # event handlers

  @impl true
  def handle_event("rename_conversation", _params, socket) do
    {:noreply, assign(socket, :is_renaming_conversation, true)}
  end

  def handle_event("cancel_rename_conversation", _params, socket) do
    {:noreply, assign(socket, :is_renaming_conversation, false)}
  end

  # info handlers

  @impl true
  def handle_info(
        {RenameConversationFormComponent, {:conversation_renamed, conversation}},
        socket
      ) do
    socket =
      socket
      |> assign(:conversation, conversation)
      |> assign(:is_renaming_conversation, false)
      |> update(
        :conversations,
        &Enum.map(&1, fn c ->
          if c.id == conversation.id,
            do: conversation,
            else: c
        end)
      )

    {:noreply, socket}
  end

  def handle_info({ConversationComponent, {:conversation_created, conversation}}, socket) do
    socket =
      push_patch(
        socket,
        to: ~p"/strands/lesson/#{socket.assigns.lesson}/chat/#{conversation.id}"
      )

    {:noreply, socket}
  end

  def handle_info({:conversation, {:message_added, saved_message}}, socket) do
    conversation = socket.assigns.conversation

    socket =
      socket
      |> update(:conversations, fn convs ->
        # Move this conversation to the top
        case Enum.find(convs, &(&1.id == conversation.id)) do
          nil ->
            convs

          conv ->
            [
              conv
              | Enum.reject(convs, &(&1.id == conversation.id))
            ]
        end
      end)

    # notify conversation component
    send_update(
      ConversationComponent,
      id: "agent-conversation",
      action: {:message_added, saved_message}
    )

    {:noreply, socket}
  end

  def handle_info({:conversation, {:failed, _}}, socket) do
    # notify conversation component
    send_update(
      ConversationComponent,
      id: "agent-conversation",
      action: :prompt_failed
    )

    socket =
      socket
      |> put_flash(:error, gettext("Failed to get AI response"))

    {:noreply, socket}
  end

  def handle_info({:conversation, {:conversation_renamed, updated_conversation}}, socket) do
    socket =
      socket
      |> assign(:conversation, updated_conversation)
      |> update_conversation_in_list(updated_conversation)

    {:noreply, socket}
  end

  defp update_conversation_in_list(socket, updated_conversation) do
    update(
      socket,
      :conversations,
      &Enum.map(&1, fn c ->
        if c.id == updated_conversation.id,
          do: updated_conversation,
          else: c
      end)
    )
  end
end
