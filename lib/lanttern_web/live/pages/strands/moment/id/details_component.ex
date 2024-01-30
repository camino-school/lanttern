defmodule LantternWeb.MomentLive.DetailsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Curricula

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <.markdown text={@moment.description} />
      <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Curriculum") %></h3>
      <div :for={curriculum_item <- @curriculum_items} class="mt-6">
        <.badge theme="dark"><%= curriculum_item.curriculum_component.name %></.badge>
        <p class="mt-4"><%= curriculum_item.name %></p>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{moment: moment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :curriculum_items,
       Curricula.list_moment_curriculum_items(moment.id, preloads: :curriculum_component)
     )}
  end
end
