defmodule LantternWeb.CurriculumBNCCLive do
  use LantternWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">BNCC</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link patch={~p"/curriculum"} class="underline">Curriculum</.link>
        <span class="mx-1">/</span>
        <span>BNCC</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p>Exploring: all subjects | all years</p>
        <button class="flex items-center ml-4 text-slate-400">
          <.icon name="hero-funnel-mini" class="text-cyan-400 mr-2" />
          <span class="underline">Change</span>
        </button>
      </div>
    </div>
    <div class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto">
      TBD
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
