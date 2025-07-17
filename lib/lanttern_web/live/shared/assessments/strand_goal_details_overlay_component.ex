defmodule LantternWeb.Assessments.StrandGoalDetailsOverlayComponent do
  @moduledoc """
  Renders a strand goal info overlay.

  ### Required attrs:

  - `strand_goal_id`
  - `student_id`
  - `on_cancel` - a `%JS{}` struct to execute on overlay close
  - `prevent_preview` - should be `true` when user is not allowed to view the parent report card
  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Reporting
  alias Lanttern.Rubrics
  alias Lanttern.SupabaseHelpers

  # shared components
  import LantternWeb.AssessmentsComponents
  import LantternWeb.AttachmentsComponents
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="assessment-point-details" show={true} on_cancel={@on_cancel}>
        <p class="mb-2 font-display font-bold text-sm">
          <%= @strand_goal.curriculum_item.curriculum_component.name %>
        </p>
        <p class="text-base">
          <%= @strand_goal.curriculum_item.name %>
        </p>
        <div class="flex flex-wrap items-center gap-2 mt-4">
          <.badge :if={@strand_goal.curriculum_item.code} theme="dark">
            <%= @strand_goal.curriculum_item.code %>
          </.badge>
          <.badge :if={@strand_goal.is_differentiation} theme="diff">
            <%= gettext("Curriculum differentiation") %>
          </.badge>
          <.badge :for={subject <- @strand_goal.curriculum_item.subjects}>
            <%= subject.name %>
          </.badge>
        </div>
        <div class="py-10 border-b-2 border-ltrn-lighter">
          <.assessment_point_entry_display
            entry={@entry}
            show_student_assessment
            prevent_preview={@prevent_preview}
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
            <.icon :if={@rubric} name="hero-view-columns" class="w-6 h-6" />
            <%= if @rubric, do: gettext("Assessment rubric"), else: gettext("Assessment scale") %>
          </h5>
          <.badge :if={@rubric && @rubric.is_differentiation} theme="diff">
            <%= gettext("Differentiation") %>
          </.badge>
        </div>
        <p :if={@rubric} class="mt-2 text-sm">
          <span class="font-bold"><%= gettext("Criteria:") %></span>
          <%= @rubric.criteria %>
        </p>
        <div class="py-4 overflow-x-auto">
          <.report_scale
            scale={@strand_goal.scale}
            rubric={@rubric}
            entry={!@prevent_preview && @entry}
          />
        </div>
        <div :if={@entry && @entry.evidences != []} class="mt-10">
          <h5 class="flex items-center gap-2 font-display font-black text-base">
            <.icon name="hero-paper-clip" class="w-6 h-6" />
            <%= gettext("Learning evidences") %>
          </h5>
          <.attachments_list
            id="goals-attachments-list"
            attachments={@entry.evidences}
            on_signed_url={&JS.push("signed_url", value: %{"url" => &1}, target: @myself)}
          />
        </div>
        <div :if={@has_formative_assessment} class="mt-10">
          <h5 class="font-display font-black text-base"><%= gettext("Formative assessment") %></h5>
          <div id="moments-assessment-points-and-entries" phx-update="stream">
            <div
              :for={
                {dom_id, {moment, assessment_points_and_entries}} <-
                  @streams.moments_assessment_points_and_entries
              }
              id={dom_id}
            >
              <h6 class="mt-6 font-display font-black text-base text-ltrn-subtle">
                <%= moment.name %>
              </h6>
              <.moment_assessment_point_entry
                :for={{assessment_point, entry} <- assessment_points_and_entries}
                class="pt-4 mt-4 border-t border-ltrn-lighter"
                assessment_point={assessment_point}
                entry={entry}
                id={"#{assessment_point.id}-#{entry.id}"}
                on_signed_url={&JS.push("signed_url", value: %{"url" => &1}, target: @myself)}
              />
            </div>
          </div>
        </div>
        <div :if={@strand_goal.report_info} class="mt-10">
          <h5 class="flex items-center gap-2 font-display font-black text-base">
            <.icon name="hero-information-circle" class="w-6 h-6" />
            <%= gettext("About this assessment") %>
          </h5>
          <.markdown text={@strand_goal.report_info} class="max-w-none mt-4" />
        </div>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:prevent_preview, false)
      |> stream_configure(
        :moments_assessment_points_and_entries,
        dom_id: fn
          {moment, _assessment_points_and_entries} -> "moment-#{moment.id}"
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
      |> assign_strand_goal(assigns)
      |> assign_entry()
      |> assign_rubric()
      |> stream_moments_assessment_points_and_entries()

    {:ok, socket}
  end

  @impl true
  def handle_event("signed_url", %{"url" => url}, socket) do
    case SupabaseHelpers.create_signed_url(url) do
      {:ok, external} -> {:noreply, push_event(socket, "open_external", %{url: external})}
      {:error, :invalid_url} -> {:noreply, put_flash(socket, :error, gettext("Invalid URL"))}
    end
  end

  defp assign_strand_goal(socket, assigns) do
    strand_goal =
      Assessments.get_assessment_point(assigns.strand_goal_id,
        preloads: [
          scale: :ordinal_values,
          curriculum_item: [
            :curriculum_component,
            :subjects
          ]
        ]
      )

    assign(socket, :strand_goal, strand_goal)
  end

  defp assign_entry(socket) do
    entry =
      Assessments.get_assessment_point_student_entry(
        socket.assigns.strand_goal.id,
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

  defp assign_rubric(%{assigns: %{strand_goal: %{rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    rubric = Rubrics.get_full_rubric!(rubric_id)
    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(socket), do: assign(socket, :rubric, nil)

  defp stream_moments_assessment_points_and_entries(socket) do
    moments_assessment_points_and_entries =
      Reporting.list_strand_goal_moments_and_student_entries(
        socket.assigns.strand_goal,
        socket.assigns.student_id
      )

    has_formative_assessment = moments_assessment_points_and_entries != []

    socket
    |> stream(:moments_assessment_points_and_entries, moments_assessment_points_and_entries)
    |> assign(:has_formative_assessment, has_formative_assessment)
  end
end
