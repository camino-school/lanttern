defmodule LantternWeb.StrandLive.MomentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment

  import Lanttern.Utils, only: [swap: 3]

  # live components
  alias LantternWeb.LearningContext.MomentFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div class="flex items-end justify-between mb-4">
        <h3 class="font-display font-bold text-lg">
          <%= gettext("Strand moments") %>
        </h3>
        <div class="shrink-0 flex items-center gap-6">
          <.collection_action
            :if={@moments_count > 1}
            type="button"
            phx-click={JS.exec("data-show", to: "#strand-moments-order-overlay")}
            icon_name="hero-arrows-up-down"
          >
            <%= gettext("Reorder") %>
          </.collection_action>
          <.collection_action
            type="link"
            patch={~p"/strands/#{@strand}/new_moment"}
            icon_name="hero-plus-circle"
          >
            <%= gettext("Create new moment") %>
          </.collection_action>
        </div>
      </div>
      <%= if @moments_count == 0 do %>
        <div class="p-10 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No moments for this strand yet") %></.empty_state>
        </div>
      <% else %>
        <div phx-update="stream" id="strand-moments" class="flex flex-col gap-4">
          <div
            :for={{dom_id, {moment, i}} <- @streams.moments}
            class="flex flex-col gap-6 p-6 rounded shadow-xl bg-white"
            id={dom_id}
          >
            <div class="flex items-center justify-between gap-6">
              <.link
                navigate={~p"/strands/moment/#{moment.id}"}
                class="font-display font-black text-xl"
              >
                <%= "#{i + 1}." %>
                <span class="underline"><%= moment.name %></span>
              </.link>
              <div class="shrink-0 flex gap-2">
                <.badge :for={subject <- moment.subjects}>
                  <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", subject.name) %>
                </.badge>
              </div>
            </div>
            <div class="line-clamp-6">
              <.markdown text={moment.description} size="sm" />
            </div>
          </div>
        </div>
      <% end %>
      <.slide_over
        :if={@live_action == :new_moment}
        id="moment-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}?tab=moments")}
      >
        <:title><%= gettext("New moment") %></:title>
        <.live_component
          module={MomentFormComponent}
          id={:new}
          moment={%Moment{strand_id: @strand.id, subjects: []}}
          strand_id={@strand.id}
          action={:new}
          navigate={fn moment -> ~p"/strands/moment/#{moment}" end}
          notify_parent
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="moment-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.reorder_overlay
        :if={@moments_count > 1}
        sortable_moments={@sortable_moments}
        moments_count={@moments_count}
        myself={@myself}
      />
    </div>
    """
  end

  attr :sortable_moments, :list, required: true
  attr :moments_count, :integer, required: true
  attr :myself, :any, required: true

  def reorder_overlay(assigns) do
    ~H"""
    <.slide_over id="strand-moments-order-overlay">
      <:title><%= gettext("Strand Moments Order") %></:title>
      <ol>
        <li :for={{moment, i} <- @sortable_moments} id={"sortable-moment-#{moment.id}"} class="mb-4">
          <.sortable_card
            is_move_up_disabled={i == 0}
            on_move_up={JS.push("set_moment_position", value: %{from: i, to: i - 1}, target: @myself)}
            is_move_down_disabled={i + 1 == @moments_count}
            on_move_down={
              JS.push("set_moment_position", value: %{from: i, to: i + 1}, target: @myself)
            }
          >
            <%= "#{i + 1}. #{moment.name}" %>
          </.sortable_card>
        </li>
      </ol>
      <:actions>
        <.button
          type="button"
          theme="ghost"
          phx-click={JS.exec("data-cancel", to: "#strand-moments-order-overlay")}
        >
          <%= gettext("Cancel") %>
        </.button>
        <.button type="button" phx-click="save_order" phx-target={@myself}>
          <%= gettext("Save") %>
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> stream_configure(
       :moments,
       dom_id: fn {moment, _i} -> "moment-#{moment.id}" end
     )}
  end

  @impl true
  def update(assigns, socket) do
    moments =
      LearningContext.list_moments(strands_ids: [assigns.strand.id], preloads: :subjects)
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:moments_count, length(moments))
     |> stream(:moments, moments)
     |> assign(:sortable_moments, moments)}
  end

  # event handlers

  @impl true
  def handle_event("set_moment_position", %{"from" => i, "to" => j}, socket) do
    sortable_moments =
      socket.assigns.sortable_moments
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_moments, sortable_moments)}
  end

  def handle_event("save_order", _, socket) do
    moments_ids =
      socket.assigns.sortable_moments
      |> Enum.map(fn {ap, _i} -> ap.id end)

    case LearningContext.update_strand_moments_positions(
           socket.assigns.strand.id,
           moments_ids
         ) do
      {:ok, _moments} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=moments")}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
