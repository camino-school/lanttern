defmodule LantternWeb.StrandLive.DetailsTabs.AboutComponent do
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <.markdown text={@strand.description} />
      <h3 class="mt-16 font-display font-black text-3xl">Curriculum</h3>
      <div :for={strand_ci <- @strand.curriculum_items} class="mt-6">
        <.badge theme="dark"><%= strand_ci.curriculum_item.curriculum_component.name %></.badge>
        <p class="mt-4"><%= strand_ci.curriculum_item.name %></p>
      </div>
    </div>
    """
  end
end
