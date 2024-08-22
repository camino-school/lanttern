defmodule LantternWeb.StudentStrandReportLive.AssessmentPointDetailsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  # alias Lanttern.Assessments.AssessmentPoint

  # # shared components
  # import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="assessment-point-details" show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Goal assessment details") %></:title>
        <p class="mb-2 font-display font-bold text-sm">
          <%= @assessment_point.curriculum_item.curriculum_component.name %>
        </p>
        <p class="text-base">
          <%= @assessment_point.curriculum_item.name %>
        </p>
        <div class="flex flex-wrap items-center gap-2 mt-4">
          <.badge :if={@assessment_point.curriculum_item.code} theme="dark">
            <%= @assessment_point.curriculum_item.code %>
          </.badge>
          <.badge :if={@assessment_point.is_differentiation} theme="diff">
            <%= gettext("Curriculum differentiation") %>
          </.badge>
          <%!-- <.badge :if={rubric && length(rubric.differentiation_rubrics) > 0} theme="diff">
            <%= gettext("Differentiation rubric") %>
          </.badge> --%>
          <.badge :for={subject <- @assessment_point.curriculum_item.subjects}>
            <%= subject.name %>
          </.badge>
        </div>
        <div :if={@assessment_point.report_info} class="p-4 mt-6 rounded bg-ltrn-mesh-cyan">
          <div class="flex items-center gap-2 font-bold text-sm">
            <.icon name="hero-information-circle" class="w-6 h-6 text-ltrn-subtle" />
            <%= gettext("About this assessment") %>
          </div>
          <.markdown text={@assessment_point.report_info} size="sm" class="max-w-none mt-4" />
        </div>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  # @impl true
  # def mount(socket) do
  #   socket =
  #     socket
  #     |> assign(:info_level, "full")

  #   {:ok, socket}
  # end

  @impl true
  def update(assigns, socket) do
    assessment_point =
      Assessments.get_assessment_point(assigns.assessment_point_id,
        preloads: [
          curriculum_item: [
            :curriculum_component,
            :subjects
          ]
        ]
      )
      |> IO.inspect()

    socket =
      socket
      |> assign(assigns)
      |> assign(:assessment_point, assessment_point)

    {:ok, socket}
  end

  # # event handlers

  # @impl true
  # def handle_event("set_info_level", %{"level" => level}, socket) do
  #   {:noreply, assign(socket, :info_level, level)}
  # end
end
