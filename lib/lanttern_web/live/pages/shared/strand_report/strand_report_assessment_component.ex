defmodule LantternWeb.StrandReportLive.StrandReportAssessmentComponent do
  @moduledoc """
  Renders assessment info related to a `StrandReport`.

  ### Required attrs:

  -`strand_report` - `%StrandReport{}`
  -`student_report_card` - `%StudentReportCard{}`
  -`params` - the URL params from parent view `handle_params/3`
  -`base_path` - the base URL path for overlay navigation control
  -`current_profile` - the current `%Profile{}` from `current_user`
  -`current_scope` - the current `%Scope{}`
  """

  use LantternWeb, :live_component

  alias Lanttern.AssessmentComposition
  alias Lanttern.Assessments
  alias Lanttern.GradesReports
  alias Lanttern.LearningContext
  alias Lanttern.Reporting
  alias LantternWeb.Assessments.StudentAssessmentPointDetailsOverlayComponent
  alias LantternWeb.Attachments.AttachmentViewComponent
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.StudentGradesReportEntryButtonComponent

  import LantternWeb.ReportingComponents, only: [strand_report_assessment_point_card: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <p>
          {gettext(
            "Here you'll find information about the strand assessments. Click the cards to view more details about it."
          )}
        </p>
        <.markdown
          :if={@strand_report.strand.assessment_info}
          text={@strand_report.strand.assessment_info}
          class="mt-10"
        />
        <section id="strand-assessment-points" class="mt-10">
          <div :for={moment <- @moments} id={"moment-#{moment.id}-ap-group"} class="mt-10">
            <h4 class="font-display font-bold text-lg">{moment.name}</h4>
            <div
              id={"moment-#{moment.id}-sortable-aps"}
              phx-update="stream"
              class="mt-4 space-y-4"
            >
              <.strand_report_assessment_point_card
                :for={{dom_id, ap} <- @streams["moment_#{moment.id}_assessment_points"] || []}
                id={dom_id}
                assessment_point={ap}
                particle_entries={@composed_particle_entries_map[ap.id] || []}
                patch={"#{@base_path}/assessment_point/#{ap.id}"}
              />
            </div>
          </div>
          <div :if={@has_strand_level_assessment_points} class="mt-10">
            <h4 class="font-display font-bold text-lg">{gettext("Strand-level assessments")}</h4>
            <div id="strand-level-assessment-points" phx-update="stream" class="mt-4 space-y-4">
              <.strand_report_assessment_point_card
                :for={{dom_id, ap} <- @streams.strand_level_assessment_points}
                id={dom_id}
                assessment_point={ap}
                particle_entries={@composed_particle_entries_map[ap.id] || []}
                patch={"#{@base_path}/assessment_point/#{ap.id}"}
              />
            </div>
          </div>
          <.empty_state :if={!@has_moment_assessment_points && !@has_strand_level_assessment_points}>
            {gettext("No assessment entries for this strand yet")}
          </.empty_state>
        </section>
        <section :if={@has_student_grades_report_entries} class="mt-10">
          <h3 class="font-display font-black text-xl">{gettext("Grading")}</h3>
          <div id="grades-report-entries" phx-update="stream">
            <.link
              :for={{dom_id, sgre} <- @streams.student_grades_report_entries}
              id={dom_id}
              patch={"#{@base_path}/student_grade_report_entry/#{sgre.id}"}
              class={[
                "group/card block mt-4",
                "sm:grid sm:grid-cols-[minmax(10px,_5fr)_minmax(10px,_2fr)]"
              ]}
            >
              <.card_base class={[
                "p-4 group-hover/card:bg-ltrn-lightest",
                "sm:col-span-2 sm:grid sm:grid-cols-subgrid sm:items-center sm:gap-4"
              ]}>
                <p class="font-bold text-ltrn-subtle">
                  {Gettext.dgettext(
                    Lanttern.Gettext,
                    "taxonomy",
                    sgre.grades_report_subject.subject.name
                  )}
                </p>
                <div class="flex items-center gap-2 mt-4 sm:mt-0">
                  <.live_component
                    module={StudentGradesReportEntryButtonComponent}
                    id={"#{dom_id}-entry-button"}
                    student_grades_report_entry={sgre}
                    class="flex-1 p-2 pointer-events-none"
                  />
                  <.icon
                    :if={sgre.comment}
                    name="hero-chat-bubble-oval-left-mini"
                    class="text-ltrn-staff-accent"
                  />
                </div>
              </.card_base>
            </.link>
          </div>
        </section>
        <div :if={@has_strand_evidences} class="mt-10">
          <div class="flex items-center gap-2">
            <.icon name="hero-paper-clip" class="w-6 h-6" />
            <h4 class="font-display font-black">
              {gettext("All strand evidences")}
            </h4>
          </div>
          <div id="strand-evidences" phx-update="stream">
            <.live_component
              :for={{dom_id, {evidence, goal_id, moment_name}} <- @streams.strand_evidences}
              module={AttachmentViewComponent}
              id={dom_id}
              class="mt-6"
              attachment={evidence}
            >
              <p class="mt-4 text-xs">
                {if moment_name do
                  "#{gettext("In the context of")} \"#{moment_name}\"."
                end}
                <.link
                  patch={"#{@base_path}/assessment_point/#{goal_id}"}
                  class="underline hover:text-ltrn-subtle"
                >
                  {gettext("View assessment details")}
                </.link>
              </p>
            </.live_component>
          </div>
        </div>
      </.responsive_container>
      <.live_component
        :if={@assessment_point_id}
        module={StudentAssessmentPointDetailsOverlayComponent}
        id="assessment-point-details-component"
        assessment_point_id={@assessment_point_id}
        student_id={@student_report_card.student_id}
        current_scope={@current_scope}
        base_path={@base_path}
        displayed_assessment_points_ids={@displayed_assessment_points_ids}
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

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:moments, [])
      |> assign(:displayed_assessment_points_ids, [])
      |> assign(:composed_particle_entries_map, %{})
      |> assign(:assessment_point_id, nil)
      |> assign(:student_grades_report_entry_id, nil)
      |> assign(:initialized, false)
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
      |> assign_assessment_point_id()
      |> assign_student_grades_report_entry_id()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> load_assessment_points()
    |> assign_prevent_final_assessment_preview()
    |> stream_strand_evidences()
    |> stream_student_grades_report_entries()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp load_assessment_points(socket) do
    %{
      current_scope: scope,
      strand_report: %{strand_id: strand_id},
      student_report_card: %{student: student}
    } = socket.assigns

    moments = LearningContext.list_moments(strands_ids: [strand_id])

    moment_assessment_points =
      Assessments.list_strand_moments_assessment_points_with_student_entries(
        scope,
        student,
        strand_id
      )

    strand_level_assessment_points =
      Assessments.list_strand_level_assessment_points_with_student_entries(
        scope,
        student,
        strand_id
      )

    all_assessment_points = moment_assessment_points ++ strand_level_assessment_points

    composed_particle_entries_map =
      build_composed_particle_entries_map(scope, student.id, all_assessment_points)

    moment_ids_with_aps =
      moment_assessment_points
      |> Enum.map(& &1.moment_id)
      |> MapSet.new()

    moments_with_aps = Enum.filter(moments, &MapSet.member?(moment_ids_with_aps, &1.id))

    displayed_ids = Enum.map(all_assessment_points, &"#{&1.id}")

    socket
    |> assign(:moments, moments_with_aps)
    |> assign(:displayed_assessment_points_ids, displayed_ids)
    |> assign(:has_moment_assessment_points, moment_assessment_points != [])
    |> assign(:has_strand_level_assessment_points, strand_level_assessment_points != [])
    |> assign(:composed_particle_entries_map, composed_particle_entries_map)
    |> stream_assessment_points_by_moment(moment_assessment_points, moments_with_aps)
    |> stream(:strand_level_assessment_points, strand_level_assessment_points)
  end

  defp build_composed_particle_entries_map(scope, student_id, assessment_points) do
    composed_ids =
      assessment_points
      |> Enum.filter(& &1.uses_composition)
      |> Enum.map(& &1.id)

    AssessmentComposition.list_component_entries_by_parent(scope, composed_ids, student_id)
  end

  defp stream_assessment_points_by_moment(socket, assessment_points, moments) do
    Enum.reduce(moments, socket, fn moment, socket ->
      moment_aps =
        assessment_points
        |> Enum.filter(&(&1.moment_id == moment.id))

      stream(socket, "moment_#{moment.id}_assessment_points", moment_aps)
    end)
  end

  defp assign_prevent_final_assessment_preview(socket) do
    profile = socket.assigns.current_profile

    prevent_final_assessment_preview =
      case {profile.type, socket.assigns.student_report_card} do
        {"staff", _} -> false
        {"student", %{allow_access: true}} -> false
        {"guardian", %{allow_access: true}} -> false
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

    socket
    |> stream(:strand_evidences, strand_evidences)
    |> assign(:has_strand_evidences, strand_evidences != [])
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

  defp assign_student_grades_report_entry_id(
         %{assigns: %{params: %{"student_grade_report_entry_id" => sgre_id}}} = socket
       ) do
    # simple guard to prevent viewing details from unrelated entries
    student_grades_report_entry_id =
      if sgre_id in socket.assigns.student_grades_report_entries_ids do
        sgre_id
      end

    assign(socket, :student_grades_report_entry_id, student_grades_report_entry_id)
  end

  defp assign_student_grades_report_entry_id(socket),
    do: assign(socket, :student_grades_report_entry_id, nil)

  defp assign_assessment_point_id(
         %{assigns: %{params: %{"assessment_point_id" => assessment_point_id}}} = socket
       ) do
    # simple guard to prevent viewing details from unrelated assessment points
    assessment_point_id =
      if assessment_point_id in socket.assigns.displayed_assessment_points_ids do
        assessment_point_id
      end

    assign(socket, :assessment_point_id, assessment_point_id)
  end

  defp assign_assessment_point_id(socket), do: assign(socket, :assessment_point_id, nil)
end
