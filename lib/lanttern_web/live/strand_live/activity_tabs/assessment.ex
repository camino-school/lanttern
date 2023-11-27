defmodule LantternWeb.StrandLive.ActivityTabs.Assessment do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias LantternWeb.AssessmentPointLive.ActivityAssessmentPointFormComponent
  alias LantternWeb.AssessmentPointLive.EntryEditorComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
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
      </div>
      <div
        id="activity-assessment-points-slider"
        class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto"
        phx-hook="Slider"
      >
        <%= if length(@assessment_points) > 0 do %>
          <div class="sticky top-0 z-20 flex items-stretch gap-4 pr-6 mb-2 bg-white">
            <div class="sticky left-0 z-20 shrink-0 w-40 bg-white"></div>
            <.assessment_point :for={ap <- @assessment_points} assessment_point={ap} />
            <div class="shrink-0 w-2"></div>
          </div>
          <.student_and_entries
            :for={{student, entries} <- @students_entries}
            assessment_points={@assessment_points}
            student={student}
            entries={entries}
          />
        <% else %>
          <.empty_state>No assessment points found</.empty_state>
        <% end %>
      </div>
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
          strand_id={@activity.strand_id}
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

  # function components

  attr :assessment_point, AssessmentPoint, required: true

  def assessment_point(assigns) do
    ~H"""
    <div class="shrink-0 w-40 pt-6 pb-2 bg-white">
      <div class="flex gap-1 items-center mb-1 text-xs text-ltrn-subtle">
        <.icon name="hero-calendar-mini" />
        <%= Timex.format!(@assessment_point.datetime, "{Mshort} {0D}") %>
      </div>
      <.link
        navigate={~p"/assessment_points/#{@assessment_point.id}"}
        class="text-xs hover:underline line-clamp-2"
      >
        <%= @assessment_point.name %>
      </.link>
    </div>
    """
  end

  attr :student, Lanttern.Schools.Student, required: true
  attr :entries, :list, required: true
  attr :assessment_points, :list, required: true

  def student_and_entries(%{assessment_points: assessment_points, entries: entries} = assigns) do
    assigns =
      assigns
      |> assign(
        :assessment_points_entries,
        Enum.zip(assessment_points, entries)
      )

    ~H"""
    <div class="flex items-stretch gap-4">
      <.icon_with_name
        class="sticky left-0 z-10 shrink-0 w-40 px-6 bg-white"
        profile_name={@student.name}
      />
      <%= for {assessment_point, entry} <- @assessment_points_entries do %>
        <div class="shrink-0 w-40 min-h-[4rem] py-1">
          <.live_component
            module={EntryEditorComponent}
            id={"student-#{@student.id}-entry-for-#{assessment_point.id}"}
            student={@student}
            assessment_point={assessment_point}
            entry={entry}
            class="w-full h-full"
            wrapper_class="w-full h-full"
          >
            <:marking_input class="w-full h-full" />
          </.live_component>
          <%!-- <%= if entry == nil do %>
            <.base_input
              class="w-full h-full rounded-sm font-mono text-center bg-ltrn-subtle"
              value="N/A"
              name="na"
              readonly
            />
          <% else %>
            <.live_component
              module={AssessmentPointEntryEditorComponent}
              id={entry.id}
              entry={entry}
              class="w-full h-full"
              wrapper_class="w-full h-full"
            >
              <:marking_input class="w-full h-full" />
            </.live_component>
          <% end %> --%>
        </div>
      <% end %>
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
    %{
      assessment_points: assessment_points,
      students_entries: students_entries
    } = Assessments.build_activity_assessment_grid(activity.id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:assessment_points, assessment_points)
     |> assign(:students_entries, students_entries)
     |> stream(:assessment_points, Assessments.list_activity_assessment_points(activity.id))}
  end
end
