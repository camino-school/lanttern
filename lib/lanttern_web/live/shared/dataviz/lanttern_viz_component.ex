defmodule LantternWeb.Dataviz.LantternVizComponent do
  @moduledoc """
  Renders a "Lanttern visualization" component
  """

  use LantternWeb, :live_component

  alias Lanttern.Dataviz

  @color_scale [
    # cyan
    "#67e8f9",
    # rose
    "#fda4af",
    # violet
    "#c4b5fd",
    # yellow
    "#fde047",
    # lime
    "#bef264",
    # blue
    "#93c5fd",
    # fuschia
    "#f0abfc",
    # orange
    "#fdba74"
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex gap-6 px-10", @class]}>
      <div class="relative flex-1 h-[60vh] min-h-[20rem]">
        <canvas id={@id} phx-hook="LantternViz" class="w-full h-full rounded-lg bg-ltrn-primary/20">
        </canvas>
        <div class="absolute left-2 top-2 max-w-40 font-mono text-xs">
          <p class="mb-2 font-bold"><%= gettext("Layers (moments)") %></p>
          <ul>
            <li class="flex items-center gap-1">
              <span class="shrink-0 w-4 border-t-2 border-ltrn-dark" />
              <.link
                navigate={~p"/strands/#{@strand_id}?tab=assessment"}
                class="underline hover:opacity-50 truncate"
              >
                <%= gettext("Final assessment") %>
              </.link>
            </li>
            <li
              :for={{dom_id, moment} <- @streams.moments}
              id={dom_id}
              class="flex items-center gap-1 mt-2"
            >
              <span class="shrink-0 w-4 border-t-2 border-dotted border-ltrn-subtle"></span>
              <.link
                navigate={~p"/strands/moment/#{moment.id}?tab=assessment"}
                class="underline truncate hover:opacity-50"
              >
                <%= moment.name %>
              </.link>
            </li>
          </ul>
        </div>
      </div>
      <div id="viz-items" class="shrink-0 w-60 h-[60vh] min-h-full overflow-auto">
        <button
          :for={{ci, color} <- @curriculum_items_and_color}
          id={"control-btn-#{ci.id}"}
          type="button"
          class="group w-full pl-2 border-l-4 rounded mb-4 text-sm text-left truncate"
          style={"border-color: #{color}"}
          title={ci.name}
          phx-click={
            JS.toggle_class("truncate active")
            |> JS.push("select_item", value: %{"id" => ci.id}, target: @myself)
          }
        >
          <.badge class="group-[.active]:hidden"><%= ci.curriculum_component.name %></.badge>
          <.badge theme="dark" class="hidden group-[.active]:inline-flex">
            <%= ci.curriculum_component.name %>
          </.badge>
          <br />
          <%= ci.name %>
        </button>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> push_assessment_points_data()

    {:ok, socket}
  end

  defp push_assessment_points_data(socket) do
    %{
      moments: moments,
      strand_goals_curriculum_items: strand_goals_curriculum_items,
      strand_goals_curriculum_items_ids: strand_goals_curriculum_items_ids,
      moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids
    } =
      Dataviz.get_strand_lanttern_viz_data(socket.assigns.strand_id)

    curriculum_items_and_color =
      strand_goals_curriculum_items
      |> Enum.with_index()
      |> Enum.map(fn {ci, i} -> {ci, Enum.at(@color_scale, rem(i, 8))} end)

    socket
    |> push_event("build_lanttern_viz", %{
      strand_goals_curriculum_items_ids: strand_goals_curriculum_items_ids,
      moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids
    })
    |> assign(:curriculum_items_and_color, curriculum_items_and_color)
    |> stream(:moments, moments)
  end

  @impl true
  def handle_event("select_item", %{"id" => id}, socket) do
    socket =
      socket
      |> push_event("set_current_item", %{id: id})

    {:noreply, socket}
  end
end
