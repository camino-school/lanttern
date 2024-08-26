defmodule LantternWeb.StudentStrandReportLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments

  # page components
  alias LantternWeb.StudentStrandReportLive.StrandGoalDetailsComponent

  # shared components
  import LantternWeb.AssessmentsComponents
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
          :for={{goal, entry} <- @strand_goals_student_entries}
          patch={
            ~p"/student_report_card/#{@student_report_card.id}/strand_report/#{@strand_report.id}?tab=assessment&strand_goal_id=#{goal.id}"
          }
          class={[
            "group/card block mt-4",
            "sm:grid sm:grid-cols-[minmax(10px,_3fr)_minmax(10px,_2fr)]"
          ]}
        >
          <%!-- <.card_base class="flex flex-col sm:flex-row items-center gap-4 p-4"> --%>
          <.card_base class={[
            "p-4 group-hover/card:bg-ltrn-mesh-cyan",
            "sm:col-span-2 sm:grid sm:grid-cols-subgrid sm:items-center sm:gap-4"
          ]}>
            <div>
              <p class="text-sm">
                <span class="inline-block mr-1 font-display font-bold text-ltrn-subtle">
                  <%= goal.curriculum_item.curriculum_component.name %>
                </span>
                <%= goal.curriculum_item.name %>
              </p>
              <div
                :if={
                  goal.is_differentiation ||
                    goal.rubric_id ||
                    (entry && entry.report_note) ||
                    (entry && entry.student_report_note) ||
                    goal.report_info
                }
                class="flex items-center gap-4 mt-2"
              >
                <div class="flex flex-wrap items-center gap-1">
                  <.assessment_metadata_icon :if={goal.report_info} type={:info} />
                  <.assessment_metadata_icon :if={goal.rubric_id} type={:rubric} />
                  <.assessment_metadata_icon
                    :if={goal.is_differentiation || goal.has_diff_rubric_for_student}
                    type={:diff}
                  />
                  <.assessment_metadata_icon :if={entry && entry.report_note} type={:teacher_comment} />
                  <.assessment_metadata_icon
                    :if={entry && entry.student_report_note}
                    type={:student_comment}
                  />
                </div>
                <div class="group relative flex items-center gap-1">
                  <div class="w-4 h-4 rounded-sm bg-ltrn-primary"></div>
                  <div class="w-4 h-4 rounded-sm bg-ltrn-secondary"></div>
                  <div class="w-4 h-4 rounded-sm bg-ltrn-light"></div>
                  <.tooltip><%= gettext("Formative assessment pattern") %></.tooltip>
                </div>
              </div>
            </div>
            <.assessment_point_entry_display
              entry={entry}
              show_student_assessment
              class="mt-4 sm:mt-0"
            />
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
