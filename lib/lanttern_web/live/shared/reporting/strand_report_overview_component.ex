defmodule LantternWeb.Reporting.StrandReportOverviewComponent do
  @moduledoc """
  Renders the overview content of a `StrandReport`.

  ### Required attrs

  - `strand_report` - `%StrandReport{}`
  - `student_id`

  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Rubrics
  # alias Lanttern.Rubrics.Rubric

  # shared components
  import LantternWeb.RubricsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <.markdown :if={@description} text={@description} />
        <div :if={@has_assessment_point_rubric} class={if @description, do: "mt-10"}>
          <h3 class="font-display font-black text-xl"><%= gettext("Strand rubrics") %></h3>
          <.assessment_point_rubrics_card
            :for={
              {dom_id, {assessment_point, assessment_point_rubrics}} <-
                @streams.assessment_points_rubrics
            }
            id={dom_id}
            assessment_point={assessment_point}
            assessment_point_rubrics={assessment_point_rubrics}
          />
          <%!-- <.rubric_card :for={{dom_id, rubric} <- @streams.diff_rubrics} id={dom_id} rubric={rubric} /> --%>
        </div>
        <.empty_state :if={!@description && !@has_assessment_point_rubric}>
          <%= gettext("No strand report info yet.") %>
        </.empty_state>
      </.responsive_container>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :assessment_point_rubrics, :list, required: true

  def assessment_point_rubrics_card(assigns) do
    # {is_diff, diff_type} =
    #   case assigns.rubric do
    #     %{is_differentiation: true} -> {true, :curriculum}
    #     %{diff_for_rubric_id: parent_rubric} when not is_nil(parent_rubric) -> {true, :rubric}
    #     _ -> {false, nil}
    #   end

    # assigns =
    #   assigns
    #   |> assign(:is_diff, is_diff)
    #   |> assign(:diff_type, diff_type)

    ~H"""
    <.card_base
      id={@id}
      class={["mt-6", if(@assessment_point.is_differentiation, do: "border border-ltrn-diff-accent")]}
    >
      <div class="pt-4 px-4 text-sm">
        <%!-- <p :if={@is_diff} class="mb-2 text-ltrn-diff-dark font-bold">
          <%= if @diff_type == :curriculum,
            do: gettext("Curriculum differentiation"),
            else: gettext("Rubric differentiation") %>
        </p> --%>
        <p>
          <span class="font-bold">
            <%= @assessment_point.curriculum_item.curriculum_component.name %>
          </span>
          <%= @assessment_point.curriculum_item.name %>
        </p>
      </div>
      <div :for={apr <- @assessment_point_rubrics} class="pt-4 border-t border-ltrn-lighter mt-4">
        <p class="px-4">
          <span class="font-bold"><%= gettext("Criteria:") %></span>
          <%= apr.rubric.criteria %>
        </p>
        <div class="overflow-x-auto">
          <%!-- extra div with min-w-min prevent clamped right padding issue --%>
          <%!-- https://stackoverflow.com/a/26892899 --%>
          <div class="p-4 min-w-min">
            <.rubric_descriptors rubric={apr.rubric} />
          </div>
        </div>
      </div>
    </.card_base>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> stream_configure(
        :assessment_points_rubrics,
        dom_id: fn {ap, _rubrics} -> "assessment-point-#{ap.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_description()
      |> stream_assessment_points_rubrics()

    # |> stream_diff_rubrics()

    {:ok, socket}
  end

  defp assign_description(socket) do
    # we try to use the strand report description
    # and we fall back to the strand description

    description =
      case socket.assigns.strand_report do
        %{description: strand_report_desc} when is_binary(strand_report_desc) ->
          strand_report_desc

        %{strand: %{description: strand_desc}} when is_binary(strand_desc) ->
          strand_desc

        _ ->
          nil
      end

    assign(socket, :description, description)
  end

  defp stream_assessment_points_rubrics(socket) do
    assessment_points_rubrics =
      Rubrics.list_strand_assessment_points_rubrics(socket.assigns.strand_report.strand_id)
      # filter out assessment points without rubrics
      |> Enum.filter(fn
        {_, []} -> false
        {_, _} -> true
      end)

    socket
    |> stream(:assessment_points_rubrics, assessment_points_rubrics)
    |> assign(:has_assessment_point_rubric, assessment_points_rubrics != [])
  end

  # to do: reimplement diff rubrics for student
  # defp stream_diff_rubrics(socket) do
  #   diff_rubrics =
  #     Rubrics.list_strand_diff_rubrics_for_student_id(
  #       socket.assigns.student_id,
  #       socket.assigns.strand_report.strand_id
  #     )

  #   socket
  #   |> stream(:diff_rubrics, diff_rubrics)
  #   |> assign(:has_diff_rubric, diff_rubrics != [])
  # end
end
