defmodule LantternWeb.MessageBoard.ReorderComponent do
  @moduledoc """
  Reorder Component for Message Board.
  """
  use LantternWeb, :live_component
  alias Lanttern.MessageBoardV2, as: MessageBoard

  def mount(socket), do: {:ok, assign(socket, :initialized, false)}

  def update(assigns, socket) do
    socket = socket |> assign(assigns) |> initialize()
    {:ok, socket}
  end

  def handle_event("sortable_update", %{"oldIndex" => old, "newIndex" => new}, socket) do
    {changed_id, rest} = List.pop_at(socket.assigns.sections, old)
    new_sections = List.insert_at(rest, new, changed_id)
    MessageBoard.update_section_position(new_sections)
    send(self(), {__MODULE__, :reordered})
    {:noreply, assign_sections(socket)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp assign_sections(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    assign(socket, :sections, MessageBoard.list_sections(school_id: school_id))
  end

  defp initialize(%{assigns: %{initialized: false}} = socket),
    do: socket |> assign_sections() |> assign(:initialized, true)

  defp initialize(socket), do: socket

  def render(assigns) do
    ~H"""
    <div class="px-6">
      <%= if @sections == [] do %>
        <.card_base class="p-10 mt-4">
          <.empty_state>{gettext("No sections created yet")}</.empty_state>
        </.card_base>
      <% else %>
        <div class="-mb-6"></div>
        <div
          class="space-y-8"
          phx-hook="Sortable"
          phx-target={@myself}
          id="sortable-section-cards"
          data-sortable-handle=".sortable-handle"
          data-sortable-event="sortable_update"
          phx-update="ignore"
        >
          <.draggable_card
            :for={section <- @sections}
            id={"sortable-#{section.id}"}
            class="w-full bg-white rounded-lg shadow-lg my-4 border-l-12 gap-2"
            style="border-left-color: #fff;"
          >
            <h3 class="font-display font-black text-lg truncate" title={section.name}>
              {section.name}
            </h3>
          </.draggable_card>
        </div>
      <% end %>
    </div>
    """
  end
end
