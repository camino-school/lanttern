defmodule LantternWeb.StudentStrandReportLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  # page components
  alias LantternWeb.StudentStrandReportLive.StrandGoalDetailsComponent

  # shared components
  # import LantternWeb.AssessmentsComponents
  # import LantternWeb.ReportingComponents

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
        <.link
          :for={
            {%AssessmentPoint{
               id: strand_goal_id,
               is_differentiation: is_diff,
               curriculum_item: curriculum_item,
               # scale: scale,
               rubric: rubric,
               report_info: report_info
             },
             entry} <-
              @strand_goals_student_entries
          }
          patch={
            ~p"/student_report_card/#{@student_report_card.id}/strand_report/#{@strand_report.id}?tab=assessment&strand_goal_id=#{strand_goal_id}"
          }
          class="block mt-4"
        >
          <.card_base>
            <div class="flex items-center gap-4 p-4">
              <p class="flex-1 text-sm">
                <span class="inline-block mr-1 font-display font-bold text-ltrn-subtle">
                  <%= curriculum_item.curriculum_component.name %>
                </span>
                <%= curriculum_item.name %>
              </p>
              entry TBD <%!-- <.assessment_point_entry_display entry={entry} /> --%>
            </div>
            <div class="flex items-center gap-2 px-2 pb-2">
              <div
                :if={
                  is_diff ||
                    rubric ||
                    (entry && entry.report_note) ||
                    (entry && entry.student_report_note) ||
                    report_info
                }
                class="flex flex-wrap items-center gap-1"
              >
                <.assessment_metadata_icon :if={report_info} type={:info} />
                <.assessment_metadata_icon :if={rubric} type={:rubric} />
                <.assessment_metadata_icon
                  :if={is_diff || (rubric && rubric.is_differentiation)}
                  type={:diff}
                />
                <.assessment_metadata_icon :if={entry && entry.report_note} type={:teacher_comment} />
                <.assessment_metadata_icon
                  :if={entry && entry.student_report_note}
                  type={:student_comment}
                />
              </div>
              <div class="flex-1 flex h-4">
                Formative TBD
                <div class="flex-1 bg-ltrn-primary"></div>
                <div class="flex-1 bg-ltrn-secondary"></div>
                <div class="flex-1 bg-ltrn-light"></div>
              </div>
            </div>
            <%!-- <div
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
            </div> --%>
          </.card_base>
        </.link>
      </.responsive_container>
      <.live_component
        :if={@strand_goal_id}
        module={StrandGoalDetailsComponent}
        id="assessment-point-details-component"
        strand_goal_id={@strand_goal_id}
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

  attr :type, :atom, required: true

  defp assessment_metadata_icon(assigns) do
    {text, icon_name, bg, color} =
      assessment_metadata_icon_attrs(assigns.type)

    assigns =
      assigns
      |> assign(:text, text)
      |> assign(:icon_name, icon_name)
      |> assign(:bg, bg)
      |> assign(:color, color)

    ~H"""
    <div class={["group relative flex items-center justify-center w-6 h-6 rounded-full", @bg]}>
      <.icon name={@icon_name} class={@color} />
      <.tooltip><%= @text %></.tooltip>
    </div>
    """
  end

  defp assessment_metadata_icon_attrs(:info),
    do:
      {gettext("Assessment info"), "hero-information-circle-mini", "bg-ltrn-mesh-cyan",
       "text-ltrn-primary"}

  defp assessment_metadata_icon_attrs(:rubric),
    do:
      {gettext("Has rubric"), "hero-view-columns-mini", "bg-ltrn-mesh-cyan", "text-ltrn-primary"}

  defp assessment_metadata_icon_attrs(:diff),
    do:
      {gettext("Differentiation"), "hero-user-mini", "bg-ltrn-diff-lighter",
       "text-ltrn-diff-accent"}

  defp assessment_metadata_icon_attrs(:teacher_comment),
    do:
      {gettext("Teacher comment"), "hero-chat-bubble-oval-left-mini", "bg-ltrn-teacher-lighter",
       "text-ltrn-teacher-accent"}

  defp assessment_metadata_icon_attrs(:student_comment),
    do:
      {gettext("Student comment"), "hero-chat-bubble-oval-left-mini", "bg-ltrn-student-lighter",
       "text-ltrn-student-accent"}

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:info_level, "full")
      |> assign(:strand_goal_id, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_strand_goals_student_entries(assigns)
      |> assign_strand_goal_id(assigns)
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_strand_goals_student_entries(%{assigns: %{initialized: false}} = socket, assigns) do
    strand_goals_student_entries =
      Assessments.list_strand_goals_student_entries(
        assigns.student_report_card.student_id,
        assigns.strand_report.strand_id
      )

    strand_goals_ids =
      strand_goals_student_entries
      |> Enum.map(fn {strand_goal, _} -> "#{strand_goal.id}" end)

    socket
    |> assign(:strand_goals_student_entries, strand_goals_student_entries)
    |> assign(:strand_goals_ids, strand_goals_ids)
  end

  defp assign_strand_goals_student_entries(socket, _assigns), do: socket

  defp assign_strand_goal_id(socket, %{
         params: %{"strand_goal_id" => strand_goal_id}
       }) do
    # simple guard to prevent viewing details from unrelated assessment points
    strand_goal_id =
      if strand_goal_id in socket.assigns.strand_goals_ids do
        strand_goal_id
      end

    assign(socket, :strand_goal_id, strand_goal_id)
  end

  defp assign_strand_goal_id(socket, _assigns), do: assign(socket, :strand_goal_id, nil)

  # event handlers

  @impl true
  def handle_event("set_info_level", %{"level" => level}, socket) do
    {:noreply, assign(socket, :info_level, level)}
  end
end
