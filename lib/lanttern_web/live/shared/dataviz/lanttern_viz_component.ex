defmodule LantternWeb.Dataviz.LantternVizComponent do
  @moduledoc """
  Renders a "Lanttern visualization" component
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

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
      <div class="flex-1 h-[60vh] min-h-[20rem]">
        <canvas id={@id} phx-hook="LantternViz" class="w-full h-full rounded-lg bg-ltrn-primary/20">
        </canvas>
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
            JS.add_class("truncate", to: "#viz-items button:not(#control-btn-#{ci.id})")
            |> JS.remove_class("active", to: "#viz-items button:not(#control-btn-#{ci.id})")
            |> JS.toggle_class("truncate")
            |> JS.toggle_class("active")
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
    strand =
      LearningContext.get_strand(socket.assigns.strand_id,
        preloads: [
          assessment_points: [curriculum_item: :curriculum_component],
          moments: :assessment_points
        ]
      )

    strand_goals =
      strand.assessment_points
      |> Enum.map(& &1.curriculum_item_id)

    moments_assessment_points =
      strand.moments
      |> Enum.map(&build_moment_reverse_curriculum_items_list/1)
      |> Enum.reverse()

    curriculum_items_and_color =
      strand.assessment_points
      |> Enum.map(& &1.curriculum_item)
      |> Enum.with_index()
      |> Enum.map(fn {ci, i} -> {ci, Enum.at(@color_scale, rem(i, 8))} end)

    socket
    |> push_event("build_lanttern_viz", %{
      strand_goals: strand_goals,
      moments_assessment_points: moments_assessment_points
    })
    |> assign(:curriculum_items_and_color, curriculum_items_and_color)
  end

  defp build_moment_reverse_curriculum_items_list(
         %{assessment_points: assessment_points} = _moment
       ) do
    assessment_points
    |> Enum.map(& &1.curriculum_item_id)
    |> Enum.reverse()
  end

  @impl true
  def handle_event("select_item", %{"id" => id}, socket) do
    socket =
      socket
      |> push_event("set_current_item", %{id: id})

    {:noreply, socket}
  end
end
