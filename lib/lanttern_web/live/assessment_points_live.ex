defmodule LantternWeb.AssessmentPointsLive do
  use LantternWeb, :live_view

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
        <button
          class="flex items-center mt-4 font-display font-black text-lg text-slate-400"
          phx-click="create-assessment-point"
        >
          Create assessment point <.icon name="hero-plus" class="text-cyan-400 ml-2" />
        </button>
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
    <.live_component
      module={LantternWeb.AssessmentPointCreateOverlayComponent}
      id={:new}
      show={@is_creating_assessment_point}
    />
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
    {:ok, assign(socket, :is_creating_assessment_point, false)}
  end

  def handle_event("create-assessment-point", _params, socket) do
    {:noreply, assign(socket, :is_creating_assessment_point, true)}
  end

  def handle_event("cancel-create-assessment-point", _params, socket) do
    {:noreply, assign(socket, :is_creating_assessment_point, false)}
  end

  def handle_info({:assessment_point_created, assessment_point}, socket) do
    socket =
      socket
      |> assign(:is_creating_assessment_point, false)
      |> put_flash(:info, "Assessment point \"#{assessment_point.name}\" created!")
      |> push_navigate(to: ~p"/assessment_points/#{assessment_point.id}")

    {:noreply, socket}
  end
end
