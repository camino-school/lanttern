defmodule LantternWeb.ChatsLive do
  use LantternWeb, :live_view

  alias LangChain.ChatModels.ChatOpenAI

  alias Lanttern.AgentChat

  @model "gpt-5-nano"

  # helpers

  # Extract text content from LangChain message content (list of ContentParts)
  defp extract_text_content(content) when is_list(content) do
    content
    |> Enum.filter(&(&1.type == :text))
    |> Enum.map_join("\n", & &1.content)
  end

  defp extract_text_content(content) when is_binary(content), do: content
  defp extract_text_content(_), do: ""

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    # Mock data for available agents (to be replaced later)
    agents = [
      %{id: 1, name: "Agent Foo"},
      %{id: 2, name: "Agent Bar"}
    ]

    socket =
      socket
      |> assign(:page_title, gettext("AI Agents Chat"))
      |> assign_conversations()
      |> assign(:agents, agents)
      |> assign(:selected_agent_id, 1)
      |> assign(:current_conversation, nil)
      |> assign(:messages, [])
      |> assign(:message_input, "")
      |> assign(:loading, false)

    {:ok, socket}
  end

  defp assign_conversations(socket) do
    conversations = AgentChat.list_conversations(socket.assigns.current_scope)
    assign(socket, :conversations, conversations)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:current_conversation, nil)
    |> assign(:messages, [])
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case AgentChat.get_conversation_with_messages(
           socket.assigns.current_scope,
           id
         ) do
      nil ->
        socket
        |> put_flash(:error, gettext("Conversation not found"))
        |> push_navigate(to: ~p"/chats")

      conversation ->
        socket
        |> assign(:current_conversation, conversation)
        |> assign(:messages, conversation.messages)
    end
  end

  # event handlers

  @impl true
  def handle_event("select_conversation", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/chats/#{id}")}
  end

  def handle_event("new_chat", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/chats")}
  end

  def handle_event("update_message", %{"message" => value}, socket) do
    {:noreply, assign(socket, :message_input, value)}
  end

  def handle_event("send_message", %{"message" => content}, socket) when content != "" do
    socket = assign(socket, :loading, true)

    case socket.assigns.current_conversation do
      nil ->
        # Create new conversation with initial message
        case AgentChat.create_conversation_with_message(socket.assigns.current_scope, content) do
          {:ok, %{conversation: conversation, user_message: user_message}} ->
            send(self(), {:run_llm_chain, conversation.id, [user_message]})

            socket =
              socket
              |> assign(:current_conversation, conversation)
              |> assign(:messages, [user_message])
              |> assign(:message_input, "")
              |> update(:conversations, fn convs -> [conversation | convs] end)
              |> push_patch(to: ~p"/chats/#{conversation.id}")

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
            messages = socket.assigns.messages ++ [user_message]
            send(self(), {:run_llm_chain, conversation.id, messages})

            socket =
              socket
              |> assign(:messages, messages)
              |> assign(:message_input, "")

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

  def handle_event("select_agent", %{"id" => id}, socket) do
    {:noreply, assign(socket, :selected_agent_id, String.to_integer(id))}
  end

  # info handlers

  @impl true
  def handle_info({:run_llm_chain, conversation_id, messages}, socket) do
    # Create the LLM chain and run it
    llm = ChatOpenAI.new!(%{model: @model, stream: false})

    socket =
      case AgentChat.run_llm_chain(messages, llm) do
        {:ok, updated_chain} ->
          # Get the last message (assistant response)
          assistant_message = updated_chain.last_message

          # Extract token usage from metadata
          usage = Map.get(assistant_message.metadata || %{}, :usage, %{})

          usage_attrs = %{
            prompt_tokens: Map.get(usage, :input, 0),
            completion_tokens: Map.get(usage, :output, 0),
            model: @model
          }

          # Save the assistant message
          content = extract_text_content(assistant_message.content)

          AgentChat.add_assistant_message(conversation_id, content, usage_attrs)
          |> handle_add_assistant_message(socket, conversation_id, updated_chain)

        {:error, _reason} ->
          socket
          |> assign(:loading, false)
          |> put_flash(:error, gettext("Failed to get AI response"))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:rename_conversation, conversation, chain}, socket) do
    scope = socket.assigns.current_scope

    case AgentChat.rename_conversation_based_on_chain(scope, conversation, chain) do
      {:ok, updated_conversation} ->
        socket =
          socket
          |> assign(:current_conversation, updated_conversation)
          |> update(:conversations, fn convs ->
            Enum.map(convs, fn c ->
              if c.id == updated_conversation.id, do: updated_conversation, else: c
            end)
          end)

        {:noreply, socket}

      {:error, _reason} ->
        # Silently fail - naming is not critical
        {:noreply, socket}
    end
  end

  defp handle_add_assistant_message(
         {:ok, %{message: saved_message}},
         socket,
         conversation_id,
         chain
       ) do
    conversation = socket.assigns.current_conversation

    # Trigger async rename for unnamed conversations after first response
    if is_nil(conversation.name) do
      send(self(), {:rename_conversation, conversation, chain})
    end

    socket
    |> update(:messages, fn msgs -> msgs ++ [saved_message] end)
    |> assign(:loading, false)
    |> update(:conversations, fn convs ->
      # Move this conversation to the top
      case Enum.find(convs, &(&1.id == conversation_id)) do
        nil ->
          convs

        conv ->
          [
            %{conv | updated_at: NaiveDateTime.utc_now()}
            | Enum.reject(convs, &(&1.id == conversation_id))
          ]
      end
    end)
  end

  defp handle_add_assistant_message({:error, _}, socket, _conversation_id, _chain) do
    socket
    |> assign(:loading, false)
    |> put_flash(:error, gettext("Failed to save response"))
  end
end
