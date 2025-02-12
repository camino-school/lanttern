defmodule LantternWeb.SchoolLive.MessageBoardComponent do
  @moduledoc """
  ### Supported attrs/assigns

  - `is_communication_manager` (required, bool)
  """
  use LantternWeb, :live_component

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoard.Message

  import LantternWeb.DateTimeHelpers

  # shared

  alias LantternWeb.MessageBoard.MessageFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <p class="flex items-center gap-2">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext(
            "Messages in the school message board are shared with all students and families."
          ) %>
        </p>
        <.action
          :if={@is_communication_manager}
          type="link"
          patch={~p"/school/message_board?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New message") %>
        </.action>
      </.action_bar>
      <.responsive_container class="p-4">
        <div class="flex items-center gap-4">
          <p><%= ngettext("Showing 1 message", "Showing %{count} messages", @messages_count) %></p>
          <.action type="link" theme="subtle" navigate={~p"/school/message_board/archive"}>
            <%= gettext("View archived messages") %>
          </.action>
        </div>
        <%= if @messages_count == 0 do %>
          <.card_base class="p-10 mt-4">
            <.empty_state><%= gettext("No messages created yet") %></.empty_state>
          </.card_base>
        <% else %>
          <div id="messages-board" phx-update="stream">
            <.card_base :for={{dom_id, message} <- @streams.messages} id={dom_id} class="p-6 mt-4">
              <div class="flex items-start justify-between gap-4">
                <h3 class="flex-1 font-display font-black text-xl" inner-html={}>
                  <%= raw(Earmark.as_html!(message.name, inner_html: true)) %>
                </h3>
                <.action
                  :if={@is_communication_manager}
                  type="link"
                  patch={~p"/school/message_board?edit=#{message.id}"}
                  icon_name="hero-pencil-mini"
                >
                  <%= gettext("Edit") %>
                </.action>
              </div>
              <div class="flex items-center gap-2 mt-2 text-xs">
                <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
                <%= format_local!(message.inserted_at, "{Mshort} {0D}, {YYYY} {h24}:{m}") %>
                <%= if message.inserted_at != message.updated_at do %>
                  <span class="text-ltrn-subtle">
                    <%= "(#{gettext("Updated")} #{format_local!(message.updated_at, "{Mshort} {0D}, {YYYY} {h24}:{m}")})" %>
                  </span>
                <% end %>
              </div>
              <.markdown text={message.description} class="mt-10" />
            </.card_base>
          </div>
        <% end %>
      </.responsive_container>
      <.live_component
        :if={@message}
        module={MessageFormOverlayComponent}
        id="message-form-overlay"
        message={@message}
        title={@message_overlay_title}
        on_cancel={JS.patch(~p"/school/message_board")}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {MessageFormOverlayComponent, {action, _message}}}, socket)
      when action in [:created, :updated, :archived] do
    flash_message =
      case action do
        :created -> {:info, gettext("Message created successfully")}
        :updated -> {:info, gettext("Message updated successfully")}
        :archived -> {:info, gettext("Message archived successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: ~p"/school/message_board"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_message()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_messages()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_messages(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    messages =
      MessageBoard.list_messages(school_id: school_id)

    socket
    |> stream(:messages, messages)
    |> assign(:messages_count, length(messages))
    |> assign(:messages_ids, Enum.map(messages, &"#{&1.id}"))
  end

  defp assign_message(%{assigns: %{is_communication_manager: false}} = socket),
    do: assign(socket, :message, nil)

  defp assign_message(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    message = %Message{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:message, message)
    |> assign(:message_overlay_title, gettext("New message"))
  end

  defp assign_message(%{assigns: %{params: %{"edit" => message_id}}} = socket) do
    with true <- socket.assigns.is_communication_manager,
         true <- message_id in socket.assigns.messages_ids do
      message = MessageBoard.get_message(message_id)

      socket
      |> assign(:message, message)
      |> assign(:message_overlay_title, gettext("Edit message"))
    else
      _ ->
        assign(socket, :message, nil)
    end
  end

  defp assign_message(socket), do: assign(socket, :message, nil)

  # defp assign_message(
  #        %{assigns: %{params: %{"new" => "true"}, is_content_manager: true}} = socket
  #      ) do
  #   message = %MomentCardTemplate{
  #     school_id: socket.assigns.current_user.current_profile.school_id
  #   }

  #   socket
  #   |> assign(:message, message)
  # end

  # defp assign_message(%{assigns: %{params: %{"id" => id}}} = socket) do
  #   message =
  #     SchoolConfig.get_moment_card_message(id)

  #   socket
  #   |> assign(:message, message)
  # end

  # defp assign_message(socket), do: assign(socket, :message, nil)

  # defp assign_sortable_messages(
  #        %{assigns: %{params: %{"reorder" => "true"}, is_content_manager: true}} = socket
  #      ) do
  #   school_id = socket.assigns.current_user.current_profile.school_id

  #   messages =
  #     SchoolConfig.list_moment_cards_messages(schools_ids: [school_id])
  #     # remove unnecessary fields to save memory
  #     |> Enum.map(&%MomentCardTemplate{id: &1.id, name: &1.name})

  #   socket
  #   |> assign(:sortable_messages, Enum.with_index(messages))
  #   |> assign(:is_reordering, true)
  # end

  # defp assign_sortable_messages(socket), do: assign(socket, :is_reordering, false)

  # # event handlers

  # @impl true
  # def handle_event("set_message_position", %{"from" => i, "to" => j}, socket) do
  #   sortable_messages =
  #     socket.assigns.sortable_messages
  #     |> Enum.map(fn {mct, _i} -> mct end)
  #     |> swap(i, j)
  #     |> Enum.with_index()

  #   {:noreply, assign(socket, :sortable_messages, sortable_messages)}
  # end

  # def handle_event("save_order", _, socket) do
  #   messages_ids =
  #     socket.assigns.sortable_messages
  #     |> Enum.map(fn {mct, _i} -> mct.id end)

  #   case SchoolConfig.update_moment_cards_messages_positions(messages_ids) do
  #     :ok ->
  #       socket =
  #         socket
  #         |> push_navigate(to: ~p"/school/moment_cards_messages")

  #       {:noreply, socket}

  #     {:error, _} ->
  #       {:noreply, socket}
  #   end
  # end
end
