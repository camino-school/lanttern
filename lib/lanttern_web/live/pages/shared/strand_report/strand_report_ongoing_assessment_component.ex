defmodule LantternWeb.StrandReportLive.StrandReportOngoingAssessmentComponent do
  @moduledoc """
  Renders ongoing assessment info (moment assessments) related to a `StrandReport`.

  ### Required attrs:

  -`strand_report` - `%StrandReport{}`
  -`student_report_card` - `%StudentReportCard{}`
  -`params` - the URL params from parent view `handle_params/3`
  -`base_path` - the base URL path for overlay navigation control
  -`current_profile` - the current `%Profile{}` from `current_user`
  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.LearningContext
  alias LantternWeb.Assessments.StudentAssessmentPointDetailsOverlayComponent

  import LantternWeb.AssessmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <h2 class="font-display font-black text-2xl">{gettext("Ongoing assessment")}</h2>
        <p class="mt-4">
          {gettext("Information about ongoing assessment points, grouped by strand moments.")}
        </p>

        <section id="ongoing-assessment-points" class="mt-10">
          <div class="mt-6 space-y-10">
            <div :for={moment <- @moments} id={"moment-#{moment.id}-ap-group"}>
              <h4 class="font-display font-bold text-lg">{moment.name}</h4>
              <div
                id={"moment-#{moment.id}-sortable-aps"}
                phx-update="stream"
              >
                <.assessment_point_card
                  :for={{dom_id, ap} <- @streams["moment_#{moment.id}_assessment_points"] || []}
                  id={dom_id}
                  assessment_point={ap}
                  base_path={@base_path}
                  on_edit={JS.push("edit_assessment_point", value: %{id: ap.id}, target: @myself)}
                />
                <.empty_state_simple
                  class="p-4 mt-4 hidden only:block"
                  id={"moment-#{moment.id}-assessment-empty"}
                >
                  {gettext("No assessment points in this moment")}
                </.empty_state_simple>
              </div>
            </div>
          </div>
        </section>
      </.responsive_container>
      <.live_component
        :if={@assessment_point_id}
        module={StudentAssessmentPointDetailsOverlayComponent}
        id="assessment-point-details-component"
        assessment_point_id={@assessment_point_id}
        student_id={@student_report_card.student_id}
        on_cancel={JS.patch(@base_path)}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :assessment_point, :map, required: true
  attr :on_edit, :any, required: true
  attr :base_path, :string, required: true

  defp assessment_point_card(assigns) do
    is_diff = assigns.assessment_point.is_differentiation
    has_diff_rubric = !!assigns.assessment_point.student_entry.differentiation_rubric_id
    has_rubric = !!assigns.assessment_point.rubric_id
    has_comment = !!assigns.assessment_point.student_entry.report_note
    has_evidences = assigns.assessment_point.student_entry.has_evidences
    has_icon = is_diff || has_diff_rubric || has_rubric || has_comment || has_evidences

    assigns =
      assigns
      |> assign(:is_diff, is_diff)
      |> assign(:has_diff_rubric, has_diff_rubric)
      |> assign(:has_rubric, has_rubric)
      |> assign(:has_comment, has_comment)
      |> assign(:has_evidences, has_evidences)
      |> assign(:has_icon, has_icon)

    ~H"""
    <.link
      id={@id}
      patch={"#{@base_path}/#{@assessment_point.id}"}
      class={[
        "group/card block mt-4",
        "sm:grid sm:grid-cols-[minmax(10px,_3fr)_minmax(10px,_2fr)]"
      ]}
    >
      <.card_base class={[
        "p-4 group-hover/card:bg-ltrn-lightest",
        "sm:col-span-2 sm:grid sm:grid-cols-subgrid sm:items-center sm:gap-4"
      ]}>
        <div>
          <p class="font-bold text-ltrn-darkest">
            {@assessment_point.name}
          </p>
          <.markdown
            :if={@assessment_point.report_info}
            text={@assessment_point.report_info}
            class="mt-2 line-clamp-2"
          />
          <div :if={@has_icon} class="flex items-center gap-4 mt-4 text-ltrn-subtle">
            <p
              :if={@is_diff || @has_diff_rubric}
              class="font-sans font-bold text-sm text-ltrn-diff-dark"
            >
              {gettext("Diff")}
            </p>
            <.icon :if={@has_rubric || @has_diff_rubric} name="hero-view-columns-mini" />
            <.icon
              :if={@assessment_point.student_entry.report_note}
              name="hero-chat-bubble-oval-left-mini"
            />
            <.icon :if={@assessment_point.student_entry.has_evidences} name="hero-paper-clip-mini" />
          </div>
        </div>

        <.assessment_point_entry_display
          entry={@assessment_point.student_entry}
          show_student_assessment
          class="mt-4 sm:mt-0"
        />
      </.card_base>
    </.link>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:assessment_point_id, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_assessment_point_id()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> load_moments_and_assessment_points()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp load_moments_and_assessment_points(socket) do
    strand_id = socket.assigns.strand_report.strand_id

    moments = LearningContext.list_moments(strands_ids: [strand_id])
    moments_ids = Enum.map(moments, & &1.id)

    assessment_points =
      Assessments.list_strand_moments_assessment_points_with_student_entries(
        socket.assigns.current_scope,
        socket.assigns.student_report_card.student,
        socket.assigns.strand_report.strand_id
      )

    socket
    |> assign(:moments, moments)
    |> assign(:moments_ids, moments_ids)
    |> assign(:assessment_points_ids, Enum.map(assessment_points, &"#{&1.id}"))
    |> stream_assessment_points_by_moment(assessment_points, moments)
  end

  defp stream_assessment_points_by_moment(socket, assessment_points, moments) do
    Enum.reduce(moments, socket, fn moment, socket ->
      moment_aps =
        assessment_points
        |> Enum.filter(&(&1.moment_id == moment.id))

      stream(socket, "moment_#{moment.id}_assessment_points", moment_aps)
    end)
  end

  defp assign_assessment_point_id(
         %{assigns: %{params: %{"assessment_point_id" => assessment_point_id}}} = socket
       ) do
    # simple guard to prevent viewing details from unrelated assessment points
    assessment_point_id =
      if assessment_point_id in socket.assigns.assessment_points_ids do
        assessment_point_id
      end

    assign(socket, :assessment_point_id, assessment_point_id)
  end

  defp assign_assessment_point_id(socket), do: assign(socket, :assessment_point_id, nil)
end
