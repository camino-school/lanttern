defmodule LantternWeb.StudentStrandReportLive.AssessmentPointDetailsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  # alias Lanttern.Assessments.AssessmentPoint

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="assessment-point-details" show={true} on_cancel={@on_cancel}>
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
        <div class="flex items-center justify-between gap-2 mt-10">
          <h6 class="font-display font-black text-base">
            <%= if @rubric, do: gettext("Assessment rubric"), else: gettext("Assessment scale") %>
          </h6>
          <.badge :if={@rubric && @rubric.diff_for_rubric_id} theme="diff">
            <%= gettext("Differentiation") %>
          </.badge>
        </div>
        <p :if={@rubric} class="mt-2 text-sm">
          <span class="font-bold"><%= gettext("Criteria:") %></span>
          <%= @rubric.criteria %>
        </p>
        <div class="py-4 overflow-x-auto">
          <.report_scale scale={@assessment_point.scale} rubric={@rubric} />
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
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point(assigns)
      |> assign_rubric()

    {:ok, socket}
  end

  defp assign_assessment_point(socket, assigns) do
    assessment_point =
      Assessments.get_assessment_point(assigns.assessment_point_id,
        preloads: [
          scale: :ordinal_values,
          curriculum_item: [
            :curriculum_component,
            :subjects
          ]
        ]
      )

    assign(socket, :assessment_point, assessment_point)
  end

  defp assign_rubric(%{assigns: %{assessment_point: %{rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    student_id = socket.assigns.student_id
    rubric = Rubrics.get_full_rubric!(rubric_id, check_diff_for_student_id: student_id)

    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(socket), do: assign(socket, :rubric, nil)

  # # event handlers

  # @impl true
  # def handle_event("set_info_level", %{"level" => level}, socket) do
  #   {:noreply, assign(socket, :info_level, level)}
  # end
end
