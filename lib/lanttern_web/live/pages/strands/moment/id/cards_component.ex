defmodule LantternWeb.MomentLive.CardsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard

  # shared components
  alias LantternWeb.LearningContext.MomentCardOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4">
        <p>
          {gettext("Use cards to add an extra layer of organization to moments")}
        </p>
        <div class="flex gap-4">
          <.action
            :if={@moment_cards_count > 1}
            type="link"
            patch={~p"/strands/moment/#{@moment}/cards?reorder=true"}
            icon_name="hero-arrows-up-down-mini"
          >
            {gettext("Reorder")}
          </.action>
          <.action
            type="link"
            patch={~p"/strands/moment/#{@moment}/cards?new=true"}
            icon_name="hero-plus-circle-mini"
          >
            {gettext("New moment card")}
          </.action>
        </div>
      </.action_bar>
      <%= if @moment_cards_count == 0 do %>
        <div class="p-4">
          <.card_base class="p-10">
            <.empty_state>{gettext("No cards for this moment yet")}</.empty_state>
          </.card_base>
        </div>
      <% else %>
        <.responsive_grid id="moment-cards" phx-update="stream" class="p-4" is_full_width>
          <.card_base :for={{dom_id, moment_card} <- @streams.moment_cards} id={dom_id} class="p-6">
            <h5 class="font-display font-black text-base">
              <.link
                patch={~p"/strands/moment/#{@moment}/cards?moment_card_id=#{moment_card.id}"}
                class="font-display font-black text-xl hover:text-ltrn-subtle"
              >
                {moment_card.name}
              </.link>
            </h5>
            <div class="mt-4 line-clamp-4">
              <.markdown text={moment_card.description} />
            </div>
            <div
              :if={moment_card.shared_with_students || moment_card.attachments_count > 0}
              class="flex gap-2 mt-4"
            >
              <.badge
                :if={moment_card.shared_with_students}
                icon_name="hero-users-mini"
                theme="student"
              >
                {gettext("Shared")}
              </.badge>
              <.badge :if={moment_card.attachments_count > 0} icon_name="hero-paper-clip-mini">
                {ngettext("1 attachment", "%{count} attachments", moment_card.attachments_count)}
              </.badge>
            </div>
          </.card_base>
        </.responsive_grid>
      <% end %>
      <.live_component
        :if={@moment_card}
        module={MomentCardOverlayComponent}
        moment_card={@moment_card}
        id="moment-card-overlay"
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}/cards")}
        current_user={@current_user}
        allow_edit
        notify_component={@myself}
      />
      <.slide_over
        :if={@is_reordering}
        show
        id="moment-cards-order-overlay"
        on_cancel={JS.push("dismiss_sort_overlay", target: @myself)}
      >
        <:title>{gettext("Moment cards order")}</:title>
        <div
          phx-hook="Sortable"
          id="sortable-moment-cards"
          data-sortable-handle=".sortable-handle"
          phx-update="ignore"
        >
          <.dragable_card
            :for={{dom_id, moment_card} <- @streams.sortable_moment_cards}
            id={"sortable-#{dom_id}"}
            class="mb-4 gap-4"
          >
            {moment_card.name}
          </.dragable_card>
        </div>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:has_position_change, false)
      |> stream_configure(
        :indexed_moment_cards,
        dom_id: fn {moment_card, _i} -> "moment-card-#{moment_card.id}" end
      )
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {MomentCardOverlayComponent, {:created, moment_card}}}, socket) do
    socket =
      socket
      |> stream_insert(:moment_cards, moment_card)
      |> assign(:moment_cards_count, socket.assigns.moment_cards_count + 1)
      |> assign(:moment_cards_ids, [moment_card.id | socket.assigns.moment_cards_ids])

    {:ok, socket}
  end

  def update(%{action: {MomentCardOverlayComponent, {:updated, moment_card}}}, socket),
    do: {:ok, stream_insert(socket, :moment_cards, moment_card)}

  def update(%{action: {MomentCardOverlayComponent, {:deleted, moment_card}}}, socket) do
    socket =
      socket
      |> stream_delete(:moment_cards, moment_card)
      |> assign(:moment_cards_count, socket.assigns.moment_cards_count - 1)
      |> assign(
        :moment_cards_ids,
        Enum.filter(socket.assigns.moment_cards_ids, &(&1 != moment_card.id))
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_moment_card()
      |> stream_sortable_moment_cards()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_moment_cards()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moment_cards(socket) do
    moment_cards =
      LearningContext.list_moment_cards(
        moments_ids: [socket.assigns.moment.id],
        school_id: socket.assigns.current_user.current_profile.school_id,
        count_attachments: true
      )

    socket
    |> stream(:moment_cards, moment_cards)
    |> assign(:moment_cards_count, length(moment_cards))
    |> assign(:moment_cards_ids, Enum.map(moment_cards, & &1.id))
  end

  defp assign_moment_card(%{assigns: %{params: %{"new" => "true"}}} = socket),
    do: assign(socket, :moment_card, %MomentCard{moment_id: socket.assigns.moment.id})

  defp assign_moment_card(%{assigns: %{params: %{"moment_card_id" => binary_id}}} = socket) do
    with {id, _} <- Integer.parse(binary_id),
         true <- id in socket.assigns.moment_cards_ids,
         %MomentCard{} = moment_card <-
           LearningContext.get_moment_card(id, count_attachments: true) do
      assign(socket, :moment_card, moment_card)
    else
      _ -> assign(socket, :moment_card, nil)
    end
  end

  defp assign_moment_card(socket),
    do: assign(socket, :moment_card, nil)

  defp stream_sortable_moment_cards(%{assigns: %{params: %{"reorder" => "true"}}} = socket) do
    moment_cards =
      LearningContext.list_moment_cards(
        moments_ids: [socket.assigns.moment.id],
        school_id: socket.assigns.current_user.current_profile.school_id
      )

    socket
    |> stream(:sortable_moment_cards, moment_cards)
    # already assigned, but update here just in case
    |> assign(:moment_cards_ids, Enum.map(moment_cards, & &1.id))
    |> assign(:is_reordering, true)
  end

  defp stream_sortable_moment_cards(socket), do: assign(socket, :is_reordering, false)

  # event handlers

  @impl true
  # view Sortable hook for payload info
  def handle_event("sortable_update", payload, socket) do
    %{
      "oldIndex" => old_index,
      "newIndex" => new_index
    } = payload

    {changed_id, rest} = List.pop_at(socket.assigns.moment_cards_ids, old_index)
    moment_cards_ids = List.insert_at(rest, new_index, changed_id)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    LearningContext.update_moment_cards_positions(moment_cards_ids)

    socket =
      socket
      |> assign(:moment_cards_ids, moment_cards_ids)
      |> assign(:has_position_change, true)

    {:noreply, socket}
  end

  def handle_event("dismiss_sort_overlay", _, %{assigns: %{has_position_change: true}} = socket),
    do: {:noreply, push_navigate(socket, to: ~p"/strands/moment/#{socket.assigns.moment}/cards")}

  def handle_event("dismiss_sort_overlay", _, socket),
    do: {:noreply, push_patch(socket, to: ~p"/strands/moment/#{socket.assigns.moment}/cards")}
end
