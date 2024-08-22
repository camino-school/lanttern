defmodule LantternWeb.StudentStrandReportLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  # page components
  alias LantternWeb.StudentStrandReportLive.AssessmentPointDetailsComponent

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <div class="flex items-center gap-2">
          <span class="text-sm font-bold">
            <%= gettext("Information level") %>
          </span>
          <.badge_button
            theme={if @info_level == "full", do: "primary"}
            phx-click={JS.push("set_info_level", value: %{"level" => "full"}, target: @myself)}
          >
            <%= gettext("Full") %>
          </.badge_button>
          <.badge_button
            theme={if @info_level == "simplified", do: "primary"}
            phx-click={JS.push("set_info_level", value: %{"level" => "simplified"}, target: @myself)}
          >
            <%= gettext("Simplified") %>
          </.badge_button>
        </div>
        <div class="mt-4">
          <div
            :for={
              {%AssessmentPoint{
                 id: assessment_point_id,
                 is_differentiation: is_diff,
                 curriculum_item: curriculum_item,
                 scale: scale,
                 rubric: rubric,
                 report_info: report_info
               },
               entry} <-
                @strand_goals_student_entries
            }
            class="rounded mt-4 bg-white shadow"
          >
            <.link patch={
              ~p"/student_report_card/#{@student_report_card.id}/strand_report/#{@strand_report.id}?tab=assessment&assessment_point_id=#{assessment_point_id}"
            }>
              details
            </.link>
            <div class="pt-6 px-6">
              <%= if @info_level == "simplified" do %>
                <p class="text-sm">
                  <span class="inline-block mr-1 font-display font-bold text-ltrn-subtle">
                    <%= curriculum_item.curriculum_component.name %>
                  </span>
                  <%= curriculum_item.name %>
                </p>
              <% else %>
                <p class="mb-2 font-display font-bold text-sm">
                  <%= curriculum_item.curriculum_component.name %>
                </p>
                <p class="text-base">
                  <%= curriculum_item.name %>
                </p>
              <% end %>
              <div
                :if={
                  @info_level == "full" &&
                    (curriculum_item.code || curriculum_item.subjects != [])
                }
                class="flex flex-wrap items-center gap-2 mt-4"
              >
                <.badge :if={curriculum_item.code} theme="dark">
                  <%= curriculum_item.code %>
                </.badge>
                <.badge :if={is_diff} theme="diff">
                  <%= gettext("Curriculum differentiation") %>
                </.badge>
                <.badge :if={rubric && length(rubric.differentiation_rubrics) > 0} theme="diff">
                  <%= gettext("Differentiation rubric") %>
                </.badge>
                <.badge :for={subject <- curriculum_item.subjects}>
                  <%= subject.name %>
                </.badge>
              </div>
            </div>
            <div class="p-6 overflow-x-auto">
              <.report_scale
                scale={scale}
                entry={entry}
                rubric={
                  case rubric && rubric.differentiation_rubrics do
                    [diff_rubric] -> diff_rubric
                    _ -> rubric
                  end
                }
                class="float-left"
              />
              <%!-- fix for padding right. we need the float-left above and this emtpy div below --%>
              <div class="w-6"></div>
            </div>
            <div
              :if={entry && entry.report_note && @info_level == "full"}
              class="sm:pt-6 sm:px-6 last:sm:pb-6"
            >
              <div class="p-4 sm:rounded bg-ltrn-teacher-lightest">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-teacher-accent" />
                  <span class="text-ltrn-teacher-dark"><%= gettext("Teacher comment") %></span>
                </div>
                <.markdown text={entry.report_note} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
            <div
              :if={entry && entry.student_report_note && @info_level == "full"}
              class="sm:pt-6 sm:px-6 last:sm:pb-6"
            >
              <div class="p-4 sm:rounded bg-ltrn-student-lightest">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-student-accent" />
                  <span class="text-ltrn-student-dark">
                    <%= gettext("%{student} comment", student: @student_report_card.student.name) %>
                  </span>
                </div>
                <.markdown text={entry.student_report_note} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
            <div :if={report_info && @info_level == "full"} class="sm:pt-6 sm:px-6 last:sm:pb-6">
              <div class="p-4 sm:rounded bg-ltrn-mesh-cyan">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-information-circle" class="w-6 h-6 text-ltrn-subtle" />
                  <%= gettext("About this assessment") %>
                </div>
                <.markdown text={report_info} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
          </div>
        </div>
      </.responsive_container>
      <.live_component
        :if={@assessment_point_id}
        module={AssessmentPointDetailsComponent}
        id="assessment-point-details-component"
        assessment_point_id={@assessment_point_id}
        student_id={@student_report_card.student_id}
        on_cancel={
          JS.patch(
            ~p"/student_report_card/#{@student_report_card.id}/strand_report/#{@strand_report.id}?tab=assessment"
          )
        }
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:info_level, "full")
      |> assign(:assessment_point_id, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_strand_goals_student_entries(assigns)
      |> assign_assessment_point_id(assigns)
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_strand_goals_student_entries(%{assigns: %{initialized: false}} = socket, assigns) do
    strand_goals_student_entries =
      Assessments.list_strand_goals_student_entries(
        assigns.student_report_card.student_id,
        assigns.strand_report.strand_id
      )

    assessment_points_ids =
      strand_goals_student_entries
      |> Enum.map(fn {assessment_point, _} -> "#{assessment_point.id}" end)

    socket
    |> assign(:strand_goals_student_entries, strand_goals_student_entries)
    |> assign(:assessment_points_ids, assessment_points_ids)
  end

  defp assign_strand_goals_student_entries(socket, _assigns), do: socket

  defp assign_assessment_point_id(socket, %{
         params: %{"assessment_point_id" => assessment_point_id}
       }) do
    # simple guard to prevent viewing details from unrelated assessment points
    assessment_point_id =
      if assessment_point_id in socket.assigns.assessment_points_ids do
        assessment_point_id
      end

    assign(socket, :assessment_point_id, assessment_point_id)
  end

  defp assign_assessment_point_id(socket, _assigns), do: assign(socket, :assessment_point_id, nil)

  # event handlers

  @impl true
  def handle_event("set_info_level", %{"level" => level}, socket) do
    {:noreply, assign(socket, :info_level, level)}
  end
end
