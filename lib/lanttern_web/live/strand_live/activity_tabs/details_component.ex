defmodule LantternWeb.StrandLive.ActivityTabs.DetailsComponent do
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <.markdown text={@activity.description} />
    </div>
    """
  end
end
