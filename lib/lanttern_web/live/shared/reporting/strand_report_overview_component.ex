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
  alias Lanttern.Rubrics.Rubric

  # shared components
  alias LantternWeb.Rubrics.RubricDescriptorsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <.markdown :if={@description} text={@description} />
        <div :if={@has_rubric} id="curriculum-items-student-rubrics" phx-update="stream">
          <.card_base
            :for={{dom_id, {goal, rubrics}} <- @streams.goals_rubrics}
            id={dom_id}
            class={[
              "p-6 mt-6",
              if(goal.is_differentiation, do: "border border-ltrn-diff-accent")
            ]}
          >
            <div class="flex items-center gap-4">
              <div class="flex-1">
                <.badge :if={goal.is_differentiation} theme="diff" class="mb-2">
                  <%= gettext("Curriculum differentiation") %>
                </.badge>
                <p>
                  <strong class="inline-block mr-2 font-display font-bold">
                    <%= goal.curriculum_item.curriculum_component.name %>
                  </strong>
                  <%= goal.curriculum_item.name %>
                </p>
              </div>
            </div>
            <.rubric
              :for={rubric <- rubrics}
              class="pt-6 border-t border-ltrn-lighter mt-6"
              id={"rubric-#{rubric.id}"}
              goal={goal}
              rubric={rubric}
            />
          </.card_base>
        </div>
        <%!-- <div :if={@has_rubric} class={if @description, do: "mt-10"}>
          <h3 class="font-display font-black text-xl"><%= gettext("Strand rubrics") %></h3>
          <.rubric_card :for={{dom_id, rubric} <- @streams.rubrics} id={dom_id} rubric={rubric} />
          <.rubric_card :for={{dom_id, rubric} <- @streams.diff_rubrics} id={dom_id} rubric={rubric} />
        </div> --%>
        <.empty_state :if={!@description && !@has_rubric}>
          <%= gettext("No strand report info yet.") %>
        </.empty_state>
      </.responsive_container>
    </div>
    """
  end

  attr :goal, AssessmentPoint, required: true
  attr :class, :any, default: nil
  attr :id, :string, required: true
  attr :rubric, Rubric, required: true

  def rubric(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div class="flex items-center gap-2 mb-6">
        <div class="flex-1 pr-2">
          <.badge :if={@rubric.is_differentiation} theme="diff" class="mb-2">
            <%= gettext("Rubric differentiation") %>
          </.badge>
          <p class="font-display font-black">
            <%= gettext("Rubric criteria") %>: <%= @rubric.criteria %>
          </p>
        </div>
      </div>
      <.live_component
        module={RubricDescriptorsComponent}
        id={"#{@id}-rubric-descriptors"}
        rubric={@rubric}
        class="overflow-x-auto"
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> stream_configure(
        :goals_rubrics,
        dom_id: fn
          {goal, _rubrics} -> "goal-#{goal.id}"
          _ -> ""
        end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_description()
      |> stream_goals_rubrics()

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

  defp stream_goals_rubrics(socket) do
    opts =
      if socket.assigns.allow_access,
        do: [only_with_entries: true],
        else: []

    goals_rubrics =
      Rubrics.list_student_strand_rubrics_grouped_by_goal(
        socket.assigns.student_id,
        socket.assigns.strand_report.strand_id,
        opts
      )

    socket
    |> stream(:goals_rubrics, goals_rubrics)
    |> assign(:has_rubric, goals_rubrics != [])
  end
end
