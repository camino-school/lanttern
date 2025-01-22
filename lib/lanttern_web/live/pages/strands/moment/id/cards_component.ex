defmodule LantternWeb.MomentLive.CardsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.LearningContext.MomentCardOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4">
        <p>
          <%= gettext("Use cards to add an extra layer of organization to moments") %>
        </p>
        <div class="flex gap-4">
          <.action
            :if={@moment_cards_count > 1}
            type="link"
            patch={~p"/strands/moment/#{@moment}/cards?reorder=true"}
            icon_name="hero-arrows-up-down-mini"
          >
            <%= gettext("Reorder") %>
          </.action>
          <.action
            type="link"
            patch={~p"/strands/moment/#{@moment}/cards?new=true"}
            icon_name="hero-plus-circle-mini"
          >
            <%= gettext("New moment card") %>
          </.action>
        </div>
      </.action_bar>
      <%= if @moment_cards_count == 0 do %>
        <div class="p-4">
          <.card_base class="p-10">
            <.empty_state><%= gettext("No cards for this moment yet") %></.empty_state>
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
                <%= moment_card.name %>
              </.link>
            </h5>
            <div class="mt-4 line-clamp-4">
              <.markdown text={moment_card.description} />
            </div>
            <div :if={moment_card.attachments_count > 0} class="mt-4">
              <.badge icon_name="hero-paper-clip-mini">
                <%= ngettext("1 attachment", "%{count} attachments", moment_card.attachments_count) %>
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
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}/cards")}
      >
        <:title><%= gettext("Moment cards order") %></:title>
        <ol>
          <li
            :for={{moment_card, i} <- @sortable_moment_cards}
            id={"sortable-moment-card-#{moment_card.id}"}
            class="mb-4"
          >
            <.sortable_card
              is_move_up_disabled={i == 0}
              on_move_up={
                JS.push("set_moment_card_position", value: %{from: i, to: i - 1}, target: @myself)
              }
              is_move_down_disabled={i + 1 == @moment_cards_count}
              on_move_down={
                JS.push("set_moment_card_position", value: %{from: i, to: i + 1}, target: @myself)
              }
            >
              <%= "#{i + 1}. #{moment_card.name}" %>
            </.sortable_card>
          </li>
        </ol>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-cards-order-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="button" phx-click="save_order" phx-target={@myself}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
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
      |> assign_sortable_moment_cards()

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

  defp assign_sortable_moment_cards(%{assigns: %{params: %{"reorder" => "true"}}} = socket) do
    moment_cards =
      LearningContext.list_moment_cards(moments_ids: [socket.assigns.moment.id])
      # remove unnecessary fields to save memory
      |> Enum.map(&%MomentCard{id: &1.id, name: &1.name})

    socket
    |> assign(:sortable_moment_cards, Enum.with_index(moment_cards))
    |> assign(:is_reordering, true)
  end

  defp assign_sortable_moment_cards(socket), do: assign(socket, :is_reordering, false)

  # event handlers

  @impl true
  def handle_event("set_moment_card_position", %{"from" => i, "to" => j}, socket) do
    sortable_moment_cards =
      socket.assigns.sortable_moment_cards
      |> Enum.map(fn {mc, _i} -> mc end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_moment_cards, sortable_moment_cards)}
  end

  def handle_event("save_order", _, socket) do
    moment_cards_ids =
      socket.assigns.sortable_moment_cards
      |> Enum.map(fn {mc, _i} -> mc.id end)

    case LearningContext.update_moment_cards_positions(moment_cards_ids) do
      {:ok, _moment_cards} ->
        socket =
          socket
          |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/cards")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
