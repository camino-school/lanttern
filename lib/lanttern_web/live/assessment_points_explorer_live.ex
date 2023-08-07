defmodule LantternWeb.AssessmentPointsExplorerLive do
  use LantternWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment points explorer</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link href={~p"/assessment-points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <span>Explorer</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p>Exploring: all disciplines | all grade 4 classes | this bimester</p>
        <button class="flex items-center ml-4 text-slate-400">
          <.icon name="hero-funnel-mini" class="text-cyan-400 mr-2" />
          <span class="underline">Change</span>
        </button>
      </div>
    </div>
    <div class="w-full p-20 mt-6 rounded shadow-xl bg-white">
      <.link href={~p"/assessment-points/1"} class="underline">Details</.link>
    </div>
    """
  end
end
