defmodule LantternWeb.AgentChat.ConversationComponent do
  @moduledoc """
  A live component that renders an AI chat conversation interface with message
  streaming, template/agent selection, and prompt submission.

  ## Attributes

  Required:

    * `id` - Component identifier for targeting with `send_update/2`
    * `current_scope` - The current user scope for authorization and data access
    * `conversation` - The `%Conversation{}` struct to display, or `nil` for a
      fresh chat interface (a new conversation will be created on first prompt)

  Optional:

    * `class` - Additional CSS classes for the container
    * `strand_id` - Associated strand ID for context in AI responses
    * `lesson_id` - Associated lesson ID for context in AI responses
    * `enabled_functions` - List of functions the LLM will have access to
    * `notify` - Target for notifications (uses `LantternWeb.CoreComponentsHelper.notify/3`)

  ## Notifications

  This component sends the following notifications via `notify/3`:

    * `{:conversation_created, conversation}` - Sent when the first prompt
      creates a new conversation. The parent should handle this to track the
      new conversation ID.

  ## Handling `send_update/2`

  The parent LiveView should forward messages from `ChatResponseWorker` to this
  component using `send_update/3` with the following actions:

    * `%{action: {:message_added, message}}` - Adds a new message to the stream
      and clears the loading state
    * `%{action: :prompt_failed}` - Sets an error state and clears loading

  ## PubSub integration

  The parent LiveView must subscribe to conversation PubSub topics and handle
  broadcasts from `Lanttern.ChatResponseWorker`. The worker broadcasts:

    * `{:assistant_message_created, message}` - When AI generates a response
    * `:assistant_message_failed` - When AI response generation fails

  The parent should translate these into `send_update/3` calls targeting this
  component with the appropriate action.

  ## Example

      <.live_component
        module={ConversationComponent}
        id="lesson-chat"
        current_scope={@current_scope}
        conversation={@conversation}
        strand_id={@strand.id}
        lesson_id={@lesson.id}
        notify={@myself}
      />

  In the parent LiveView:

      def handle_info({:assistant_message_created, message}, socket) do
        send_update(ConversationComponent,
          id: "lesson-chat",
          action: {:message_added, message}
        )
        {:noreply, socket}
      end

      def handle_info(:assistant_message_failed, socket) do
        send_update(ConversationComponent, id: "lesson-chat", action: :prompt_failed)
        {:noreply, socket}
      end
  """

  use LantternWeb, :live_component

  alias Lanttern.AgentChat
  alias Lanttern.Agents
  alias Lanttern.LessonTemplates

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <div class="max-w-[640px] mx-auto">
        <%!-- Chat messages area --%>
        <div id="conversation-messages" phx-update="stream" class="space-y-6">
          <%= for {dom_id, message} <- @streams.messages do %>
            <%= if message.role == "user" do %>
              <div class="flex justify-end" id={dom_id}>
                <div class="rounded-sm p-4 bg-ltrn-dark">
                  <.markdown text={message.content} invert />
                </div>
              </div>
            <% else %>
              <.markdown text={message.content} id={dom_id} />
            <% end %>
          <% end %>
        </div>

        <%!-- Loading indicator --%>
        <div :if={@loading} class="flex justify-start mt-6">
          <div class="bg-ltrn-lighter rounded-sm p-2">
            <p class="text-sm">
              {gettext("Thinking")}
              <span class="inline-block animate-bounce">.</span>
              <span class="inline-block animate-bounce" style="animation-delay: 0.1s">.</span>
              <span class="inline-block animate-bounce" style="animation-delay: 0.2s">.</span>
              <span class="inline-block ml-2">{gettext("(it might take a while)")}</span>
            </p>
          </div>
        </div>

        <%!-- New conversation instructions --%>
        <p :if={!@conversation} class="text-lg text-center">
          {gettext(
            "Select a template and an agent, and give them instructions to help you with the lesson planning."
          )}
        </p>

        <%!-- Error --%>
        <.error_block :if={@error} class="mt-10">
          {@error}
        </.error_block>
      </div>

      <%!-- Input area (always visible) --%>
      <div class="sticky bottom-0 left-0 right-0 py-10">
        <div class="w-full max-w-172 mx-auto bg-white border border-ltrn-light rounded-sm shadow-xl">
          <.form
            for={@prompt_form}
            phx-change="update_prompt"
            phx-submit="send_prompt"
            phx-target={@myself}
            id="conversation-prompt-form"
          >
            <textarea
              id={@prompt_form[:content].id}
              name={@prompt_form[:content].name}
              placeholder={
                if @conversation,
                  do: gettext("Reply..."),
                  else: gettext("How can I help you today?")
              }
              disabled={@loading || !is_nil(@error)}
              class={[
                "w-full h-24 px-4 py-4 font-serif text-base leading-6 text-ltrn-dark placeholder:text-ltrn-subtle resize-none border-0 focus:ring-0 focus:outline-none",
                @loading && "opacity-50 cursor-not-allowed"
              ]}
              phx-debounce="500"
            >{@prompt_form[:content].value}</textarea>
          </.form>

          <%!-- Bottom controls --%>
          <div class="flex items-center justify-end gap-2 px-4 py-4">
            <%!-- Template selector button --%>
            <div class="relative">
              <.button
                type="button"
                id="lesson-template-options-button"
                size="sm"
              >
                {if @selected_lesson_template,
                  do: @selected_lesson_template.name,
                  else: gettext("No lesson template")}
              </.button>
              <.dropdown_menu
                id="lesson-template-options"
                button_id="lesson-template-options-button"
              >
                <:item
                  on_click={JS.push("select_template", value: %{"id" => nil}, target: @myself)}
                  text={gettext("Use without lesson template")}
                />
                <:item
                  :for={template <- @lesson_templates}
                  on_click={
                    JS.push("select_template", value: %{"id" => template.id}, target: @myself)
                  }
                  text={template.name}
                />
              </.dropdown_menu>
            </div>

            <%!-- Agent selector button --%>
            <div class="relative">
              <.button
                type="button"
                id="agent-options-button"
                size="sm"
              >
                {if @selected_agent,
                  do: @selected_agent.name,
                  else: gettext("No agents available")}
              </.button>
              <.dropdown_menu
                id="agent-options"
                button_id="agent-options-button"
              >
                <:item
                  :for={agent <- @agents}
                  on_click={JS.push("select_agent", value: %{"id" => agent.id}, target: @myself)}
                  text={agent.name}
                />
              </.dropdown_menu>
            </div>

            <button
              type="submit"
              form="conversation-prompt-form"
              disabled={@loading || !is_nil(@error) || @prompt_form[:content].value in ["", nil]}
              class={[
                "flex items-center justify-center p-2 rounded-full",
                if(@loading || !is_nil(@error) || @prompt_form[:content].value in ["", nil],
                  do: "bg-ltrn-darkest/50 cursor-not-allowed",
                  else: "bg-ltrn-darkest hover:bg-ltrn-darkest/80"
                )
              ]}
            >
              <.icon name="hero-arrow-up" class="size-5 text-white" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true

  # send_update clauses
  def update(%{action: {:message_added, message}} = _assigns, socket) do
    socket =
      socket
      |> stream_insert(:messages, message)
      |> assign(:loading, false)

    {:ok, socket}
  end

  def update(%{action: :prompt_failed} = _assigns, socket) do
    socket =
      socket
      |> assign(:error, gettext("Failed to get AI response"))
      |> assign(:loading, false)

    {:ok, socket}
  end

  # initialize update
  def update(assigns, %{assigns: %{initialized: false}} = socket) do
    socket =
      socket
      |> assign(assigns)
      |> handle_lesson_template_assigns()
      |> handle_agent_assigns()
      |> assign_empty_prompt_form()
      |> stream_messages(assigns.conversation)
      |> assign(:initialized, true)

    {:ok, socket}
  end

  def update(assigns, socket),
    do: {:ok, assign(socket, assigns)}

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

  defp assign_empty_prompt_form(socket) do
    form =
      %{"content" => ""}
      |> to_form(as: :prompt)

    assign(socket, :prompt_form, form)
  end

  defp stream_messages(socket, nil),
    do: stream(socket, :messages, [], reset: true)

  defp stream_messages(socket, conversation) do
    AgentChat.list_conversation_messages(
      socket.assigns.current_scope,
      conversation
    )
    |> case do
      messages when is_list(messages) and messages != [] ->
        stream(socket, :messages, messages, reset: true)

      _ ->
        assign(socket, :error, gettext("No messages for conversation"))
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

  def handle_event("update_prompt", %{"prompt" => params}, socket) do
    form = params |> to_form(as: :prompt)
    {:noreply, assign(socket, :prompt_form, form)}
  end

  def handle_event("send_prompt", %{"prompt" => %{"content" => content}}, socket)
      when content not in ["", nil] do
    socket = assign(socket, :loading, true)

    case socket.assigns.conversation do
      nil ->
        # Use context from assigns
        opts =
          for key <- [:lesson_id, :strand_id],
              val = socket.assigns[key],
              val != nil,
              do: {key, val}

        # Create new conversation with initial message
        case AgentChat.create_conversation_with_message(
               socket.assigns.current_scope,
               content,
               opts
             ) do
          {:ok, %{conversation: conversation, user_message: user_message}} ->
            notify(__MODULE__, {:conversation_created, conversation}, socket.assigns)

            socket =
              socket
              # update messages (sync)
              |> stream_insert(:messages, user_message)
              |> enqueue_chat_response_job(conversation)
              |> assign_empty_prompt_form()

            {:noreply, socket}

          {:error, _changeset} ->
            socket =
              socket
              |> assign(:loading, false)
              |> assign(:error, gettext("Failed to create conversation"))

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
              |> enqueue_chat_response_job(conversation)
              |> assign_empty_prompt_form()

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

  def handle_event("send_prompt", _params, socket) do
    {:noreply, socket}
  end

  defp enqueue_chat_response_job(socket, conversation) do
    # request chat response via oban job (async)
    # model is resolved by the worker from school config or application config
    %{
      user_id: socket.assigns.current_scope.user_id,
      conversation_id: conversation.id,
      agent_id: Map.get(socket.assigns.selected_agent || %{}, :id),
      lesson_template_id: Map.get(socket.assigns.selected_lesson_template || %{}, :id),
      strand_id: Map.get(socket.assigns, :strand_id),
      lesson_id: Map.get(socket.assigns, :lesson_id),
      enabled_functions: Map.get(socket.assigns, :enabled_functions, [])
    }
    |> Lanttern.ChatResponseWorker.new()
    |> Oban.insert()

    socket
  end
end
