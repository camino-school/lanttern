defmodule LantternWeb.StrandLive.ActivityTabs.Assessment do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias LantternWeb.AssessmentPointLive.ActivityAssessmentPointFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      Assessment TBD
      <.link patch={~p"/strands/activity/#{@activity}/assessment_point/new"}>
        Add
      </.link>
      <ul phx-update="stream" id="activity-assessment-points">
        <ol :for={{dom_id, assessment_point} <- @streams.assessment_points} id={dom_id}>
          <%= assessment_point.name %>
        </ol>
      </ul>
      <.slide_over
        :if={@live_action in [:new_assessment_point, :edit_assessment_point]}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/activity/#{@activity}?tab=assessment")}
      >
        <:title>Assessment Point</:title>
        <.live_component
          module={ActivityAssessmentPointFormComponent}
          id={:new}
          activity_id={@activity.id}
          notify_component={@myself}
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#assessment-point-form-overlay")}
          >
            Cancel
          </.button>
          <.button type="submit" form="activity-assessment-point-form" phx-disable-with="Saving...">
            Save
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(
        %{action: {ActivityAssessmentPointFormComponent, {:created, assessment_point}}},
        socket
      ) do
    {:ok,
     socket
     |> stream_insert(:assessment_points, assessment_point)}
  end

  def update(%{activity: activity} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> stream(:assessment_points, Assessments.list_activity_assessment_points(activity.id))}
  end
end
