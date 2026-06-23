defmodule LantternWeb.Assessments.AssessmentsGridComponent do
  @moduledoc """
  This component handles the loading and rendering of the assessment
  points and its entries in the context of a strand or a moment.

  The component also handles the entries update process, including
  the entry details view (with comments and evidences).

  #### Expected external assigns

      attr :current_user, User
      attr :current_scope, Scope
      attr :current_assessment_view, :string
      attr :classes_ids, :list, doc: "list of classes_ids to filter results"
      attr :strand_id, :integer, doc: "defines a strand grid view"
      attr :strand, Strand, doc: "strand struct (with :subjects preloaded) enabling the grades report column group"
      attr :strand_grades_report_cards, :list, default: [], doc: "linked grade report cards (from `Reporting.list_strand_grades_report_cards/2`), fetched once by the parent and narrowed to the active filter here"
      attr :class, :any
      attr :navigate, :string, doc: "defines push_navigate target"
      attr :url_params, :map, doc: "URL-based filter params to preserve in navigation", default: %{}
      attr :filter_assessment_points_ids, :list, default: nil, doc: "when set, restricts displayed assessment points to these IDs"
      attr :filter_grades_report_cycle_id, :integer, default: nil, doc: "when set with the subject id, keeps only the matching grades report column (grade report filter active)"
      attr :filter_grades_report_subject_id, :integer, default: nil, doc: "see filter_grades_report_cycle_id"

  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.GradesReports
  alias Lanttern.Identity.Scope
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Student

  import LantternWeb.GradingComponents
  import LantternWeb.GradesReportsHelpers, only: [build_calculation_results_message: 1]

  # shared components
  alias LantternWeb.AssessmentComposition.AssessmentPointCompositionOverlayComponent
  alias LantternWeb.Assessments.AssessmentPointCommandPaletteComponent
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Assessments.EntryCellComponent
  alias LantternWeb.Assessments.EntryDetailsOverlayComponent
  alias LantternWeb.GradesReports.StudentGradesReportEntryButtonComponent
  alias LantternWeb.GradesReports.StudentGradesReportEntryOverlayComponent
  alias LantternWeb.Grading.StrandGradeCompositionOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <%!-- if no class filter is selected, ask user to select one --%>
        <div :if={@classes_ids == []} class="p-10 rounded-sm shadow-xl bg-white">
          <p class="flex items-center gap-2">
            <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
            {gettext("Assign at least one class to the strand to view the assessment grid")}
          </p>
          {render_slot(@no_class_action)}
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div
          :if={@classes_ids != [] && !@has_assessment_points}
          class="p-10 mt-4 rounded-sm shadow-xl bg-white"
        >
          <.empty_state>{gettext("No assessment points for this strand yet")}</.empty_state>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div :if={@classes_ids != [] && @has_assessment_points}>
        <div class={[
          "relative w-full max-h-screen border rounded-sm shadow-xl #{@view_bg} overflow-x-auto",
          if(@current_assessment_view == "student",
            do: "border-ltrn-student-accent",
            else: "border-transparent"
          )
        ]}>
          <div
            class={["relative grid", if(@entries_changes_map != %{}, do: "pb-20", else: "pb-4")]}
            style={"grid-template-columns: 15rem #{@assessment_points_columns_grid} #{@grades_report_columns_grid}"}
          >
            <div
              class={"sticky top-0 z-20 grid grid-cols-subgrid pt-4 #{@view_bg}"}
              style={"grid-column: span #{@assessment_points_count + @grades_report_columns_count + 1} / span #{@assessment_points_count + @grades_report_columns_count + 1}"}
            >
              <div class={["sticky left-0 z-20 #{@view_bg}", "row-span-2"]}></div>
              <div
                id="grid-assessment-point-headers"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point_header
                  :for={{dom_id, ap_header} <- @streams.assessment_point_headers}
                  id={dom_id}
                  ap_header={ap_header}
                  assessment_view={@current_assessment_view}
                />
              </div>
              <div
                :if={@grades_report_columns_count > 0}
                class="group pt-2 px-2"
                style={"grid-column: span #{@grades_report_columns_count} / span #{@grades_report_columns_count}"}
              >
                <div class="h-full pb-2 border-b border-ltrn-light">
                  <span class="flex items-center w-full text-sm font-display font-bold truncate">
                    {gettext("Grade report")}
                  </span>
                </div>
              </div>
              <div
                id="grid-assessment-points"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point
                  :for={{dom_id, assessment_point} <- @streams.assessment_points}
                  id={dom_id}
                  assessment_point={assessment_point}
                  assessment_view={@current_assessment_view}
                  url_params={@url_params}
                  myself={@myself}
                />
              </div>
              <div
                :if={@grades_report_columns_count > 0}
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@grades_report_columns_count} / span #{@grades_report_columns_count}"}
              >
                <.grade_column_header
                  :for={column <- @grades_report_columns}
                  column={column}
                  myself={@myself}
                />
              </div>
            </div>
            <div
              id="grid-student-entries"
              phx-update="stream"
              class="grid grid-cols-subgrid"
              style={"grid-column: span #{@assessment_points_count + @grades_report_columns_count + 1} / span #{@assessment_points_count + @grades_report_columns_count + 1}"}
            >
              <.student_entries
                :for={{dom_id, {student, entries, grade_cells}} <- @streams.students_entries}
                id={dom_id}
                current_scope={@current_scope}
                student={student}
                entries={entries}
                grades_report_columns={@grades_report_columns}
                student_grade_cells={grade_cells}
                myself={@myself}
                current_assessment_view={@current_assessment_view}
                view_bg={@view_bg}
                current_user={@current_user}
                composed_assessment_point_ids={@composed_assessment_point_ids}
              />
            </div>
          </div>
        </div>
      </div>
      <.fixed_bar :if={@entries_changes_map != %{}} class="flex items-center gap-6">
        <div class="flex-1 flex items-center gap-4">
          <p class="text-white text-nowrap">
            {ngettext("1 change", "%{count} changes", map_size(@entries_changes_map))}
          </p>
          <p
            :if={MapSet.size(@invalid_changes_set) > 0}
            class="flex items-center gap-2 font-sans text-sm text-ltrn-alert-lighter"
          >
            <.icon name="hero-exclamation-circle-mini" />
            {gettext("Some values are out of range")}
          </p>
          <p
            :if={@current_assessment_view == "student" && MapSet.size(@invalid_changes_set) == 0}
            class="flex items-center gap-2 font-sans text-sm text-ltrn-student-accent"
          >
            <.icon name="hero-information-circle-mini" />
            {gettext("You are registering students self-assessments")}
          </p>
        </div>
        <.button
          phx-click={JS.navigate(@navigate)}
          theme="white_outline"
          data-confirm={gettext("Are you sure?")}
        >
          {gettext("Discard")}
        </.button>
        <.button
          type="button"
          phx-click="save_changes"
          phx-target={@myself}
          theme={if @current_assessment_view == "student", do: "student", else: "white"}
          disabled={MapSet.size(@invalid_changes_set) > 0}
          class="disabled:opacity-40"
        >
          {if @current_assessment_view == "student",
            do: gettext("Save self-assessments"),
            else: gettext("Save")}
        </.button>
      </.fixed_bar>
      <.live_component
        :if={@assessment_point_entry}
        module={EntryDetailsOverlayComponent}
        id={"#{@id}-entry-details-overlay"}
        entry={@assessment_point_entry}
        current_user={@current_user}
        on_cancel={JS.push("close_entry_details_overlay", target: @myself)}
        notify_component={@myself}
      />
      <.live_component
        :if={@command_palette_ap}
        module={AssessmentPointCommandPaletteComponent}
        id={"#{@id}-ap-command-palette"}
        ap={@command_palette_ap}
        current_scope={@current_scope}
        notify_component={@myself}
        on_cancel={JS.push("close_command_palette", target: @myself)}
      />
      <.live_component
        :if={@assessment_point_overlay}
        module={AssessmentPointFormOverlayComponent}
        id={"#{@id}-assessment-point-form-overlay"}
        current_scope={@current_scope}
        assessment_point={@assessment_point_overlay}
        notify_component={@myself}
        title={gettext("Edit assessment point")}
        on_cancel={JS.push("close_assessment_point_form", target: @myself)}
        initial_curriculum_results={[]}
      />
      <.live_component
        :if={@composition_overlay_ap}
        module={AssessmentPointCompositionOverlayComponent}
        id={"#{@id}-ap-composition-overlay"}
        current_scope={@current_scope}
        ap={@composition_overlay_ap}
        strand_id={@strand_id}
        notify_component={@myself}
        initial_view={@composition_overlay_initial_view}
        on_cancel={JS.push("close_composition_overlay", target: @myself)}
      />
      <.live_component
        :if={@grades_composition_overlay_column}
        module={StrandGradeCompositionOverlayComponent}
        id={"#{@id}-grades-report-composition-overlay"}
        current_scope={@current_scope}
        strand_id={@strand_id}
        grades_report_id={@grades_composition_overlay_column.grades_report.id}
        grades_report_cycle_id={@grades_composition_overlay_column.grades_report_cycle.id}
        grades_report_subject_id={@grades_composition_overlay_column.grades_report_subject.id}
        cycle_name={@grades_composition_overlay_column.school_cycle.name}
        subject_name={@grades_composition_overlay_column.grades_report_subject.subject.name}
        on_cancel={JS.push("close_grades_composition_overlay", target: @myself)}
      />
      <.live_component
        :if={@student_grades_report_entry}
        module={StudentGradesReportEntryOverlayComponent}
        id={"#{@id}-student-grade-entry-overlay"}
        student_grades_report_entry={@student_grades_report_entry}
        scale_id={@grades_report_entry_scale_id}
        tz={@current_user.tz}
        navigate={@navigate}
        on_cancel={JS.push("close_grade_entry_overlay", target: @myself)}
      />
    </div>
    """
  end

  # function components

  attr :id, :string, required: true
  attr :ap_header, :any, required: true
  attr :assessment_view, :string, required: true

  def assessment_point_header(assigns) do
    {header_struct, assessment_points_count} = assigns.ap_header

    grid_column_span_style =
      "grid-column: span #{assessment_points_count} / span #{assessment_points_count}"

    assigns =
      assigns
      |> assign(:header_struct, header_struct)
      |> assign(:grid_column_span_style, grid_column_span_style)

    ~H"""
    <div id={@id} class="group pt-2 px-2" style={@grid_column_span_style}>
      <div class="h-full pb-2 border-b border-ltrn-light" style={@grid_column_span_style}>
        <span class="flex items-center w-full text-sm font-display font-bold truncate">
          <%= if match?(%Moment{}, @header_struct) do %>
            {@header_struct.name}
          <% else %>
            {gettext("Goals assessment")}
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true
  attr :assessment_view, :string, required: true
  attr :url_params, :map, required: true
  attr :id, :string, required: true
  attr :myself, :any, required: true

  def assessment_point(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col p-1">
      <div class="flex flex-1 gap-1">
        <button
          type="button"
          phx-click="open_command_palette"
          phx-value-id={@assessment_point.id}
          phx-target={@myself}
          class="flex flex-1 gap-2 p-1 rounded-sm text-left hover:bg-ltrn-lightest"
        >
          <div class="flex flex-col flex-1">
            <div class={if(@assessment_point.is_hidden, do: "opacity-50")}>
              <div class="flex items-center gap-2 mb-1">
                <%= if @assessment_point.scale.type == "numeric" do %>
                  <.badge>{@assessment_point.scale.max_score}</.badge>
                <% else %>
                  <.ordinal_scale_range scale={@assessment_point.scale} />
                <% end %>
              </div>
              <p class="flex-1 font-sans text-sm line-clamp-2">
                {@assessment_point.name}
              </p>
            </div>
          </div>
          <div class="shrink-0 flex flex-col gap-1 text-ltrn-light">
            <.icon
              name="hero-view-columns-micro"
              class={["size-3", if(@assessment_point.rubric_id, do: "text-ltrn-primary")]}
            />
            <.icon
              name="hero-light-bulb-micro"
              class={["size-3", if(@assessment_point.is_differentiation, do: "text-ltrn-diff-accent")]}
            />
            <.icon
              name="hero-calculator-micro"
              class={["size-3", if(@assessment_point.uses_composition, do: "text-ltrn-primary")]}
            />
          </div>
        </button>
        <.tooltip id={"assessment-point-#{@assessment_point.id}-tooltip"}>
          <p>{@assessment_point.name}</p>
          <p class="mt-2">
            <%= if @assessment_point.scale.type == "numeric" do %>
              {gettext("Max score: %{max}", max: @assessment_point.scale.max_score)}
            <% else %>
              {@assessment_point.scale.name}
            <% end %>
          </p>
          <p :if={@assessment_point.rubric_id} class="mt-2">{gettext("Uses rubric")}</p>
          <p :if={@assessment_point.is_differentiation} class="mt-2">
            {gettext("Differentiation assessment")}
          </p>
          <p
            :if={@assessment_point.uses_composition and @assessment_point.scale.type == "numeric"}
            class="mt-2"
          >
            {gettext("Sum-based grade composition")}
          </p>
          <p
            :if={@assessment_point.uses_composition and @assessment_point.scale.type == "ordinal"}
            class="mt-2"
          >
            {gettext("Average-based grade composition")}
          </p>
          <.markdown
            :if={@assessment_point.report_info}
            text={@assessment_point.report_info}
            invert
            strip_tags
            size="sm"
            class="mt-2"
          />
        </.tooltip>
      </div>
      <.badge
        :if={@assessment_point.is_hidden}
        icon_name="hero-eye-slash-micro"
        class="w-full mt-2"
      >
        {gettext("Hidden")}
      </.badge>
      <.compare_header :if={@assessment_view == "compare"} />
    </div>
    """
  end

  def compare_header(assigns) do
    ~H"""
    <div class="flex gap-1 w-full mt-2 font-sans text-xs">
      <div class="flex-1 pb-1 border-b-2 border-ltrn-staff-accent text-center text-ltrn-staff-dark">
        {gettext("Teacher")}
      </div>
      <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-center text-ltrn-student-dark">
        {gettext("Student")}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :current_scope, Scope, required: true
  attr :student, Student, required: true
  attr :entries, :list, required: true
  attr :grades_report_columns, :list, required: true
  attr :student_grade_cells, :list, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :current_assessment_view, :string, required: true
  attr :view_bg, :string, required: true
  attr :current_user, User, required: true
  attr :composed_assessment_point_ids, :any, required: true

  def student_entries(assigns) do
    ~H"""
    <div
      id={@id}
      data-grid-row
      class="grid grid-cols-subgrid"
      style={"grid-column: span #{length(@entries) + length(@grades_report_columns) + 1} / span #{length(@entries) + length(@grades_report_columns) + 1}"}
    >
      <div class={"sticky left-0 z-10 pl-6 py-2 pr-2 #{@view_bg}"}>
        <.profile_picture_with_name
          profile_name={@student.name}
          picture_url={@student.profile_picture_url}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
          navigate={~p"/school/students/#{@student}"}
        />
      </div>
      <div :for={entry <- @entries} data-grid-cell class="p-2">
        <.live_component
          module={EntryCellComponent}
          current_scope={@current_scope}
          id={"student-#{@student.id}-entry-for-#{entry.assessment_point_id}"}
          class="w-full h-full"
          entry={entry}
          view={@current_assessment_view}
          allow_edit={true}
          is_composed={
            entry.assessment_point_id in @composed_assessment_point_ids and
              not entry.use_manual_input
          }
          notify_component={@myself}
        />
      </div>
      <div
        :for={{column, cell} <- Enum.zip(@grades_report_columns, @student_grade_cells)}
        data-grid-cell
        class="p-2"
      >
        <.grade_cell student={@student} column={column} cell={cell} myself={@myself} />
      </div>
    </div>
    """
  end

  attr :column, :map, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def grade_column_header(assigns) do
    subject_name =
      Gettext.dgettext(
        Lanttern.Gettext,
        "taxonomy",
        assigns.column.grades_report_subject.subject.name
      )

    year_name =
      Gettext.dgettext(
        Lanttern.Gettext,
        "taxonomy",
        assigns.column.grades_report.year.name
      )

    dom_id =
      "grades-report-col-#{assigns.column.grades_report.id}-#{assigns.column.grades_report_cycle && assigns.column.grades_report_cycle.id}-#{assigns.column.grades_report_subject.id}"

    assigns =
      assigns
      |> assign(:subject_name, subject_name)
      |> assign(:year_name, year_name)
      |> assign(:has_cycle, not is_nil(assigns.column.grades_report_cycle))
      |> assign(:dom_id, dom_id)

    ~H"""
    <div class="flex flex-col py-1 px-2">
      <div class="flex items-center gap-1">
        <%= if @has_cycle do %>
          <div class="relative flex-1 min-w-0">
            <button
              type="button"
              id={"#{@dom_id}-button"}
              class="max-w-full font-display font-bold text-sm text-left truncate hover:text-ltrn-subtle"
            >
              {@subject_name}
            </button>
            <.dropdown_menu id={"#{@dom_id}-menu"} button_id={"#{@dom_id}-button"} z_index="30">
              <:item
                text={gettext("Manage grade composition")}
                on_click={
                  JS.push("manage_grades_composition",
                    value: %{
                      grades_report_cycle_id: @column.grades_report_cycle.id,
                      grades_report_subject_id: @column.grades_report_subject.id
                    },
                    target: @myself
                  )
                }
              />
            </.dropdown_menu>
          </div>
        <% else %>
          <p class="flex-1 min-w-0 font-display font-bold text-sm truncate">{@subject_name}</p>
        <% end %>
        <.icon_button
          name="hero-arrow-path-mini"
          theme="white"
          rounded
          size="sm"
          sr_text={gettext("Calculate subject grades")}
          disabled={not @has_cycle}
          phx-click="calculate_subject"
          phx-value-grades_report_id={@column.grades_report.id}
          phx-value-grades_report_cycle_id={
            @column.grades_report_cycle && @column.grades_report_cycle.id
          }
          phx-value-grades_report_subject_id={@column.grades_report_subject.id}
          phx-target={@myself}
          data-confirm={gettext("Are you sure? Existing grades will be recalculated.")}
        />
      </div>
      <p class="mt-0.5 font-sans text-xs text-ltrn-subtle truncate" title={@year_name}>
        {@year_name}
      </p>
      <div class="relative mt-2">
        <.badge
          icon_name={if @column.is_hidden, do: "hero-eye-slash-micro", else: "hero-eye-micro"}
          class="w-full"
        >
          {if @column.is_hidden, do: gettext("Hidden"), else: gettext("Visible")}
        </.badge>
        <.tooltip id={"#{@dom_id}-visibility-tooltip"}>
          {if @column.is_hidden,
            do:
              gettext(
                "This grade report is hidden from students and guardians. Visibility is managed by the school admin."
              ),
            else:
              gettext(
                "This grade report is visible to students and guardians. Visibility is managed by the school admin."
              )}
        </.tooltip>
      </div>
    </div>
    """
  end

  attr :student, Student, required: true
  attr :column, :map, required: true
  attr :cell, :map, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def grade_cell(assigns) do
    entry = assigns.cell.entry

    has_retake_history =
      entry && (entry.pre_retake_ordinal_value_id != nil || entry.pre_retake_score != nil)

    has_manual_grade =
      case entry do
        %{ordinal_value_id: ov_id, composition_ordinal_value_id: comp_ov_id}
        when ov_id != comp_ov_id ->
          true

        %{score: score, composition_score: comp_score}
        when score != comp_score ->
          true

        _ ->
          false
      end

    has_comment = entry && is_binary(entry.comment) && entry.comment != ""

    base_id =
      "student-#{assigns.student.id}-grade-for-#{assigns.cell.grades_report_id}-#{assigns.cell.grades_report_cycle_id}-#{assigns.cell.grades_report_subject_id}"

    view_grade_entry_js =
      entry &&
        JS.push("view_grade_entry",
          value: %{id: entry.id, scale_id: assigns.cell.scale_id},
          target: assigns.myself
        )

    assigns =
      assigns
      |> assign(:has_retake_history, has_retake_history)
      |> assign(:has_manual_grade, has_manual_grade)
      |> assign(:has_comment, has_comment)
      |> assign(:base_id, base_id)
      |> assign(:view_grade_entry_js, view_grade_entry_js)

    ~H"""
    <div class="flex items-center justify-center gap-1 w-full h-full">
      <.live_component
        :if={@has_retake_history}
        module={StudentGradesReportEntryButtonComponent}
        id={"#{@base_id}-pre-retake"}
        is_pre_retake
        student_grades_report_entry={@cell.entry}
        use_short_name
        class="flex-1 self-stretch my-2 text-xs opacity-70"
        on_click={@view_grade_entry_js}
      />
      <.live_component
        module={StudentGradesReportEntryButtonComponent}
        id={@base_id}
        student_grades_report_entry={@cell.entry}
        use_short_name
        class="flex-2 self-stretch"
        on_click={@view_grade_entry_js}
      />
      <button
        :if={@cell.entry}
        type="button"
        tabindex="-1"
        class="flex flex-col shrink-0 rounded-full text-ltrn-light hover:opacity-60"
        phx-click={@view_grade_entry_js}
      >
        <.icon
          name="hero-chat-bubble-oval-left-micro"
          class={["size-3", @has_comment && "text-ltrn-staff-accent"]}
        />
        <.icon
          name="hero-pencil-square-micro"
          class={["size-3", @has_manual_grade && "text-ltrn-primary"]}
        />
        <.tooltip :if={@has_comment || @has_manual_grade} id={"#{@base_id}-indicators-tooltip"}>
          <div class="space-y-2">
            <p :if={@has_comment}>{gettext("Has comment")}</p>
            <p :if={@has_manual_grade}>
              {gettext("Manual grade adjustment (differs from the calculated composition value)")}
            </p>
          </div>
        </.tooltip>
      </button>
      <.icon_button
        name="hero-arrow-path-mini"
        theme="white"
        rounded
        size="sm"
        sr_text={gettext("Calculate grade")}
        disabled={is_nil(@cell.grades_report_cycle_id)}
        phx-click="calculate_cell"
        phx-value-student_id={@student.id}
        phx-value-grades_report_id={@cell.grades_report_id}
        phx-value-grades_report_cycle_id={@cell.grades_report_cycle_id}
        phx-value-grades_report_subject_id={@cell.grades_report_subject_id}
        phx-target={@myself}
        data-confirm={
          if @has_manual_grade,
            do:
              gettext(
                "There is a manual grade change that will be overwritten by this operation. Are you sure you want to proceed?"
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
      |> assign(:class, nil)
      |> assign(:classes_ids, [])
      |> assign(:strand, nil)
      |> assign(:strand_id, nil)
      |> assign(:entries_changes_map, %{})
      |> assign(:invalid_changes_set, MapSet.new())
      |> assign(:assessment_point_entry, nil)
      |> assign(:command_palette_ap, nil)
      |> assign(:assessment_point_overlay, nil)
      |> assign(:composition_overlay_ap, nil)
      |> assign(:composition_overlay_initial_view, :overview)
      |> assign(:has_entry_details_change, false)
      |> assign(:has_assessment_points, false)
      |> assign(:assessment_points_count, 0)
      |> assign(:assessment_points_columns_grid, "")
      |> assign(:composed_assessment_point_ids, MapSet.new())
      |> assign(:url_params, %{})
      |> assign(:filter_assessment_points_ids, nil)
      |> assign(:filter_grades_report_cycle_id, nil)
      |> assign(:filter_grades_report_subject_id, nil)
      |> assign(:strand_grades_report_cards, [])
      |> assign(:grades_report_columns, [])
      |> assign(:grades_report_columns_count, 0)
      |> assign(:grades_report_columns_grid, "")
      |> assign(:students_ids, [])
      |> assign(:grades_composition_overlay_column, nil)
      |> assign(:student_grades_report_entry, nil)
      |> assign(:grades_report_entry_scale_id, nil)
      |> stream_configure(
        :assessment_point_headers,
        dom_id: fn
          {%Moment{} = moment, _count} -> "ap-group-moment-#{moment.id}"
          {%Strand{} = strand, _count} -> "ap-group-strand-#{strand.id}"
        end
      )
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries, _grade_cells} -> "student-#{student.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {EntryCellComponent, {:change, :cancel, composite_id, _, _}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, &Map.drop(&1, [composite_id]))
      |> update(:invalid_changes_set, &MapSet.delete(&1, composite_id))

    {:ok, socket}
  end

  def update(
        %{action: {EntryCellComponent, {:change, change_type, composite_id, _entry_id, params}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, &Map.put(&1, composite_id, params))
      |> update(:invalid_changes_set, fn set ->
        if change_type == :invalid,
          do: MapSet.put(set, composite_id),
          else: MapSet.delete(set, composite_id)
      end)

    {:ok, socket}
  end

  def update(
        %{action: {EntryCellComponent, {:view_details, entry}}},
        socket
      ) do
    socket =
      socket
      |> assign(:assessment_point_entry, entry)

    {:ok, socket}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, {msg_type, _}}},
        socket
      )
      when msg_type in [:created_entry, :change, :created_attachment, :deleted_attachment] do
    {:ok, assign(socket, :has_entry_details_change, true)}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, {:delete, _entry}}},
        socket
      ) do
    socket =
      socket
      |> assign(:assessment_point_entry, nil)
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:has_entry_details_change, false)

    {:ok, socket}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, _}},
        socket
      ),
      do: {:ok, socket}

  def update(%{action: {AssessmentPointCommandPaletteComponent, {:edit}}}, socket) do
    ap = socket.assigns.command_palette_ap

    socket =
      socket
      |> assign(:command_palette_ap, nil)
      |> assign(:assessment_point_overlay, ap)

    {:ok, socket}
  end

  def update(
        %{action: {AssessmentPointCommandPaletteComponent, {:add_composition}}},
        socket
      ) do
    ap = socket.assigns.command_palette_ap

    {:ok, updated_ap} =
      Assessments.update_assessment_point(socket.assigns.current_scope, ap, %{
        uses_composition: true
      })

    ap =
      Assessments.get_assessment_point!(updated_ap.id,
        preloads: [curriculum_item: :curriculum_component, scale: :ordinal_values]
      )

    socket =
      socket
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:command_palette_ap, nil)
      |> assign(:composition_overlay_ap, ap)
      |> assign(:composition_overlay_initial_view, :setup)

    {:ok, socket}
  end

  def update(%{action: {AssessmentPointCommandPaletteComponent, {:manage_composition}}}, socket) do
    ap = socket.assigns.command_palette_ap

    socket =
      socket
      |> assign(:command_palette_ap, nil)
      |> assign(:composition_overlay_ap, ap)
      |> assign(:composition_overlay_initial_view, :overview)

    {:ok, socket}
  end

  def update(%{action: {AssessmentPointCommandPaletteComponent, {:toggle_hidden}}}, socket) do
    ap = socket.assigns.command_palette_ap

    {:ok, _} =
      Assessments.update_assessment_point(socket.assigns.current_scope, ap, %{
        is_hidden: !ap.is_hidden
      })

    updated_ap =
      Assessments.get_assessment_point!(ap.id,
        preloads: [curriculum_item: :curriculum_component, scale: :ordinal_values]
      )

    socket =
      socket
      |> stream_insert(:assessment_points, updated_ap)
      |> assign(:command_palette_ap, updated_ap)

    {:ok, socket}
  end

  def update(%{action: {AssessmentPointFormOverlayComponent, {:updated, updated_ap}}}, socket) do
    socket =
      socket
      |> stream_insert(:assessment_points, updated_ap)
      |> assign(:assessment_point_overlay, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Assessment point updated successfully")})

    {:ok, socket}
  end

  def update(
        %{action: {AssessmentPointFormOverlayComponent, {action, _deleted_ap}}},
        socket
      )
      when action in [:deleted, :deleted_with_entries] do
    socket =
      socket
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:assessment_point_overlay, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Assessment point deleted")})

    {:ok, socket}
  end

  def update(%{action: {AssessmentPointFormOverlayComponent, _}}, socket) do
    {:ok, assign(socket, :assessment_point_overlay, nil)}
  end

  def update(
        %{action: {AssessmentPointCompositionOverlayComponent, {:composition_updated, _ap_id}}},
        socket
      ) do
    socket =
      socket
      |> stream_assessment_points()
      |> stream_students_entries()

    {:ok, socket}
  end

  def update(
        %{action: {AssessmentPointCompositionOverlayComponent, {:deleted, _ap_id}}},
        socket
      ) do
    socket =
      socket
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:composition_overlay_ap, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Grade composition deleted")})

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:no_class_action, fn -> [] end)
      |> assign_view_bg()

    socket =
      if socket.assigns.classes_ids == [] do
        socket
      else
        socket
        |> assign_grades_report_columns()
        |> stream_assessment_points()
        |> stream_students_entries()
      end

    {:ok, socket}
  end

  defp assign_view_bg(socket) do
    view_bg =
      case socket.assigns.current_assessment_view do
        "student" -> "bg-ltrn-student-lightest"
        _ -> "bg-white"
      end

    assign(socket, :view_bg, view_bg)
  end

  # The grades report column group is only shown in the strand context. The full
  # set of linked cards is fetched once by the parent and passed in as
  # `strand_grades_report_cards`; here we only narrow it to the active filter:
  # - no filter active → all linked grades report columns;
  # - a grades report filter active → only the filtered subject's column,
  #   shown alongside its composition's assessment points;
  # - an assessment point composition filter active → none (hidden).
  # When empty, the layout collapses to the assessment-points-only grid.
  defp assign_grades_report_columns(socket) do
    cards = socket.assigns.strand_grades_report_cards

    columns =
      case socket.assigns do
        %{
          filter_grades_report_cycle_id: cycle_id,
          filter_grades_report_subject_id: subject_id
        }
        when not is_nil(cycle_id) and not is_nil(subject_id) ->
          Enum.filter(cards, fn column ->
            column.grades_report_cycle &&
              column.grades_report_cycle.id == cycle_id &&
              column.grades_report_subject.id == subject_id
          end)

        %{filter_assessment_points_ids: nil} ->
          cards

        _ ->
          []
      end

    columns_count = length(columns)

    columns_grid =
      if columns_count == 0, do: "", else: "repeat(#{columns_count}, 12rem)"

    socket
    |> assign(:grades_report_columns, columns)
    |> assign(:grades_report_columns_count, columns_count)
    |> assign(:grades_report_columns_grid, columns_grid)
  end

  defp stream_assessment_points(socket) do
    {all_headers, all_assessment_points} =
      Assessments.list_strand_assessment_points(socket.assigns.strand_id)

    {assessment_point_headers, assessment_points} =
      case socket.assigns.filter_assessment_points_ids do
        nil ->
          {all_headers, all_assessment_points}

        filter_ids ->
          filtered_aps = Enum.filter(all_assessment_points, &(&1.id in filter_ids))
          {recompute_headers(all_headers, filtered_aps), filtered_aps}
      end

    assessment_points_count = length(assessment_points)

    composed_ids =
      assessment_points
      |> Enum.filter(& &1.uses_composition)
      |> MapSet.new(& &1.id)

    socket
    |> stream(:assessment_points, assessment_points, reset: true)
    |> stream(:assessment_point_headers, assessment_point_headers, reset: true)
    |> assign(:assessment_points_count, assessment_points_count)
    |> assign(:assessment_points_columns_grid, "repeat(#{assessment_points_count}, 12rem)")
    |> assign(:has_assessment_points, assessment_points != [])
    |> assign(:composed_assessment_point_ids, composed_ids)
  end

  defp recompute_headers(all_headers, filtered_aps) do
    filtered_count_map =
      filtered_aps
      |> Enum.group_by(& &1.moment_id)
      |> Map.new(fn {moment_id, aps} -> {moment_id, length(aps)} end)

    all_headers
    |> Enum.map(fn {struct, _} ->
      key =
        case struct do
          %Moment{} -> struct.id
          _ -> nil
        end

      {struct, Map.get(filtered_count_map, key, 0)}
    end)
    |> Enum.reject(fn {_, count} -> count == 0 end)
  end

  defp stream_students_entries(socket) do
    students_entries =
      Assessments.list_strand_students_entries(
        socket.assigns.strand_id,
        classes_ids: socket.assigns.classes_ids,
        load_profile_picture_from_cycle_id:
          socket.assigns.current_user.current_profile.current_school_cycle.id,
        active_students_only: true,
        check_if_has_evidences: true
      )

    students_entries =
      case socket.assigns.filter_assessment_points_ids do
        nil ->
          students_entries

        filter_ids ->
          Enum.map(students_entries, fn {student, entries} ->
            {student, Enum.filter(entries, &(&1.assessment_point_id in filter_ids))}
          end)
      end

    students_ids = Enum.map(students_entries, fn {student, _entries} -> student.id end)

    grades_maps =
      build_grades_report_grades_maps(socket.assigns.grades_report_columns, students_ids)

    students_entries_with_grades =
      Enum.map(students_entries, fn {student, entries} ->
        grade_cells =
          build_student_grade_cells(socket.assigns.grades_report_columns, grades_maps, student.id)

        {student, entries, grade_cells}
      end)

    socket
    |> assign(:students_ids, students_ids)
    |> stream(:students_entries, students_entries_with_grades, reset: true)
  end

  # Builds one grades cycle map per distinct `{grades_report_id, school_cycle_id}`
  # group, so multiple grades reports/cycles linked to the same strand resolve to
  # the right student entries. Each value is keyed by `student_id => %{subject_id => entry}`.
  defp build_grades_report_grades_maps([], _students_ids), do: %{}

  defp build_grades_report_grades_maps(columns, students_ids) do
    columns
    |> Enum.group_by(fn col -> {col.grades_report.id, col.school_cycle.id} end)
    |> Map.new(fn {{grades_report_id, school_cycle_id} = key, _cols} ->
      {key,
       GradesReports.build_students_grades_cycle_map(
         students_ids,
         grades_report_id,
         school_cycle_id
       )}
    end)
  end

  # Builds the grade cell payloads for a single student, positionally aligned to
  # `columns` (avoids subject-id collisions when the same subject appears under
  # two grades reports/cycles).
  defp build_student_grade_cells(columns, grades_maps, student_id) do
    Enum.map(columns, fn col ->
      entry =
        grades_maps
        |> Map.get({col.grades_report.id, col.school_cycle.id}, %{})
        |> Map.get(student_id, %{})
        |> Map.get(col.grades_report_subject.id)

      %{
        entry: entry,
        scale_id: col.scale.id,
        grades_report_id: col.grades_report.id,
        grades_report_cycle_id: col.grades_report_cycle && col.grades_report_cycle.id,
        grades_report_subject_id: col.grades_report_subject.id
      }
    end)
  end

  # event handlers

  @impl true
  def handle_event("save_changes", _params, socket) do
    if MapSet.size(socket.assigns.invalid_changes_set) > 0 do
      {:noreply, socket}
    else
      %{
        entries_changes_map: entries_changes_map,
        current_user: current_user
      } = socket.assigns

      changes = Map.values(entries_changes_map)

      socket =
        case Assessments.save_assessment_point_entries(changes,
               log_profile_id: current_user.current_profile_id
             ) do
          {:ok, count} ->
            msg = ngettext("1 entry updated", "%{count} entries updated", count)
            put_flash(socket, :info, msg)

          {:error, _changeset} ->
            msg = gettext("Error updating assessment point entries")
            put_flash(socket, :error, msg)
        end
        |> push_navigate(to: socket.assigns.navigate)

      {:noreply, socket}
    end
  end

  def handle_event("calculate_subject", params, socket) do
    %{
      "grades_report_id" => grades_report_id,
      "grades_report_cycle_id" => grades_report_cycle_id,
      "grades_report_subject_id" => grades_report_subject_id
    } = params

    socket =
      GradesReports.calculate_subject_grades(
        socket.assigns.students_ids,
        grades_report_id,
        grades_report_cycle_id,
        grades_report_subject_id
      )
      |> case do
        {:ok, results} ->
          socket
          |> stream_students_entries()
          |> delegate_navigation(
            put_flash:
              {:info,
               "#{gettext("Subject grades calculated successfully")}. #{build_calculation_results_message(results)}"}
          )

        {:error, _, results} ->
          delegate_navigation(socket,
            put_flash:
              {:error,
               "#{gettext("Something went wrong")}. #{gettext("Partial results")}: #{build_calculation_results_message(results)}"}
          )
      end

    {:noreply, socket}
  end

  def handle_event("calculate_cell", params, socket) do
    %{
      "student_id" => student_id,
      "grades_report_id" => grades_report_id,
      "grades_report_cycle_id" => grades_report_cycle_id,
      "grades_report_subject_id" => grades_report_subject_id
    } = params

    socket =
      GradesReports.calculate_student_grade(
        student_id,
        grades_report_id,
        grades_report_cycle_id,
        grades_report_subject_id,
        force_overwrite: true
      )
      |> case do
        {:ok, nil, :skipped} ->
          delegate_navigation(socket,
            put_flash:
              {:error,
               gettext("This student doesn't belong to this grade report's year and cycle")}
          )

        {:ok, nil, _} ->
          delegate_navigation(socket,
            put_flash: {:error, gettext("No assessment point entries for this grade composition")}
          )

        {:ok, _, _} ->
          socket
          |> stream_students_entries()
          |> delegate_navigation(put_flash: {:info, gettext("Grade calculated successfully")})

        {:error, _} ->
          delegate_navigation(socket, put_flash: {:error, gettext("Something went wrong")})
      end

    {:noreply, socket}
  end

  def handle_event("manage_grades_composition", params, socket) do
    %{
      "grades_report_cycle_id" => grades_report_cycle_id,
      "grades_report_subject_id" => grades_report_subject_id
    } = params

    column =
      Enum.find(socket.assigns.grades_report_columns, fn col ->
        "#{col.grades_report_subject.id}" == "#{grades_report_subject_id}" and
          col.grades_report_cycle != nil and
          "#{col.grades_report_cycle.id}" == "#{grades_report_cycle_id}"
      end)

    {:noreply, assign(socket, :grades_composition_overlay_column, column)}
  end

  def handle_event("close_grades_composition_overlay", _params, socket) do
    {:noreply, assign(socket, :grades_composition_overlay_column, nil)}
  end

  def handle_event("view_grade_entry", %{"id" => id, "scale_id" => scale_id}, socket) do
    entry =
      GradesReports.get_student_grades_report_entry!(id,
        preloads: [
          :student,
          :composition_ordinal_value,
          grades_report_subject: :subject,
          grades_report_cycle: :school_cycle
        ]
      )

    socket =
      socket
      |> assign(:student_grades_report_entry, entry)
      |> assign(:grades_report_entry_scale_id, scale_id)

    {:noreply, socket}
  end

  def handle_event("close_grade_entry_overlay", _params, socket) do
    {:noreply, assign(socket, :student_grades_report_entry, nil)}
  end

  def handle_event("open_command_palette", %{"id" => id}, socket) do
    ap =
      Assessments.get_assessment_point!(
        id,
        preloads: [curriculum_item: :curriculum_component, scale: :ordinal_values]
      )

    {:noreply, assign(socket, :command_palette_ap, ap)}
  end

  def handle_event("close_command_palette", _, socket) do
    {:noreply, assign(socket, :command_palette_ap, nil)}
  end

  def handle_event("close_assessment_point_form", _, socket) do
    {:noreply, assign(socket, :assessment_point_overlay, nil)}
  end

  def handle_event("close_composition_overlay", _, socket) do
    {:noreply, assign(socket, :composition_overlay_ap, nil)}
  end

  def handle_event("close_entry_details_overlay", _, socket) do
    socket =
      socket
      |> assign(:assessment_point_entry, nil)

    socket =
      if socket.assigns.has_entry_details_change do
        socket
        |> stream_assessment_points()
        |> stream_students_entries()
        |> assign(:has_entry_details_change, false)
      else
        socket
      end

    {:noreply, socket}
  end
end
