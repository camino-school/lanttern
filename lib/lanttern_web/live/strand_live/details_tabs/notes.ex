defmodule LantternWeb.StrandLive.DetailsTabs.Notes do
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      Notes
    </div>
    """
  end
end
