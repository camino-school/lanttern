defmodule LantternWeb.MomentLive.CardsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard

  # shared components
  alias LantternWeb.LearningContext.MomentCardFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div class="flex items-end justify-between gap-6">
        <h3 class="font-display font-black text-3xl"><%= gettext("Moment cards") %></h3>
        <div class="shrink-0 flex items-center gap-6">
          <.collection_action
            :if={@has_position_change}
            type="button"
            icon_name="hero-check-circle"
            phx-click="save_order"
            phx-target={@myself}
            class="font-bold"
          >
            <%= gettext("Save updated order") %>
          </.collection_action>
          <.collection_action
            type="button"
            icon_name="hero-plus-circle"
            phx-click="new_card"
            phx-target={@myself}
          >
            <%= gettext("Add moment card") %>
          </.collection_action>
        </div>
      </div>
      <p class="mt-4">
        <%= gettext("Use this feature to add an extra layer of organization to your moment planning.") %>
      </p>
      <div :if={@moment_cards == []} class="p-10 mt-10 rounded shadow-xl bg-white">
        <.empty_state><%= gettext("No cards for this moment yet") %></.empty_state>
      </div>
      <div :for={{moment_card, i} <- @moment_cards} class="mt-6">
        <div class="flex items-stretch gap-6 p-6 rounded bg-white shadow-lg">
          <div class="flex-1">
            <div class="flex items-center gap-4">
              <p class="font-display font-bold text-sm">
                <%= moment_card.name %>
              </p>
              <.button
                type="button"
                theme="ghost"
                phx-click={JS.push("edit_card", value: %{id: moment_card.id})}
                phx-target={@myself}
              >
                <%= gettext("Edit") %>
              </.button>
            </div>
            <.markdown text={moment_card.description} class="mt-4" />
          </div>
          <div class="shrink-0 flex flex-col justify-center gap-2">
            <.icon_button
              type="button"
              sr_text={gettext("Move moment card up")}
              name="hero-chevron-up-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i == 0}
              phx-click={JS.push("swap_card_position", value: %{from: i, to: i - 1})}
              phx-target={@myself}
            />
            <.icon_button
              type="button"
              sr_text={gettext("Move moment card down")}
              name="hero-chevron-down-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i + 1 == length(@moment_cards)}
              phx-click={JS.push("swap_card_position", value: %{from: i, to: i + 1})}
              phx-target={@myself}
            />
          </div>
        </div>
      </div>
      <.slide_over
        :if={@live_action == :edit_card}
        id="moment-card-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}?tab=cards")}
      >
        <:title><%= gettext("Moment card") %></:title>
        <.live_component
          module={MomentCardFormComponent}
          id={Map.get(@moment_card, :id) || :new}
          notify_component={@myself}
          moment_card={@moment_card}
          navigate={~p"/strands/moment/#{@moment}?tab=cards"}
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

    {:ok, socket}
  end

  @impl true
  def update(%{moment: moment} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:moment_cards, fn ->
        LearningContext.list_moment_cards(moments_ids: [moment.id])
        |> Enum.with_index()
      end)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("new_card", _params, socket) do
    moment = socket.assigns.moment

    socket =
      socket
      |> assign(:moment_card, %MomentCard{moment_id: moment.id})
      |> push_patch(to: ~p"/strands/moment/#{moment}/edit_card")

    {:noreply, socket}
  end

  def handle_event("edit_card", %{"id" => moment_card_id}, socket) do
    moment_card =
      socket.assigns.moment_cards
      |> Enum.map(fn {card, _i} -> card end)
      |> Enum.find(&(&1.id == moment_card_id))

    socket =
      socket
      |> assign(:moment_card, moment_card)
      |> push_patch(to: ~p"/strands/moment/#{moment_card.moment_id}/edit_card")

    {:noreply, socket}
  end

  def handle_event("delete_card", _params, socket) do
    case LearningContext.delete_moment_card(socket.assigns.moment_card) do
      {:ok, _moment_card} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=cards")}

      {:error, _changeset} ->
        # to do: handle error
        {:noreply, socket}
    end
  end

  def handle_event("swap_card_position", %{"from" => i, "to" => j}, socket) do
    moment_cards =
      socket.assigns.moment_cards
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply,
     socket
     |> assign(:moment_cards, moment_cards)
     |> assign(:has_position_change, true)}
  end

  def handle_event("save_order", _, socket) do
    moment_cards_ids =
      socket.assigns.moment_cards
      |> Enum.map(fn {c, _i} -> c.id end)

    case LearningContext.update_moment_cards_positions(moment_cards_ids) do
      {:ok, _moment_cards} ->
        {:noreply, assign(socket, :has_position_change, false)}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # helpers

  # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  defp swap(a, i1, i2) do
    e1 = Enum.at(a, i1)
    e2 = Enum.at(a, i2)

    a
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end
end
