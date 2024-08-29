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
        <p>
          <%= gettext(
            "Here you'll find information about the strand final and formative assessments."
          ) %>
        </p>
        <p class="mt-4 mb-10">
          <%= gettext("You can click the assessment card to view more details about it.") %>
        </p>
        <.link
          :for={{goal, entry, moment_entries} <- @strand_goals_student_entries}
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
                    (entry && entry.report_note) ||
                    (entry && entry.student_report_note) ||
                    goal.report_info ||
                    goal.rubric_id ||
                    moment_entries != []
                }
                class="shrink-0 flex items-center gap-4 max-w-full mt-2"
              >
                <div
                  :if={
                    goal.is_differentiation ||
                      (entry && entry.report_note) ||
                      (entry && entry.student_report_note) ||
                      goal.report_info ||
                      goal.rubric_id
                  }
                  class="flex items-center gap-1"
                >
                  <.assessment_metadata_icon
                    :if={goal.is_differentiation || goal.has_diff_rubric_for_student}
                    type={:diff}
                  />
                  <.assessment_metadata_icon :if={entry && entry.report_note} type={:teacher_comment} />
                  <.assessment_metadata_icon
                    :if={entry && entry.student_report_note}
                    type={:student_comment}
                  />
                  <.assessment_metadata_icon :if={goal.report_info} type={:info} />
                  <.assessment_metadata_icon :if={goal.rubric_id} type={:rubric} />
                </div>
                <div class="group relative flex-1 flex flex-wrap gap-1">
                  <.moment_entry :for={moment_entry <- moment_entries} entry={moment_entry} />
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

  defp assessment_metadata_icon(%{type: :diff} = assigns) do
    ~H"""
    <div class="group relative flex items-center justify-center w-6 h-6 rounded-full bg-ltrn-diff-lighter">
      <span class="font-display font-black text-sm text-ltrn-diff-accent">D</span>
      <.tooltip><%= gettext("Differentiation") %></.tooltip>
    </div>
    """
  end

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

  defp assessment_metadata_icon_attrs(:teacher_comment),
    do:
      {gettext("Teacher comment"), "hero-chat-bubble-oval-left-mini", "bg-ltrn-teacher-lighter",
       "text-ltrn-teacher-accent"}

  defp assessment_metadata_icon_attrs(:student_comment),
    do:
      {gettext("Student comment"), "hero-chat-bubble-oval-left-mini", "bg-ltrn-student-lighter",
       "text-ltrn-student-accent"}

  defp assessment_metadata_icon_attrs(:info),
    do:
      {gettext("Assessment info"), "hero-information-circle-mini", "bg-ltrn-lighter",
       "text-ltrn-subtle"}

  defp assessment_metadata_icon_attrs(:rubric),
    do: {gettext("Has rubric"), "hero-view-columns-mini", "bg-ltrn-lighter", "text-ltrn-subtle"}

  attr :entry, :any, required: true

  defp moment_entry(assigns) do
    {additional_classes, style, text} =
      case assigns.entry do
        %{scale_type: "ordinal"} = entry ->
          {nil,
           "color: #{entry.ordinal_value.text_color}; background-color: #{entry.ordinal_value.bg_color}",
           "•"}

        %{scale_type: "numeric"} ->
          {"text-ltrn-dark bg-ltrn-lighter", nil, "•"}

        nil ->
          {"border border-dashed border-ltrn-light text-ltrn-light", nil, "-"}
      end

    assigns =
      assigns
      |> assign(:additional_classes, additional_classes)
      |> assign(:style, style)
      |> assign(:text, text)

    ~H"""
    <div
      class={[
        "flex-1 flex items-center justify-center w-6 h-6 max-w-6 rounded-sm text-base",
        @additional_classes
      ]}
      style={@style}
    >
      <%= @text %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
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
      |> Enum.map(fn {strand_goal, _, _} -> "#{strand_goal.id}" end)

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
end
