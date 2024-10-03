defmodule LantternWeb.Reporting.StrandReportAssessmentComponent do
  @moduledoc """
  Renders assessment info related to a `StrandReport`.

  ### Required attrs:

  -`strand_report` - `%StrandReport{}`
  -`student_report_card` - `%StudentReportCard{}`
  -`params` - the URL params from parent view `handle_params/3`
  -`base_path` - the base URL path for overlay navigation control
  -`current_profile` - the current `%Profile{}` from `current_user`
  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Reporting

  # page components
  alias LantternWeb.Assessments.StrandGoalDetailsOverlayComponent

  # shared components
  alias LantternWeb.Assessments.EntryParticleComponent
  import LantternWeb.AssessmentsComponents
  import LantternWeb.AttachmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <h2 class="font-display font-black text-2xl"><%= gettext("Goals assessment entries") %></h2>
        <p class="mt-4">
          <%= gettext(
            "Here you'll find information about the strand final and formative assessments."
          ) %>
        </p>
        <p class="mt-4 mb-10">
          <%= gettext("You can click the assessment card to view more details about it.") %>
        </p>
        <.goal_card
          :for={{goal, entry, moment_entries, has_evidence} <- @strand_goals_student_entries}
          patch={"#{@base_path}&strand_goal_id=#{goal.id}"}
          goal={goal}
          entry={entry}
          moment_entries={moment_entries}
          has_evidence={has_evidence}
          prevent_preview={@prevent_final_assessment_preview}
        />
        <.empty_state :if={!@has_strand_goals_with_student_entries}>
          <%= gettext("No assessment entries for this strand yet") %>
        </.empty_state>
        <div :if={@has_strand_evidences} class="mt-10">
          <div class="flex items-center gap-2">
            <.icon name="hero-paper-clip" class="w-6 h-6" />
            <h4 class="font-display font-black">
              <%= gettext("All strands evidences") %>
            </h4>
          </div>
          <div id="strand-evidences" phx-update="stream">
            <.attachment_card
              :for={{dom_id, {evidence, goal_id, moment_name}} <- @streams.strand_evidences}
              id={dom_id}
              class="mt-6"
              attachment={evidence}
            >
              <p class="mt-4 text-xs">
                <%= if moment_name do
                  "#{gettext("In the context of")} #{moment_name}."
                end %>
                <.link
                  patch={"#{@base_path}&strand_goal_id=#{goal_id}"}
                  class="underline hover:text-ltrn-subtle"
                >
                  <%= gettext("View assessment details") %>
                </.link>
              </p>
            </.attachment_card>
          </div>
        </div>
        <div :if={@has_strand_goals_without_student_entries} class="mt-10">
          <div class="flex items-center gap-2">
            <h4 class="flex-1 font-display font-black text-ltrn-subtle">
              <%= gettext("Goals without assessment entries") %>
            </h4>
            <.toggle_expand_button
              id="toggle-strand-goals-without-student-entries"
              target_selector="#strand-goals-without-student-entries"
              initial_is_expanded={false}
            />
          </div>
          <div id="strand-goals-without-student-entries" class="hidden">
            <.goal_card
              :for={
                {goal, entry, moment_entries, has_evidence} <- @strand_goals_without_student_entries
              }
              patch={"#{@base_path}&strand_goal_id=#{goal.id}"}
              goal={goal}
              entry={entry}
              moment_entries={moment_entries}
              has_evidence={has_evidence}
              prevent_preview={@prevent_final_assessment_preview}
            />
          </div>
        </div>
      </.responsive_container>
      <.live_component
        :if={@strand_goal_id}
        module={StrandGoalDetailsOverlayComponent}
        id="assessment-point-details-component"
        strand_goal_id={@strand_goal_id}
        student_id={@student_report_card.student_id}
        prevent_preview={@prevent_final_assessment_preview}
        on_cancel={JS.patch(@base_path)}
      />
    </div>
    """
  end

  attr :goal, AssessmentPoint, required: true
  attr :entry, :any, required: true
  attr :moment_entries, :list, required: true
  attr :has_evidence, :boolean, required: true
  attr :patch, :string, required: true
  attr :prevent_preview, :boolean, required: true

  defp goal_card(assigns) do
    %{
      goal: goal,
      entry: entry,
      moment_entries: moment_entries,
      has_evidence: has_evidence
    } = assigns

    render_icons_area =
      goal.is_differentiation ||
        (entry && entry.report_note) ||
        (entry && entry.student_report_note) ||
        has_evidence ||
        goal.report_info ||
        goal.rubric_id

    render_extra_fields_area =
      render_icons_area ||
        moment_entries != []

    assigns =
      assigns
      |> assign(:render_extra_fields_area, render_extra_fields_area)
      |> assign(:render_icons_area, render_extra_fields_area)

    ~H"""
    <.link
      patch={@patch}
      class={[
        "group/card block mt-4",
        "sm:grid sm:grid-cols-[minmax(10px,_3fr)_minmax(10px,_2fr)]"
      ]}
    >
      <.card_base class={[
        "p-4 group-hover/card:bg-ltrn-mesh-cyan",
        "sm:col-span-2 sm:grid sm:grid-cols-subgrid sm:items-center sm:gap-4"
      ]}>
        <div>
          <p class="text-sm">
            <span class="inline-block mr-1 font-display font-bold text-ltrn-subtle">
              <%= @goal.curriculum_item.curriculum_component.name %>
            </span>
            <%= @goal.curriculum_item.name %>
          </p>
          <div
            :if={@render_extra_fields_area}
            class="shrink-0 flex items-center gap-4 max-w-full mt-2"
          >
            <div :if={@render_icons_area} class="flex items-center gap-1">
              <.assessment_metadata_icon
                :if={@goal.is_differentiation || @goal.has_diff_rubric_for_student}
                type={:diff}
              />
              <.assessment_metadata_icon :if={@entry && @entry.report_note} type={:teacher_comment} />
              <.assessment_metadata_icon
                :if={@entry && @entry.student_report_note}
                type={:student_comment}
              />
              <.assessment_metadata_icon :if={@has_evidence} type={:evidences} />
              <.assessment_metadata_icon :if={@goal.report_info} type={:info} />
              <.assessment_metadata_icon :if={@goal.rubric_id} type={:rubric} />
            </div>
            <div class="group relative flex-1 flex flex-wrap gap-1">
              <.live_component
                :for={moment_entry <- @moment_entries}
                module={EntryParticleComponent}
                id={moment_entry.id}
                entry={moment_entry}
                class="flex-1"
              />
              <.tooltip><%= gettext("Formative assessment pattern") %></.tooltip>
            </div>
          </div>
        </div>
        <.assessment_point_entry_display
          entry={@entry}
          show_student_assessment
          prevent_preview={@prevent_preview}
          class="mt-4 sm:mt-0"
        />
      </.card_base>
    </.link>
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

  defp assessment_metadata_icon_attrs(:evidences),
    do:
      {gettext("With learning evidences"), "hero-paper-clip-mini", "bg-ltrn-lighter",
       "text-ltrn-subtle"}

  defp assessment_metadata_icon_attrs(:info),
    do:
      {gettext("Assessment info"), "hero-information-circle-mini", "bg-ltrn-lighter",
       "text-ltrn-subtle"}

  defp assessment_metadata_icon_attrs(:rubric),
    do: {gettext("Has rubric"), "hero-view-columns-mini", "bg-ltrn-lighter", "text-ltrn-subtle"}

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:strand_goal_id, nil)
      |> assign(:initialized, false)
      |> stream_configure(
        :strand_evidences,
        dom_id: fn {a, _, _} -> "attachment-#{a.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_strand_goals_student_entries(assigns)
      |> assign_strand_goal_id(assigns)
      |> assign_prevent_final_assessment_preview()
      |> stream_strand_evidences()
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_strand_goals_student_entries(%{assigns: %{initialized: false}} = socket, assigns) do
    all_strand_goals_student_entries =
      Assessments.list_strand_goals_for_student(
        assigns.student_report_card.student_id,
        assigns.strand_report.strand_id
      )

    strand_goals_ids =
      all_strand_goals_student_entries
      |> Enum.map(fn {strand_goal, _, _, _} -> "#{strand_goal.id}" end)

    strand_goals_student_entries =
      all_strand_goals_student_entries
      |> Enum.filter(fn {_, entry, moments_entries, _} ->
        not is_nil(entry) or moments_entries != []
      end)

    strand_goals_without_student_entries =
      all_strand_goals_student_entries
      |> Enum.filter(fn {_, entry, moments_entries, _} ->
        is_nil(entry) and moments_entries == []
      end)

    socket
    |> assign(:strand_goals_student_entries, strand_goals_student_entries)
    |> assign(:strand_goals_ids, strand_goals_ids)
    |> assign(:strand_goals_without_student_entries, strand_goals_without_student_entries)
    |> assign(
      :has_strand_goals_with_student_entries,
      strand_goals_student_entries != []
    )
    |> assign(
      :has_strand_goals_without_student_entries,
      strand_goals_without_student_entries != []
    )
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

  defp stream_strand_evidences(%{assigns: %{initialized: false}} = socket) do
    %{
      strand_report: %{strand_id: strand_id},
      student_report_card: %{student_id: student_id}
    } = socket.assigns

    strand_evidences = Reporting.list_student_strand_evidences(strand_id, student_id)

    socket
    |> stream(:strand_evidences, strand_evidences)
    |> assign(:has_strand_evidences, strand_evidences != [])
  end

  defp stream_strand_evidences(socket), do: socket

  defp assign_prevent_final_assessment_preview(socket) do
    profile = socket.assigns.current_profile

    prevent_final_assessment_preview =
      case {profile.type, socket.assigns.student_report_card} do
        {"teacher", _} -> false
        {"student", %{allow_student_access: true}} -> false
        {"guardian", %{allow_guardian_access: true}} -> false
        _ -> true
      end

    assign(socket, :prevent_final_assessment_preview, prevent_final_assessment_preview)
  end
end
