defmodule LantternWeb.LessonChatLive do
  use LantternWeb, :live_view

  alias Lanttern.AgentChat
  alias Lanttern.Agents
  alias Lanttern.LearningContext
  alias Lanttern.Lessons
  alias Lanttern.LessonTemplates

  @model "gpt-5-nano"

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_lesson(params)
      |> assign_strand()
      |> handle_lesson_template_assigns()
      |> handle_agent_assigns()
      |> assign_conversations()
      |> assign_empty_message_form()
      |> assign(:conversation, nil)
      |> assign(:messages, [])
      |> assign(:loading, false)

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

  defp handle_lesson_template_assigns(socket) do
    lesson_templates =
      LessonTemplates.list_lesson_templates(socket.assigns.current_scope)
      # convert to a lightweight map
      |> Enum.map(fn template ->
        template
        |> Map.from_struct()
        |> Map.take([:id, :name])
      end)

    socket
    |> assign(:lesson_templates, lesson_templates)
    |> assign(:selected_lesson_template, nil)
  end

  defp handle_agent_assigns(socket) do
    agents =
      Agents.list_ai_agents(socket.assigns.current_scope)
      # convert to a lightweight map
      |> Enum.map(fn template ->
        template
        |> Map.from_struct()
        |> Map.take([:id, :name])
      end)

    # pick the first agent as the starting agent
    # (change logic in the future, maybe adding a default agent in user preferences)
    selected_agent =
      case agents do
        [] -> nil
        [agent | _] -> agent
      end

    socket
    |> assign(:agents, agents)
    |> assign(:selected_agent, selected_agent)
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

  defp assign_empty_message_form(socket) do
    form =
      %{"content" => ""}
      |> to_form(as: :message)

    assign(socket, :message_form, form)
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

    socket
    |> assign(:conversation, nil)
    |> stream(:messages, [], reset: true)
  end

  defp apply_action(socket, :show, %{"conversation_id" => id}) do
    case AgentChat.get_conversation_with_messages(
           socket.assigns.current_scope,
           id
         ) do
      nil ->
        socket
        |> put_flash(:error, gettext("Conversation not found"))
        |> push_navigate(to: ~p"/strands/lesson/#{socket.assigns.lesson}/chat")

      conversation ->
        if connected?(socket) do
          unsubscribe_all()
          AgentChat.subscribe_conversation(conversation.id)
        end

        socket
        # as messages will be saved in its own assign,
        # reset the preloaded field in conversation
        |> assign(:conversation, Ecto.reset_fields(conversation, [:messages]))
        |> stream(:messages, conversation.messages, reset: true)
    end
  end

  # event handlers

  @impl true
  def handle_event("select_template", %{"id" => id}, socket) do
    selected_lesson_template =
      Enum.find(socket.assigns.lesson_templates, &(&1.id == id))

    {:noreply, assign(socket, :selected_lesson_template, selected_lesson_template)}
  end

  def handle_event("select_agent", %{"id" => id}, socket) do
    selected_agent =
      Enum.find(socket.assigns.agents, &(&1.id == id))

    {:noreply, assign(socket, :selected_agent, selected_agent)}
  end

  def handle_event("update_message", %{"message" => params}, socket) do
    form = params |> to_form(as: :message)
    {:noreply, assign(socket, :message_form, form)}
  end

  def handle_event("send_message", %{"message" => %{"content" => content}}, socket)
      when content not in ["", nil] do
    socket = assign(socket, :loading, true)

    case socket.assigns.conversation do
      nil ->
        # Create new conversation with initial message linked to strand and lesson
        %{strand: strand, lesson: lesson, current_scope: scope} = socket.assigns
        opts = [strand_id: strand.id, lesson_id: lesson.id]

        case AgentChat.create_conversation_with_message(scope, content, opts) do
          {:ok, %{conversation: conversation, user_message: user_message}} ->
            socket =
              socket
              |> assign(:conversation, conversation)
              |> update(:conversations, fn convs -> [conversation | convs] end)
              |> assign(:messages, [user_message])
              |> enqueue_chat_response_job()
              |> assign_empty_message_form()
              |> push_patch(to: ~p"/strands/lesson/#{lesson}/chat/#{conversation.id}")

            {:noreply, socket}

          {:error, _changeset} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, gettext("Failed to create conversation"))

            {:noreply, socket}
        end

      conversation ->
        # Add message to existing conversation
        case AgentChat.add_user_message(socket.assigns.current_scope, conversation, content) do
          {:ok, user_message} ->
            socket =
              socket
              # update messages (sync)
              |> stream_insert(:messages, user_message)
              |> enqueue_chat_response_job()
              |> assign_empty_message_form()

            {:noreply, socket}

          {:error, _changeset} ->
            socket =
              socket
              |> assign(:loading, false)
              |> put_flash(:error, gettext("Failed to send message"))

            {:noreply, socket}
        end
    end
  end

  def handle_event("send_message", _params, socket) do
    {:noreply, socket}
  end

  defp enqueue_chat_response_job(socket) do
    # request chat response via oban job (async)
    %{
      user_id: socket.assigns.current_scope.user_id,
      conversation_id: socket.assigns.conversation.id,
      model: @model,
      agent_id: Map.get(socket.assigns.selected_agent || %{}, :id),
      lesson_template_id: Map.get(socket.assigns.selected_lesson_template || %{}, :id)
    }
    |> Oban.Job.new(queue: :ai, worker: Lanttern.ChatResponseWorker)
    |> Oban.insert()

    socket
  end

  # info handlers

  @impl true
  def handle_info({:conversation, {:message_added, saved_message}}, socket) do
    conversation = socket.assigns.conversation

    socket =
      socket
      |> stream_insert(:messages, saved_message)
      |> assign(:loading, false)
      |> update(:conversations, fn convs ->
        # Move this conversation to the top
        case Enum.find(convs, &(&1.id == conversation.id)) do
          nil ->
            convs

          conv ->
            [
              %{conv | updated_at: NaiveDateTime.utc_now()}
              | Enum.reject(convs, &(&1.id == conversation.id))
            ]
        end
      end)

    {:noreply, socket}
  end

  def handle_info({:conversation, {:failed, _}}, socket) do
    socket =
      socket
      |> assign(:loading, false)
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
