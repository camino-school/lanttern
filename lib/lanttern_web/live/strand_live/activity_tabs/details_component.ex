defmodule LantternWeb.StrandLive.ActivityTabs.DetailsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Curricula

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <.markdown text={@activity.description} />
      <h3 class="mt-16 font-display font-black text-3xl">Curriculum</h3>
      <div :for={curriculum_item <- @curriculum_items} class="mt-6">
        <.badge theme="dark"><%= curriculum_item.curriculum_component.name %></.badge>
        <p class="mt-4"><%= curriculum_item.name %></p>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{activity: activity} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :curriculum_items,
       Curricula.list_activity_curriculum_items(activity.id, preloads: :curriculum_component)
     )}
  end
end
