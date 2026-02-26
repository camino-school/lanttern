defmodule LantternWeb.Assessments.StudentAssessmentPointDetailsOverlayComponent do
  @moduledoc """
  Renders an assessment point info overlay.

  ### Required attrs:

  - `assessment_point_id`
  - `student_id`
  - `on_cancel` - a `%JS{}` struct to execute on overlay close
  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Rubrics

  # shared components
  import LantternWeb.AssessmentsComponents
  import LantternWeb.AttachmentsComponents
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="assessment-point-details" show={true} on_cancel={@on_cancel}>
        <h3 class="mb-2 font-display font-bold text-lg">
          {@assessment_point.name}
        </h3>
        <.markdown
          :if={@assessment_point.report_info}
          text={@assessment_point.report_info}
          class="mt-4"
        />
        <div class="mt-10">
          <.assessment_point_entry_display
            entry={@entry}
            show_student_assessment
          />
          <.comment_area :if={@entry && @entry.report_note} comment={@entry.report_note} class="mt-4" />
          <.comment_area
            :if={@entry && @entry.student_report_note}
            comment={@entry.student_report_note}
            class="mt-4"
            type="student"
          />
        </div>
        <div class="flex items-center justify-between gap-2 mt-10">
          <h5 class="flex items-center gap-2 font-display font-black text-base">
            <.icon :if={@rubric} name="hero-view-columns" />
            {if @rubric, do: gettext("Assessment rubric"), else: gettext("Assessment scale")}
          </h5>
          <.badge :if={@rubric && @rubric.is_differentiation} theme="diff">
            {gettext("Differentiation")}
          </.badge>
        </div>
        <p :if={@rubric} class="mt-2 text-sm">
          <span class="font-bold">{gettext("Criteria:")}</span> {@rubric.criteria}
        </p>
        <div class="py-4 overflow-x-auto">
          <.report_scale
            scale={@assessment_point.scale}
            rubric={@rubric}
            entry={@entry}
          />
        </div>
        <div :if={@entry && @entry.evidences != []} class="mt-10">
          <h5 class="flex items-center gap-2 font-display font-black text-base">
            <.icon name="hero-paper-clip" class="w-6 h-6" /> {gettext("Learning evidences")}
          </h5>
          <.attachments_list
            id="goals-attachments-list"
            attachments={@entry.evidences}
          />
        </div>
        <div class="mt-10">
          <h5 class="font-display font-black text-base">
            {gettext("Curriculum")}
          </h5>
          <p class="text-base mt-4">
            {@assessment_point.curriculum_item.name}
          </p>
          <div class="flex flex-wrap items-center gap-2 mt-4">
            <.badge theme="dark">
              {@assessment_point.curriculum_item.curriculum_component.name}
            </.badge>
            <.badge :if={@assessment_point.curriculum_item.code} theme="dark">
              {@assessment_point.curriculum_item.code}
            </.badge>
            <.badge :if={@assessment_point.is_differentiation} theme="diff">
              {gettext("Curriculum differentiation")}
            </.badge>
            <.badge :for={subject <- @assessment_point.curriculum_item.subjects}>
              {subject.name}
            </.badge>
          </div>
        </div>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{assessment_point: %AssessmentPoint{}} = assigns, socket),
    do: {:ok, assign(socket, assigns)}

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point(assigns)
      |> assign_entry()
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

  defp assign_entry(socket) do
    entry =
      Assessments.get_assessment_point_student_entry(
        socket.assigns.assessment_point.id,
        socket.assigns.student_id,
        preloads: [:scale, :ordinal_value, :student_ordinal_value, :evidences]
      )

    assign(socket, :entry, entry)
  end

  defp assign_rubric(%{assigns: %{entry: %{differentiation_rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    rubric = Rubrics.get_full_rubric!(rubric_id)
    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(%{assigns: %{assessment_point: %{rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    rubric = Rubrics.get_full_rubric!(rubric_id)
    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(socket), do: assign(socket, :rubric, nil)
end
