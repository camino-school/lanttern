defmodule LantternWeb.DashboardLive do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Dashboard 🚧</.page_title_with_menu>
      <div class="mt-40">
        <.link
          navigate={~p"/assessment_points"}
          class="flex items-center font-display font-black text-lg text-ltrn-subtle"
        >
          Assessment points <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          navigate={~p"/curriculum"}
          class="flex items-center mt-10 font-display font-black text-lg text-ltrn-subtle"
        >
          Curriculum <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-32">
      <h2 class="font-display font-black text-2xl">Recent activity</h2>
      <div cards="mt-12">
        <.card>
          Card A
        </.card>
        <.card>
          Card B
        </.card>
      </div>
    </div>
    """
  end

  def card(assigns) do
    ~H"""
    <div class="w-full p-20 mt-6 rounded shadow-xl bg-white">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
