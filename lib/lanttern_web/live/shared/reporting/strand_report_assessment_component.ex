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
  alias Lanttern.GradesReports
  alias Lanttern.Reporting

  # page components
  alias LantternWeb.Assessments.StrandGoalDetailsOverlayComponent

  # shared components
  alias LantternWeb.Assessments.EntryParticleComponent
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.StudentGradesReportEntryButtonComponent
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
        <div id="strand-goals-student-entries" phx-update="stream">
          <.goal_card
            :for={
              {dom_id, {goal, entry, moment_entries}} <-
                @streams.strand_goals_student_entries
            }
            id={dom_id}
            patch={"#{@base_path}&strand_goal_id=#{goal.id}"}
            goal={goal}
            entry={entry}
            moment_entries={moment_entries}
            has_evidence={@goal_has_evidences_map[goal.id]}
            prevent_preview={@prevent_final_assessment_preview}
          />
        </div>
        <.empty_state :if={!@has_strand_goals_with_student_entries}>
          <%= gettext("No assessment entries for this strand yet") %>
        </.empty_state>
        <div :if={@has_strand_evidences} class="mt-10">
          <div class="flex items-center gap-2">
            <.icon name="hero-paper-clip" class="w-6 h-6" />
            <h4 class="font-display font-black">
              <%= gettext("All strand evidences") %>
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
                  "#{gettext("In the context of")} \"#{moment_name}\"."
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
        <div :if={@has_student_grades_report_entries} class="mt-10">
          <h3 class="font-display font-black text-xl"><%= gettext("Grading") %></h3>
          <div id="grades-report-entries" phx-update="stream">
            <.card_base
              :for={{dom_id, sgre} <- @streams.student_grades_report_entries}
              id={dom_id}
              class={[
                "p-4 mt-4",
                "sm:grid sm:grid-cols-[minmax(10px,_5fr)_minmax(10px,_2fr)] sm:items-center sm:gap-4"
              ]}
            >
              <p class="font-bold text-ltrn-subtle">
                <%= Gettext.dgettext(
                  Lanttern.Gettext,
                  "taxonomy",
                  sgre.grades_report_subject.subject.name
                ) %>
              </p>
              <div class="flex items-center gap-2 mt-4 sm:mt-0">
                <.live_component
                  module={StudentGradesReportEntryButtonComponent}
                  id={"#{dom_id}-entry-button"}
                  student_grades_report_entry={sgre}
                  on_click={JS.patch("#{@base_path}&sgre=#{sgre.id}")}
                  class="flex-1 p-2"
                />
                <.icon
                  :if={sgre.comment}
                  name="hero-chat-bubble-oval-left-mini"
                  class="text-ltrn-staff-accent"
                />
              </div>
            </.card_base>
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
          <div id="strand-goals-without-student-entries" phx-update="stream" class="hidden">
            <.goal_card
              :for={
                {dom_id, {goal, entry, moment_entries}} <-
                  @streams.strand_goals_without_student_entries
              }
              id={dom_id}
              patch={"#{@base_path}&strand_goal_id=#{goal.id}"}
              goal={goal}
              entry={entry}
              moment_entries={moment_entries}
              has_evidence={@goal_has_evidences_map[goal.id]}
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
      <.live_component
        :if={@student_grades_report_entry_id}
        module={GradeDetailsOverlayComponent}
        id="grade-details-overlay-component-overlay"
        student_grades_report_entry_id={@student_grades_report_entry_id}
        on_cancel={JS.patch(@base_path)}
      />
    </div>
    """
  end

  attr :goal, AssessmentPoint, required: true
  attr :id, :string, required: true
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
      id={@id}
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
      {gettext("Teacher comment"), "hero-chat-bubble-oval-left-mini", "bg-ltrn-staff-lighter",
       "text-ltrn-staff-accent"}

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
      |> assign(:student_grades_report_entry_id, nil)
      |> assign(:initialized, false)
      |> stream_configure(
        :strand_goals_student_entries,
        dom_id: fn {goal, _, _} -> "goal-#{goal.id}" end
      )
      |> stream_configure(
        :strand_goals_without_student_entries,
        dom_id: fn {goal, _, _} -> "goal-#{goal.id}" end
      )
      |> stream_configure(
        :strand_evidences,
        dom_id: fn {attachment, _, _} -> "attachment-#{attachment.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_strand_goal_id()
      |> assign_student_grades_report_entry_id()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_strand_goals_student_entries()
    |> assign_prevent_final_assessment_preview()
    |> stream_strand_evidences()
    |> stream_student_grades_report_entries()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_strand_goals_student_entries(socket) do
    all_strand_goals_student_entries =
      Assessments.list_strand_goals_for_student(
        socket.assigns.student_report_card.student_id,
        socket.assigns.strand_report.strand_id
      )

    strand_goals_ids =
      all_strand_goals_student_entries
      |> Enum.map(fn {strand_goal, _, _} -> "#{strand_goal.id}" end)

    strand_goals_student_entries =
      all_strand_goals_student_entries
      |> Enum.filter(fn {_, entry, moments_entries} ->
        not is_nil(entry) or moments_entries != []
      end)

    strand_goals_without_student_entries =
      all_strand_goals_student_entries
      |> Enum.filter(fn {_, entry, moments_entries} ->
        is_nil(entry) and moments_entries == []
      end)

    socket
    |> stream(:strand_goals_student_entries, strand_goals_student_entries)
    |> assign(:strand_goals_ids, strand_goals_ids)
    |> stream(:strand_goals_without_student_entries, strand_goals_without_student_entries)
    |> assign(
      :has_strand_goals_with_student_entries,
      strand_goals_student_entries != []
    )
    |> assign(
      :has_strand_goals_without_student_entries,
      strand_goals_without_student_entries != []
    )
  end

  defp assign_prevent_final_assessment_preview(socket) do
    profile = socket.assigns.current_profile

    prevent_final_assessment_preview =
      case {profile.type, socket.assigns.student_report_card} do
        {"staff", _} -> false
        {"student", %{allow_student_access: true}} -> false
        {"guardian", %{allow_guardian_access: true}} -> false
        _ -> true
      end

    assign(socket, :prevent_final_assessment_preview, prevent_final_assessment_preview)
  end

  defp stream_strand_evidences(socket) do
    %{
      strand_report: %{strand_id: strand_id},
      student_report_card: %{student_id: student_id}
    } = socket.assigns

    strand_evidences = Reporting.list_student_strand_evidences(strand_id, student_id)

    goal_has_evidences_map =
      strand_evidences
      |> Enum.group_by(
        fn {_, goal_id, _} -> goal_id end,
        fn _ -> true end
      )
      |> Enum.map(fn {goal_id, _} -> {goal_id, true} end)
      |> Enum.into(%{})

    socket
    |> stream(:strand_evidences, strand_evidences)
    |> assign(:has_strand_evidences, strand_evidences != [])
    |> assign(:goal_has_evidences_map, goal_has_evidences_map)
  end

  defp stream_student_grades_report_entries(
         %{assigns: %{prevent_final_assessment_preview: false}} = socket
       ) do
    grades_report_id = socket.assigns.student_report_card.report_card.grades_report_id

    student_grades_report_entries =
      if grades_report_id do
        GradesReports.list_student_grades_report_entries_for_strand(
          socket.assigns.student_report_card.student_id,
          socket.assigns.strand_report.strand_id,
          socket.assigns.student_report_card.report_card.school_cycle_id,
          grades_report_id,
          only_visible: true
        )
      else
        []
      end

    socket
    |> stream(:student_grades_report_entries, student_grades_report_entries)
    |> assign(:has_student_grades_report_entries, student_grades_report_entries != [])
    |> assign(
      :student_grades_report_entries_ids,
      Enum.map(student_grades_report_entries, &"#{&1.id}")
    )
  end

  defp stream_student_grades_report_entries(socket) do
    socket
    |> stream(:student_grades_report_entries, [])
    |> assign(:has_student_grades_report_entries, false)
    |> assign(:student_grades_report_entries_ids, [])
  end

  defp assign_strand_goal_id(
         %{assigns: %{params: %{"strand_goal_id" => strand_goal_id}}} = socket
       ) do
    # simple guard to prevent viewing details from unrelated assessment points
    strand_goal_id =
      if strand_goal_id in socket.assigns.strand_goals_ids do
        strand_goal_id
      end

    assign(socket, :strand_goal_id, strand_goal_id)
  end

  defp assign_strand_goal_id(socket), do: assign(socket, :strand_goal_id, nil)

  defp assign_student_grades_report_entry_id(%{assigns: %{params: %{"sgre" => sgre_id}}} = socket) do
    # simple guard to prevent viewing details from unrelated entries
    student_grades_report_entry_id =
      if sgre_id in socket.assigns.student_grades_report_entries_ids do
        sgre_id
      end

    assign(socket, :student_grades_report_entry_id, student_grades_report_entry_id)
  end

  defp assign_student_grades_report_entry_id(socket),
    do: assign(socket, :student_grades_report_entry_id, nil)
end
