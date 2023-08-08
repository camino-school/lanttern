defmodule LantternWeb.AssessmentPointsLive do
  use LantternWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment points</h1>
      <div class="mt-12">
        <p class="font-display font-bold text-lg">
          I want to explore assessment points<br /> in <u>all disciplines</u>
          <br /> from <u>all grade 4 classes</u>
          <br /> in <u>this bimester</u>
        </p>
        <.link
          patch={~p"/assessment_points/explorer"}
          class="flex items-center mt-4 font-display font-black text-lg text-slate-400"
        >
          Explore <.icon name="hero-arrow-right" class="text-cyan-400 ml-2" />
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
end
