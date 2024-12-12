defmodule LantternWeb.MomentLive.CardsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.LearningContext.MomentCardFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4">
        <p>
          <%= gettext("Use cards to add an extra layer of organization to moments") %>
        </p>
        <.action
          type="link"
          patch={~p"/strands/moment/#{@moment}/cards?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New moment card") %>
        </.action>
      </.action_bar>
      <.responsive_container class="py-10">
        <%= if @moment_cards_length == 0 do %>
          <.card_base class="p-10">
            <.empty_state><%= gettext("No cards for this moment yet") %></.empty_state>
          </.card_base>
        <% else %>
          <div id="moment-cards" phx-update="stream">
            <.sortable_card
              :for={{dom_id, {moment_card, i}} <- @streams.indexed_moment_cards}
              class="mt-6"
              id={dom_id}
              is_move_up_disabled={i == 0}
              on_move_up={
                JS.push("swap_card_position", value: %{from: i, to: i - 1}, target: @myself)
              }
              is_move_down_disabled={i + 1 == @moment_cards_length}
              on_move_down={
                JS.push("swap_card_position", value: %{from: i, to: i - 1}, target: @myself)
              }
            >
              <div class="flex items-center gap-4">
                <h5 class="font-display font-bold text-sm">
                  <%= moment_card.name %>
                </h5>
                <.action
                  type="link"
                  patch={~p"/strands/moment/#{@moment}/cards?edit=#{moment_card.id}"}
                  icon_name="hero-pencil-mini"
                  theme="subtle"
                >
                  <%= gettext("Edit") %>
                </.action>
              </div>
              <.markdown text={moment_card.description} class="mt-4" />
            </.sortable_card>
          </div>
        <% end %>
      </.responsive_container>
      <.slide_over
        :if={@moment_card}
        id="moment-card-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}/cards")}
      >
        <:title><%= gettext("Moment card") %></:title>
        <.live_component
          module={MomentCardFormComponent}
          id={@moment_card.id || :new}
          notify_component={@myself}
          moment_card={@moment_card}
          navigate={~p"/strands/moment/#{@moment}/cards"}
        />
        <:actions_left :if={@moment_card.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_card"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-card-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="moment-card-form" phx-disable-with={gettext("Saving...")}>
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
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_moment_card()

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
      LearningContext.list_moment_cards(moments_ids: [socket.assigns.moment.id])

    socket
    |> stream(:indexed_moment_cards, Enum.with_index(moment_cards), reset: true)
    |> assign(:moment_cards_length, length(moment_cards))
    |> assign(:moment_cards_ids, Enum.map(moment_cards, & &1.id))
  end

  defp assign_moment_card(%{assigns: %{params: %{"new" => "true"}}} = socket),
    do: assign(socket, :moment_card, %MomentCard{moment_id: socket.assigns.moment.id})

  defp assign_moment_card(%{assigns: %{params: %{"edit" => binary_id}}} = socket) do
    with {id, _} <- Integer.parse(binary_id),
         true <- id in socket.assigns.moment_cards_ids,
         %MomentCard{} = moment_card <- LearningContext.get_moment_card(id) do
      assign(socket, :moment_card, moment_card)
    else
      _ -> assign(socket, :moment_card, nil)
    end
  end

  defp assign_moment_card(socket),
    do: assign(socket, :moment_card, nil)

  # event handlers

  @impl true
  def handle_event("delete_card", _params, socket) do
    case LearningContext.delete_moment_card(socket.assigns.moment_card) do
      {:ok, _moment_card} ->
        socket =
          socket
          |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/cards")
          |> put_flash(:info, gettext("Moment card deleted"))

        {:noreply, socket}

      {:error, _changeset} ->
        # todo: handle error
        {:noreply, socket}
    end
  end

  def handle_event("swap_card_position", %{"from" => i, "to" => j}, socket) do
    moment_cards_ids =
      socket.assigns.moment_cards_ids
      |> swap(i, j)

    case LearningContext.update_moment_cards_positions(moment_cards_ids) do
      {:ok, _moment_cards} ->
        {:noreply, stream_moment_cards(socket)}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
