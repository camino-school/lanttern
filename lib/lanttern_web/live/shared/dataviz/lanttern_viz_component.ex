defmodule LantternWeb.Dataviz.LantternVizComponent do
  @moduledoc """
  Renders a "Lanttern visualization" component
  """

  use LantternWeb, :live_component

  alias Lanttern.Dataviz

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@has_data} class={["flex gap-4", @class]}>
        <div class="relative flex-1 h-[60vh] min-h-[20rem]">
          <canvas id={@id} phx-hook="LantternViz" class="w-full h-full rounded-lg bg-ltrn-primary/20">
          </canvas>
          <div class="absolute left-2 top-2 max-w-40 font-mono text-xs">
            <p class="mb-2 font-bold"><%= gettext("Layers (moments)") %></p>
            <ul id="viz-layers-nav" phx-update="stream">
              <li class="flex items-center gap-1" id="main-layer">
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
        <div
          id="viz-items"
          class="shrink-0 w-60 h-[60vh] min-h-full overflow-auto"
          phx-update="stream"
        >
          <button
            :for={{dom_id, ci} <- @streams.curriculum_items}
            id={"control-btn-#{dom_id}"}
            type="button"
            class="group w-full pl-2 border-l-4 rounded mb-4 text-sm text-left truncate"
            style={"border-color: #{@curriculum_items_ids_color_map[ci.id]}"}
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
      moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids,
      curriculum_items_ids_color_map: curriculum_items_ids_color_map
    } =
      Dataviz.get_strand_lanttern_viz_data(socket.assigns.strand_id)

    socket
    |> push_event("build_lanttern_viz", %{
      strand_goals_curriculum_items_ids: strand_goals_curriculum_items_ids,
      moments_assessments_curriculum_items_ids: moments_assessments_curriculum_items_ids,
      curriculum_items_ids_color_map: curriculum_items_ids_color_map
    })
    |> stream(:curriculum_items, strand_goals_curriculum_items)
    |> stream(:moments, moments)
    |> assign(:curriculum_items_ids_color_map, curriculum_items_ids_color_map)
    |> assign(:has_data, length(strand_goals_curriculum_items) > 0)
  end

  @impl true
  def handle_event("select_item", %{"id" => id}, socket) do
    socket =
      socket
      |> push_event("set_current_item", %{id: id})

    {:noreply, socket}
  end
end
