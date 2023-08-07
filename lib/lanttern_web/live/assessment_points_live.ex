defmodule LantternWeb.AssessmentPointsLive do
  use LantternWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 class="font-display font-black text-3xl">Assessment points</h1>
    <div class="mt-12">
      <p>
        I want to explore assessment points<br /> in all disciplines<br />
        from all grade 4 classes<br /> in this bimester
      </p>
      <button>Explore</button>
    </div>
    """
  end
end
