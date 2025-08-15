defmodule LantternWeb.MessageBoard.ReorderLive do
  use LantternWeb, :live_view

  import LantternWeb.CoreComponents

  alias Lanttern.MessageBoard

  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :initialized)

    communication_manager? =
      "communication_management" in socket.assigns.current_user.current_profile.permissions

    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:sections, [])
      |> assign(:communication_manager?, communication_manager?)

    {:ok, socket}
  end

  def handle_event("sortable_update", %{"oldIndex" => old, "newIndex" => new}, socket) do
    {changed_id, rest} = List.pop_at(socket.assigns.sections, old)
    new_sections = List.insert_at(rest, new, changed_id)
    MessageBoard.update_section_position(new_sections)

    {:noreply, assign_sections(socket)}
  end

  def handle_info(:initialized, socket) do
    socket =
      socket
      |> assign_sections()
      |> assign(:initialized, true)

    {:noreply, socket}
  end

  defp assign_sections(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    sections = MessageBoard.list_sections(school_id)

    assign(socket, :sections, sections)
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header_nav current_user={@current_user}>
        <:title>{@current_user.current_profile.school_name}</:title>
        <div class="px-4">
          <.neo_tabs>
            <:tab patch={~p"/school/classes"} is_current={@live_action == :manage_classes}>
              {"#{@current_user.current_profile.current_school_cycle.name} #{gettext("classes")}"}
            </:tab>
            <:tab patch={~p"/school/students"} is_current={@live_action == :manage_students}>
              {gettext("Students")}
            </:tab>
            <:tab patch={~p"/school/staff"} is_current={@live_action == :manage_staff}>
              {gettext("Staff")}
            </:tab>
            <:tab patch={~p"/school/cycles"} is_current={@live_action == :manage_cycles}>
              {gettext("Cycles")}
            </:tab>
            <:tab patch={~p"/school/message_board"} is_current={@live_action == :message_board}>
              {gettext("Message board")}
            </:tab>
            <:tab
              patch={~p"/school/moment_cards_templates"}
              is_current={@live_action == :manage_moment_cards_templates}
            >
              {gettext("Templates")}
            </:tab>
          </.neo_tabs>
        </div>
      </.header_nav>

      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <div class="flex items-center gap-4">
          <h1 class="text-2xl font-bold text-gray-800">
            {gettext("Message board admin - Reorder sections")}
          </h1>
        </div>
        <.action
          type="link"
          navigate={~p"/school/message_board"}
          icon_name="hero-cog-6-tooth-mini"
        >
          {gettext("Manage messages")}
        </.action>
      </.action_bar>

      <.responsive_container class="p-4">
        <%= if @sections == [] do %>
          <.card_base class="p-10 mt-4">
            <.empty_state>
              {gettext("No sections created yet")}
            </.empty_state>
          </.card_base>
        <% else %>
          <div
            class="space-y-8"
            phx-hook="Sortable"
            id="sortable-section-cards"
            data-sortable-handle=".sortable-handle"
            phx-update="ignore"
          >
            <.dragable_card
              :for={section <- @sections}
              id={"sortable-#{section.id}"}
              class="mb-4"
            >
              <h2 class="text-lg font-semibold text-gray-800">{section.name}</h2>
            </.dragable_card>
          </div>
        <% end %>
      </.responsive_container>
    </div>
    """
  end
end
