defmodule LantternWeb.MessageBoard.MessageBoardViewerComponent do
  @moduledoc """
  Renders the message board list.

  Based on given current profile, we build the message board with
  relevant school and classes messages.

  ### Attrs

      attr :current_profile, Profile, required: true
      attr :class, :any

  """

  use LantternWeb, :live_component

  alias Lanttern.MessageBoard

  import LantternWeb.MessageBoardComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@has_messages} class={@class}>
        <.responsive_container>
          <h4 class="font-display font-black text-2xl"><%= gettext("Message board") %></h4>
          <div phx-update="stream" id="messages-list">
            <.message_board_card
              :for={{dom_id, message} <- @streams.messages}
              message={message}
              id={dom_id}
              class="mt-4"
            />
          </div>
        </.responsive_container>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_messages()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_messages(socket) do
    messages =
      MessageBoard.list_messages(school_id: socket.assigns.current_profile.school_id)

    socket
    |> stream(:messages, messages)
    |> assign(:messages_ids, Enum.map(messages, & &1.id))
    |> assign(:has_messages, length(messages) > 0)
  end
end
