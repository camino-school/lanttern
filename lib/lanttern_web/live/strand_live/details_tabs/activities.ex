defmodule LantternWeb.StrandLive.DetailsTabs.Activities do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div
        :for={{dom_id, activity} <- @streams.activities}
        class="flex flex-col gap-6 p-6 mt-6 rounded shadow-xl bg-white"
        id={dom_id}
      >
        <.link navigate={~p"/strands/#{@strand.id}"} class="font-display font-black text-xl">
          <%= "#{activity.position}." %>
          <span class="underline"><%= activity.name %></span>
        </.link>
        <div class="line-clamp-6">
          <.markdown text={activity.description} class="prose-sm" />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    list_activities_opts = [strands_ids: [assigns.strand.id]]

    {:ok,
     socket
     |> assign(assigns)
     |> stream(:activities, LearningContext.list_activities(list_activities_opts))}
  end
end
