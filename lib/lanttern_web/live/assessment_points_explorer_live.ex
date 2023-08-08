defmodule LantternWeb.AssessmentPointsExplorerLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [assessment_points: []]}
  end

  def handle_params(_params, _uri, socket) do
    assessment_points = Assessments.list_assessment_points()

    {:noreply, assign(socket, :assessment_points, assessment_points)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment points explorer</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link patch={~p"/assessment_points"} class="underline">Assessment points</.link>
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
      <ul>
        <.assessment_point :for={ap <- @assessment_points} assessment_point={ap} />
      </ul>
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true

  def assessment_point(assigns) do
    ~H"""
    <li>
      <.link patch={~p"/assessment_points/#{@assessment_point.id}"} class="underline">
        <%= @assessment_point.name %>
      </.link>
    </li>
    """
  end
end
