defmodule LantternWeb.StrandLive.MomentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  alias LantternWeb.Dataviz.LantternVizComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between">
        <p><%= gettext("Moments linked to this strand") %></p>
        <div class="shrink-0 flex items-center gap-4">
          <.action
            :if={@moments_count > 1}
            type="button"
            phx-click={JS.exec("data-show", to: "#strand-moments-order-overlay")}
            icon_name="hero-arrows-up-down-mini"
          >
            <%= gettext("Reorder") %>
          </.action>
          <.action
            type="link"
            patch={~p"/strands/#{@strand}/moments?new_moment=true"}
            icon_name="hero-plus-circle-mini"
          >
            <%= gettext("Create new moment") %>
          </.action>
        </div>
      </.action_bar>
      <%= if @moments_count == 0 do %>
        <div class="p-4">
          <.card_base class="p-10">
            <.empty_state><%= gettext("No moments for this strand yet") %></.empty_state>
          </.card_base>
        </div>
      <% else %>
        <.responsive_grid phx-update="stream" id="strand-moments" class="p-4" is_full_width>
          <.card_base :for={{dom_id, moment} <- @streams.moments} class="p-6" id={dom_id}>
            <.link
              navigate={~p"/strands/moment/#{moment.id}"}
              class="font-display font-black text-xl hover:text-ltrn-subtle"
            >
              <%= moment.name %>
            </.link>
            <div class="flex flex-wrap gap-2 mt-2">
              <.badge :for={subject <- moment.subjects}>
                <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
              </.badge>
            </div>
            <div class="mt-6 line-clamp-6">
              <.markdown text={moment.description} />
            </div>
          </.card_base>
        </.responsive_grid>
      <% end %>
      <.live_component
        module={LantternVizComponent}
        id="lanttern-viz"
        class="px-4 py-10"
        strand_id={@strand.id}
      />
      <.slide_over
        :if={@moment}
        id="moment-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}/moments")}
      >
        <:title><%= gettext("New moment") %></:title>
        <.live_component
          module={MomentFormComponent}
          id={:new}
          moment={@moment}
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
  attr :myself, Phoenix.LiveComponent.CID, required: true

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
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_moment()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_moments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moments(socket) do
    moments =
      LearningContext.list_moments(
        strands_ids: [socket.assigns.strand.id],
        preloads: :subjects
      )

    socket
    |> assign(:moments_count, length(moments))
    |> stream(:moments, moments)
    |> assign(:sortable_moments, Enum.with_index(moments))
  end

  defp assign_moment(%{assigns: %{params: %{"new_moment" => "true"}}} = socket) do
    moment = %Moment{strand_id: socket.assigns.strand.id, subjects: []}
    assign(socket, :moment, moment)
  end

  defp assign_moment(socket), do: assign(socket, :moment, nil)

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
        socket =
          socket
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/moments")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
