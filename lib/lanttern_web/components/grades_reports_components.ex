defmodule LantternWeb.GradesReportsComponents do
  @moduledoc """
  Shared function components related to `GradesReports` context
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.StudentGradesReportEntry
  alias Lanttern.GradesReports.StudentGradesReportFinalEntry

  # shared components
  alias LantternWeb.GradesReports.StudentGradesReportEntryButtonComponent

  @doc """
  Renders a grades report grid.

  Expects `[:school_cycle, grades_report_cycles: :school_cycle, grades_report_subjects: :subject]` preloads.
  """

  attr :grades_report, GradesReport, required: true
  attr :student_grades_map, :map, default: nil
  attr :on_student_grade_click, :any, default: nil
  attr :on_student_final_grade_click, :any, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :on_configure, JS, default: nil
  attr :report_card_cycle_id, :integer, default: nil
  attr :on_composition_click, JS, default: nil
  attr :show_cycle_visibility, :boolean, default: false

  def grades_report_grid(assigns) do
    %{
      grades_report_cycles: grades_report_cycles,
      grades_report_subjects: grades_report_subjects
    } = assigns.grades_report

    grid_template_columns_style =
      case length(grades_report_cycles) do
        n when n > 0 ->
          "grid-template-columns: 160px repeat(#{n + 1}, minmax(128px, 1fr))"

        _ ->
          "grid-template-columns: 160px minmax(128px, 1fr)"
      end

    grid_column_style =
      case length(grades_report_cycles) do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 2} / span #{n + 2}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:has_subjects, length(grades_report_subjects) > 0)
      |> assign(:has_cycles, length(grades_report_cycles) > 0)

    ~H"""
    <div class="relative p-2 overflow-x-auto">
      <div id={@id} class={["grid gap-1 text-sm", @class]} style={@grid_template_columns_style}>
        <%= if @on_configure do %>
          <.button
            type="button"
            theme="ghost"
            icon_name="hero-cog-6-tooth-mini"
            phx-click={@on_configure}
          >
            <%= gettext("Configure") %>
          </.button>
        <% else %>
          <div />
        <% end %>
        <%= if @has_cycles do %>
          <div
            :for={grades_report_cycle <- @grades_report.grades_report_cycles}
            id={"grid-header-cycle-#{grades_report_cycle.id}"}
            class={[
              "flex items-center justify-center gap-1 p-4 rounded shadow-lg",
              if(@report_card_cycle_id == grades_report_cycle.school_cycle_id,
                do: "font-bold bg-ltrn-mesh-cyan",
                else: "bg-white"
              )
            ]}
          >
            <%= grades_report_cycle.school_cycle.name %>
            <div
              :if={@show_cycle_visibility}
              class={[
                "flex items-center justify-center p-1 rounded-full",
                if(grades_report_cycle.is_visible,
                  do: "text-ltrn-primary bg-ltrn-mesh-cyan",
                  else: "text-ltrn-subtle"
                )
              ]}
            >
              <.icon name={if grades_report_cycle.is_visible, do: "hero-eye", else: "hero-eye-slash"} />
            </div>
          </div>
          <div class="flex items-center justify-center gap-1 p-4 rounded text-center bg-white shadow-lg">
            <span class={if !@report_card_cycle_id, do: "font-bold"}>
              <%= @grades_report.school_cycle.name %>
            </span>
            <div
              :if={@show_cycle_visibility}
              class={[
                "flex items-center justify-center p-1 rounded-full",
                if(@grades_report.final_is_visible,
                  do: "text-ltrn-primary bg-ltrn-mesh-cyan",
                  else: "text-ltrn-subtle"
                )
              ]}
            >
              <.icon name={if @grades_report.final_is_visible, do: "hero-eye", else: "hero-eye-slash"} />
            </div>
          </div>
        <% else %>
          <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
            <%= gettext("No cycles linked to this grades report") %>
          </div>
        <% end %>
        <%= if @has_subjects do %>
          <div
            :for={grades_report_subject <- @grades_report.grades_report_subjects}
            id={"grade-report-subject-#{grades_report_subject.id}"}
            class="grid grid-cols-subgrid"
            style={@grid_column_style}
          >
            <div class="sticky left-0 p-4 rounded bg-white shadow-lg">
              <%= Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                grades_report_subject.subject.name
              ) %>
            </div>
            <%= if @has_cycles do %>
              <.grades_report_grid_cell
                :for={grades_report_cycle <- @grades_report.grades_report_cycles}
                on_composition_click={
                  (@report_card_cycle_id == grades_report_cycle.school_cycle_id &&
                     @on_composition_click) || (!@report_card_cycle_id && @on_composition_click)
                }
                grades_report_id={@grades_report.id}
                grades_report_subject_id={grades_report_subject.id}
                grades_report_cycle_id={grades_report_cycle.id}
                student_grades_report_entry={
                  @student_grades_map &&
                    @student_grades_map[grades_report_cycle.id][grades_report_subject.id]
                }
                on_student_grade_click={@on_student_grade_click}
              />
              <.grades_report_grid_final_grade_cell
                on_click={@on_student_final_grade_click}
                student_grades_report_final_entry={
                  @student_grades_map &&
                    @student_grades_map[:final][grades_report_subject.id]
                }
              />
            <% else %>
              <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% else %>
          <div class="grid grid-cols-subgrid" style={@grid_column_style}>
            <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
              <%= gettext("No subjects linked to this grades report") %>
            </div>
            <%= if @has_cycles do %>
              <.grades_report_grid_cell :for={
                _grades_report_cycle <- @grades_report.grades_report_cycles
              } />
              <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% else %>
              <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :on_composition_click, JS
  attr :on_student_grade_click, JS
  attr :student_grades_report_entry, StudentGradesReportEntry
  attr :grades_report_id, :integer, default: nil
  attr :grades_report_subject_id, :integer, default: nil
  attr :grades_report_cycle_id, :integer, default: nil

  defp grades_report_grid_cell(
         %{student_grades_report_entry: %StudentGradesReportEntry{ordinal_value_id: ov_id}} =
           assigns
       )
       when not is_nil(ov_id) do
    ~H"""
    <div class="flex items-stretch justify-stretch gap-1">
      <.live_component
        :if={@student_grades_report_entry.pre_retake_ordinal_value_id}
        module={StudentGradesReportEntryButtonComponent}
        is_pre_retake
        id={"student-grades-report-entry-#{@student_grades_report_entry.id}-pre-retake"}
        student_grades_report_entry={@student_grades_report_entry}
        class="flex-1 my-2 opacity-70"
        on_click={
          if(@on_student_grade_click, do: @on_student_grade_click.(@student_grades_report_entry.id))
        }
      />
      <.live_component
        module={StudentGradesReportEntryButtonComponent}
        id={"student-grades-report-entry-#{@student_grades_report_entry.id}"}
        student_grades_report_entry={@student_grades_report_entry}
        class="flex-[2]"
        on_click={
          if(@on_student_grade_click, do: @on_student_grade_click.(@student_grades_report_entry.id))
        }
      />
    </div>
    """
  end

  defp grades_report_grid_cell(
         %{student_grades_report_entry: %StudentGradesReportEntry{}} = assigns
       ) do
    ~H"""
    <div class="flex items-stretch justify-stretch gap-1 font-mono font-bold">
      <button
        :if={@student_grades_report_entry.pre_retake_score}
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-studentgradereportid={@student_grades_report_entry.id}
        phx-value-gradesreportsubjectid={@student_grades_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grades_report_entry.grades_report_cycle_id}
        class="flex-1 rounded border border-ltrn-lighter my-2 text-sm bg-ltrn-lightest opacity-70"
      >
        <%= @student_grades_report_entry.pre_retake_score %>
      </button>
      <button
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-studentgradereportid={@student_grades_report_entry.id}
        phx-value-gradesreportsubjectid={@student_grades_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grades_report_entry.grades_report_cycle_id}
        class="flex-[2] rounded border border-ltrn-lighter text-base bg-ltrn-lightest"
      >
        <%= @student_grades_report_entry.score %>
      </button>
    </div>
    """
  end

  defp grades_report_grid_cell(%{on_composition_click: %JS{}} = assigns) do
    ~H"""
    <.button
      type="button"
      theme="ghost"
      icon_name="hero-calculator-mini"
      phx-click={@on_composition_click}
      phx-value-gradesreportid={@grades_report_id}
      phx-value-gradesreportsubjectid={@grades_report_subject_id}
      phx-value-gradesreportcycleid={@grades_report_cycle_id}
      class="border border-ltrn-lighter"
    >
      <%= gettext("Comp") %>
    </.button>
    """
  end

  defp grades_report_grid_cell(assigns) do
    ~H"""
    <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
    """
  end

  attr :on_click, :any
  attr :student_grades_report_final_entry, StudentGradesReportFinalEntry

  defp grades_report_grid_final_grade_cell(
         %{student_grades_report_final_entry: %StudentGradesReportFinalEntry{}} =
           assigns
       ) do
    ~H"""
    <div class="flex items-stretch justify-stretch gap-1">
      <.live_component
        :if={@student_grades_report_final_entry.pre_retake_ordinal_value_id}
        module={StudentGradesReportEntryButtonComponent}
        is_pre_retake
        id={"student-grades-report-final-entry-#{@student_grades_report_final_entry.id}-pre-retake"}
        student_grades_report_entry={@student_grades_report_final_entry}
        class="flex-1 my-2 opacity-70"
        on_click={
          if(@on_click,
            do: @on_click.(@student_grades_report_final_entry.id)
          )
        }
      />
      <.live_component
        module={StudentGradesReportEntryButtonComponent}
        id={"student-grades-report-final-entry-#{@student_grades_report_final_entry.id}"}
        student_grades_report_entry={@student_grades_report_final_entry}
        class="flex-[2]"
        on_click={
          if(@on_click,
            do: @on_click.(@student_grades_report_final_entry.id)
          )
        }
      />
    </div>
    """
  end

  defp grades_report_grid_final_grade_cell(assigns) do
    ~H"""
    <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
    """
  end

  @doc """
  Renders a full students grades grid for a given grades report.
  """

  attr :students, Phoenix.LiveView.LiveStream, required: true
  attr :cycle_name, :string, required: true
  attr :has_students, :boolean, required: true
  attr :final_is_visible, :boolean, required: true
  attr :grades_report_cycles, :list, required: true
  attr :grades_report_subjects, :list, required: true
  attr :students_grades_map, :map, required: true
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  attr :on_toggle_final_grades_visibility, :any, default: nil

  attr :on_calculate_final, :any,
    default: nil,
    doc: "the function to trigger when clicking on calculate final grades"

  attr :on_calculate_student, :any,
    default: nil,
    doc: "the function to trigger when clicking on calculate student. args: `student_id`"

  attr :on_calculate_subject, :any,
    default: nil,
    doc:
      "the function to trigger when clicking on calculate subject. args: `grades_report_subject_id`"

  attr :on_calculate_cell, :any,
    default: nil,
    doc:
      "the function to trigger when clicking on calculate cell. args: `student_id`, `grades_report_subject_id`"

  attr :on_entry_click, :any,
    default: nil,
    doc: "the function to trigger when clicking on student grades report entry. args: `sgre_id`"

  attr :on_final_entry_click, :any,
    default: nil,
    doc:
      "the function to trigger when clicking on student grades report final entry. args: `sgrfe_id`"

  def students_grades_report_full_grid(assigns) do
    %{
      has_students: has_students,
      grades_report_cycles: grades_report_cycles,
      grades_report_subjects: grades_report_subjects
    } = assigns

    cycles_count = length(grades_report_cycles)
    subjects_count = length(grades_report_subjects)

    has_cycles = cycles_count > 0
    has_subjects = subjects_count > 0

    # we should display actions only if we have cycles, subjects, and students
    display_actions = has_cycles && has_subjects && has_students

    grid_template_columns_style =
      case {has_cycles, has_subjects} do
        {true, true} ->
          n = cycles_count * subjects_count

          "grid-template-columns: 200px repeat(#{n}, minmax(5rem, 1fr)) repeat(#{subjects_count}, minmax(9rem, 1fr))"

        {true, false} ->
          "grid-template-columns: 200px repeat(#{cycles_count + 1}, minmax(5rem, 1fr))"

        {false, true} ->
          "grid-template-columns: 200px repeat(#{subjects_count}, minmax(5rem, 1fr))"

        _ ->
          "grid-template-columns: 200px minmax(10px, 1fr)"
      end

    row_grid_column_span_style =
      case {has_cycles, has_subjects} do
        {true, true} ->
          n = cycles_count * subjects_count + subjects_count + 1
          "grid-column: span #{n} / span #{n}"

        {true, false} ->
          # cycles + parent cycle + students col
          n = cycles_count + 2
          "grid-column: span #{n} / span #{n}"

        {false, true} ->
          n = subjects_count + 1
          "grid-column: span #{n} / span #{n}"

        _ ->
          "grid-column: span 2 / span 2"
      end

    cycle_grid_column_span_style = "grid-column: span #{subjects_count} / span #{subjects_count}"

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:row_grid_column_span_style, row_grid_column_span_style)
      |> assign(:cycle_grid_column_span_style, cycle_grid_column_span_style)
      |> assign(:has_cycles, has_cycles)
      |> assign(:has_subjects, has_subjects)
      |> assign(:display_actions, display_actions)

    ~H"""
    <div
      id={@id}
      class={[
        "relative grid gap-px w-full max-h-screen overflow-x-auto pr-px text-sm bg-ltrn-lighter",
        @class
      ]}
      style={@grid_template_columns_style}
    >
      <div
        class="sticky top-0 z-20 grid grid-cols-subgrid bg-ltrn-lighter"
        style={@row_grid_column_span_style}
      >
        <div class="sticky left-0 z-20 row-span-2 border-r-2 border-b-2 border-ltrn-subtle bg-white">
        </div>
        <%= if @has_cycles do %>
          <div
            :for={grades_report_cycle <- @grades_report_cycles}
            id={"students-grades-grid-header-cycle-#{grades_report_cycle.id}"}
            class="flex items-center justify-center p-2 border-r-2 border-ltrn-subtle text-center truncate bg-white"
            style={@cycle_grid_column_span_style}
          >
            <%= grades_report_cycle.school_cycle.name %>
          </div>
          <div
            id="students-grades-grid-header-parent-cycle"
            class="flex items-center justify-center gap-2 p-2 text-center text-white truncate bg-ltrn-dark"
            style={@cycle_grid_column_span_style}
          >
            <%= @cycle_name %> (<%= gettext("Final grades") %>)
            <%= if @display_actions && @on_calculate_final do %>
              <.icon_button
                name="hero-arrow-path-mini"
                sr_text={gettext("Calculate final grades")}
                rounded
                size="sm"
                theme="white"
                phx-click={@on_calculate_final.()}
                data-confirm={
                  gettext(
                    "Are you sure? All final grades will be created, updated, and removed based on their grade composition."
                  )
                }
                title={gettext("Calculate final grades")}
              />
              <.icon_button
                name={if @final_is_visible, do: "hero-eye-mini", else: "hero-eye-slash-mini"}
                sr_text={gettext("Parent cycle visibility")}
                rounded
                size="sm"
                theme={if @final_is_visible, do: "primary_light", else: "ghost"}
                phx-click={@on_toggle_final_grades_visibility.()}
                title={
                  if @final_is_visible,
                    do: gettext("Final grades are visible"),
                    else: gettext("Final grades not visible")
                }
              />
            <% end %>
          </div>
        <% else %>
          <div class="p-2 text-center text-ltrn-subtle" style={@cycle_grid_column_span_style}>
            <%= gettext("No cycles linked to this grades report") %>
          </div>
        <% end %>
        <%= if @has_subjects do %>
          <div
            :for={grades_report_cycle <- @grades_report_cycles}
            class="grid grid-cols-subgrid border-r-2 border-ltrn-subtle"
            style={@cycle_grid_column_span_style}
          >
            <div
              :for={grades_report_subject <- @grades_report_subjects}
              id={"students-grades-grid-header-subject-#{grades_report_subject.id}-#{grades_report_cycle.id}"}
              class="flex items-center justify-center w-20 min-w-full p-2 border-b-2 border-ltrn-subtle mt-px bg-white last:border-r-2 last:border-ltrn-subtle"
              title={
                Gettext.dgettext(
                  LantternWeb.Gettext,
                  "taxonomy",
                  grades_report_subject.subject.name
                )
              }
            >
              <div class="truncate">
                <%= Gettext.dgettext(
                  LantternWeb.Gettext,
                  "taxonomy",
                  grades_report_subject.subject.short_name || grades_report_subject.subject.name
                ) %>
              </div>
            </div>
          </div>
          <div
            :for={grades_report_subject <- @grades_report_subjects}
            id={"students-grades-grid-header-subject-#{grades_report_subject.id}"}
            class="flex items-center justify-center gap-2 w-20 min-w-full py-2 px-1 border-b-2 border-ltrn-subtle mt-px text-white bg-ltrn-dark"
            title={
              Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                grades_report_subject.subject.name
              )
            }
          >
            <div class="flex-1 text-center truncate">
              <%= Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                grades_report_subject.subject.short_name || grades_report_subject.subject.name
              ) %>
            </div>
            <.icon_button
              :if={@display_actions && @on_calculate_subject}
              name="hero-arrow-path-mini"
              theme="white"
              rounded
              size="sm"
              sr_text={gettext("Calculate subject grades")}
              phx-click={@on_calculate_subject.(grades_report_subject.id)}
              data-confirm={
                gettext(
                  "Are you sure? Final grades related to this subject will be created, updated, and removed based on their grade composition."
                )
              }
            />
          </div>
        <% else %>
          <div
            :for={_grades_report_cycles <- @grades_report_cycles}
            class="p-2 border-b-2 border-r-2 border-ltrn-subtle text-center text-ltrn-subtle"
          >
            <%= gettext("No subjects linked to this grades report") %>
          </div>
          <div class="p-2 border-b-2 border-ltrn-subtle text-center text-ltrn-subtle">
            <%= gettext("No subjects linked to this grades report") %>
          </div>
        <% end %>
      </div>
      <%= if @has_students do %>
        <div
          id="students-grades-grid-students"
          class="grid grid-cols-subgrid gap-px"
          style={@row_grid_column_span_style}
          phx-update="stream"
        >
          <div
            :for={{dom_id, student} <- @students}
            id={"students-grades-grid-#{dom_id}"}
            class="grid grid-cols-subgrid"
            style={@row_grid_column_span_style}
          >
            <div class="sticky left-0 z-10 flex items-center gap-2 p-2 border-r-2 border-ltrn-subtle bg-white">
              <.profile_icon_with_name
                icon_size="sm"
                class="flex-1"
                profile_name={student.name}
                extra_info={student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
              />
              <.icon_button
                :if={@display_actions && @on_calculate_student}
                name="hero-arrow-path-mini"
                theme="white"
                rounded
                size="sm"
                sr_text={gettext("Calculate student grades")}
                phx-click={@on_calculate_student.(student.id)}
                data-confirm={
                  gettext(
                    "Are you sure? Final grades related to this student will be created, updated, and removed based on their grade composition."
                  )
                }
              />
            </div>
            <%= if @has_cycles and @has_subjects do %>
              <div
                :for={grades_report_cycle <- @grades_report_cycles}
                class="grid grid-cols-subgrid border-r-2 border-ltrn-subtle"
                style={@cycle_grid_column_span_style}
              >
                <.students_grades_grid_cell
                  :for={grades_report_subject <- @grades_report_subjects}
                  entry={
                    @students_grades_map[student.id][grades_report_cycle.id][grades_report_subject.id]
                  }
                  on_calculate_cell={nil}
                  on_entry_click={@on_entry_click}
                  grades_report_subject_id={grades_report_subject.id}
                  grades_report_cycle_id={grades_report_cycle.id}
                  student_id={student.id}
                />
              </div>
              <div class="grid grid-cols-subgrid" style={@cycle_grid_column_span_style}>
                <.students_grades_grid_cell
                  :for={grades_report_subject <- @grades_report_subjects}
                  entry={@students_grades_map[student.id][:final][grades_report_subject.id]}
                  on_calculate_cell={@on_calculate_cell}
                  on_entry_click={@on_final_entry_click}
                  grades_report_subject_id={grades_report_subject.id}
                  grades_report_cycle_id={0}
                  student_id={student.id}
                />
              </div>
            <% end %>
          </div>
        </div>
      <% else %>
        <div class="sticky left-0 flex items-center justify-center p-4 border-r-2 border-ltrn-subtle text-ltrn-subtle">
          <%= gettext("No students linked to this grades report") %>
        </div>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a student grades grid for a given cycle.
  """

  attr :students, :list, required: true
  attr :grades_report_subjects, :list, required: true
  attr :students_grades_map, :map, required: true
  attr :class, :any, default: nil
  attr :id, :string, default: nil

  attr :on_calculate_cycle, :any,
    default: nil,
    doc: "the function to trigger when clicking on calculate all"

  attr :on_calculate_student, :any,
    default: nil,
    doc: "the function to trigger when clicking on calculate student. args: `student_id`"

  attr :on_calculate_subject, :any,
    default: nil,
    doc:
      "the function to trigger when clicking on calculate subject. args: `grades_report_subject_id`"

  attr :on_calculate_cell, :any,
    default: nil,
    doc:
      "the function to trigger when clicking on calculate cell. args: `student_id`, `grades_report_subject_id`"

  attr :on_entry_click, :any,
    default: nil,
    doc: "the function to trigger when clicking on student grades report entry. args: `sgre_id`"

  def students_grades_grid(assigns) do
    %{
      students: students,
      grades_report_subjects: grades_report_subjects
    } = assigns

    subjects_count = length(grades_report_subjects)

    grid_template_columns_style =
      case subjects_count do
        n when n > 0 ->
          "grid-template-columns: 200px repeat(#{n}, minmax(144px, 1fr))"

        _ ->
          "grid-template-columns: 200px minmax(144px, 1fr)"
      end

    grid_column_style =
      case subjects_count do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:has_subjects, subjects_count > 0)
      |> assign(:has_students, length(students) > 0)

    ~H"""
    <div
      id={@id}
      class={[
        "relative grid gap-px w-full max-h-screen text-sm bg-ltrn-lighter overflow-x-auto",
        @class
      ]}
      style={@grid_template_columns_style}
    >
      <div
        class="sticky top-0 z-20 grid grid-cols-subgrid border-b-2 border-ltrn-subtle bg-ltrn-lighter"
        style={@grid_column_style}
      >
        <%= if @on_calculate_cycle do %>
          <.button
            type="button"
            theme="white"
            icon_name="hero-arrow-path-mini"
            phx-click={@on_calculate_cycle.()}
            data-confirm={
              gettext(
                "Are you sure? All grades will be created, updated, and removed based on their grade composition."
              )
            }
            class="sticky left-0 z-10"
          >
            <%= gettext("Calculate all") %>
          </.button>
        <% else %>
          <div class="sticky left-0"></div>
        <% end %>
        <%= if @has_subjects do %>
          <div
            :for={grades_report_subject <- @grades_report_subjects}
            id={"students-grades-grid-header-subject-#{grades_report_subject.id}"}
            class="flex items-center justify-center gap-2 px-1 py-2 text-center bg-white"
          >
            <span class="flex-1 truncate">
              <%= Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                grades_report_subject.subject.name
              ) %>
            </span>
            <.icon_button
              :if={@on_calculate_subject}
              name="hero-arrow-path-mini"
              theme="white"
              rounded
              size="sm"
              sr_text={gettext("Calculate subject grades")}
              phx-click={@on_calculate_subject.(grades_report_subject.id)}
              data-confirm={
                gettext(
                  "Are you sure? Grades related to this subject will be created, updated, and removed based on their grade composition."
                )
              }
            />
          </div>
        <% else %>
          <div class="p-2 rounded text-ltrn-subtle bg-ltrn-lightest">
            <%= gettext("No cycles linked to this grades report") %>
          </div>
        <% end %>
      </div>
      <%= if @has_students do %>
        <div
          :for={student <- @students}
          id={"students-grades-grid-student-#{student.id}"}
          class="grid grid-cols-subgrid"
          style={@grid_column_style}
        >
          <div class="sticky left-0 z-10 flex items-center gap-2 px-2 py-4 bg-white">
            <.profile_icon_with_name
              icon_size="sm"
              class="flex-1"
              profile_name={student.name}
              extra_info={student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
            />
            <.icon_button
              :if={@on_calculate_student}
              name="hero-arrow-path-mini"
              theme="white"
              rounded
              size="sm"
              sr_text={gettext("Calculate student grades")}
              phx-click={@on_calculate_student.(student.id)}
              data-confirm={
                gettext(
                  "Are you sure? Grades related to this student will be created, updated, and removed based on their grade composition."
                )
              }
            />
          </div>
          <%= if @has_subjects do %>
            <.students_grades_grid_cell
              :for={grades_report_subject <- @grades_report_subjects}
              entry={@students_grades_map[student.id][grades_report_subject.id]}
              on_calculate_cell={@on_calculate_cell}
              on_entry_click={@on_entry_click}
              grades_report_subject_id={grades_report_subject.id}
              grades_report_cycle_id={0}
              student_id={student.id}
            />
          <% else %>
            <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
          <% end %>
        </div>
      <% else %>
        <div class="grid grid-cols-subgrid" style={@grid_column_style}>
          <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
            <%= gettext("No students linked to this grades report") %>
          </div>
          <%= if @has_subjects do %>
            <.grades_report_grid_cell :for={_grades_report_subject <- @grades_report_subjects} />
          <% else %>
            <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :entry, :map,
    default: nil,
    doc: "a `StudentGradesReportEntry` or `StudentGradesReportFinalEntry`"

  attr :student_id, :integer, default: nil
  attr :grades_report_subject_id, :integer, required: true
  attr :grades_report_cycle_id, :integer, required: true, doc: "use `0` for parent cycle"
  attr :on_calculate_cell, :any, required: true
  attr :on_entry_click, :any, required: true

  defp students_grades_grid_cell(%{entry: %{}} = assigns) do
    wrapper_class =
      case assigns.entry.comment || assigns.on_calculate_cell do
        nil -> ""
        _ -> "p-1 border border-ltrn-light"
      end

    wrapper_class =
      case assigns.entry do
        %{ordinal_value_id: ov_id} = entry when not is_nil(ov_id) ->
          if entry.ordinal_value_id == entry.composition_ordinal_value_id,
            do: wrapper_class,
            else: "p-1 border border-ltrn-teacher-accent bg-ltrn-teacher-lightest"

        %{} = entry ->
          if entry.score == entry.composition_score,
            do: wrapper_class,
            else: "p-1 border border-ltrn-teacher-accent bg-ltrn-teacher-lightest"
      end

    has_manual_grade =
      case assigns.entry do
        %{
          ordinal_value_id: ov_id,
          composition_ordinal_value_id: comp_ov_id
        }
        when ov_id != comp_ov_id ->
          true

        %{score: score, composition_score: comp_score}
        when score != comp_score ->
          true

        _ ->
          false
      end

    assigns =
      assigns
      |> assign(:wrapper_class, wrapper_class)
      |> assign(:has_manual_grade, has_manual_grade)

    ~H"""
    <div class={[
      "relative flex items-center justify-center gap-px",
      @wrapper_class
    ]}>
      <.students_grades_grid_cell_value
        id={"#{@student_id}_#{@grades_report_subject_id}_#{@grades_report_cycle_id}"}
        entry={@entry}
        on_entry_click={@on_entry_click}
      />
      <div
        :if={@entry.comment || @on_calculate_cell}
        class="flex flex-col gap-1 justify-center items-center ml-1"
      >
        <.icon
          :if={@entry.comment}
          name="hero-chat-bubble-oval-left-mini"
          class="text-ltrn-teacher-accent"
        />
        <.icon_button
          :if={@on_calculate_cell}
          name="hero-arrow-path-mini"
          theme="white"
          rounded
          size="sm"
          sr_text={gettext("Recalculate grade")}
          phx-click={@on_calculate_cell.(@student_id, @grades_report_subject_id)}
          data-confirm={
            if @has_manual_grade,
              do:
                gettext(
                  "There is a manual grade change that will be overwritten by this operation. Are you sure you want to proceed?"
                )
          }
        />
      </div>
    </div>
    """
  end

  defp students_grades_grid_cell(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-2 p-1 border border-ltrn-light rounded-sm text-ltrn-subtle">
      <div class="flex-1 text-center">N/A</div>
      <.icon_button
        :if={@on_calculate_cell}
        name="hero-plus-mini"
        theme="white"
        rounded
        size="sm"
        sr_text={gettext("Calculate grade")}
        phx-click={@on_calculate_cell.(@student_id, @grades_report_subject_id)}
      />
    </div>
    """
  end

  attr :entry, :map,
    required: true,
    doc: "a `StudentGradesReportEntry` or `StudentGradesReportFinalEntry`"

  attr :id, :string,
    required: true,
    doc: "a unique id to render `StudentGradesReportEntryButtonComponent`"

  attr :on_entry_click, :any, required: true

  defp students_grades_grid_cell_value(assigns) do
    has_retake_history =
      assigns.entry.pre_retake_ordinal_value_id != nil || assigns.entry.pre_retake_score != nil

    assigns =
      assigns
      |> assign(:has_retake_history, has_retake_history)

    ~H"""
    <.live_component
      :if={@has_retake_history}
      module={StudentGradesReportEntryButtonComponent}
      is_pre_retake
      id={"pre-retake-#{@id}"}
      student_grades_report_entry={@entry}
      class="flex-1 self-stretch my-2 text-xs opacity-70"
      on_click={if(@on_entry_click, do: @on_entry_click.(@entry.id))}
    />
    <.live_component
      module={StudentGradesReportEntryButtonComponent}
      id={@id}
      student_grades_report_entry={@entry}
      class="flex-[2] self-stretch"
      on_click={if(@on_entry_click, do: @on_entry_click.(@entry.id))}
    />
    """
  end

  @doc """
  Renders a grade composition table.
  """
  attr :student_grades_report_entry, StudentGradesReportEntry, required: true
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def grade_composition_table(assigns) do
    ~H"""
    <div id={@id} class="w-full overflow-x-auto">
      <table class={["w-full rounded font-mono text-xs bg-ltrn-lightest", @class]}>
        <thead>
          <tr>
            <th class="p-2 text-left"><%= gettext("Strand") %></th>
            <th class="p-2 text-left"><%= gettext("Curriculum") %></th>
            <th class="p-2 text-left"><%= gettext("Assessment") %></th>
            <th class="p-2 text-right"><%= gettext("Weight") %></th>
            <th class="p-2 text-right"><%= gettext("Normalized value") %></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={component <- @student_grades_report_entry.composition}>
            <td class="p-2">
              <span :if={component.strand_type}>
                (<%= component.strand_type %>)
              </span>
              <%= component.strand_name %>
            </td>
            <td class="p-2">
              (<%= component.curriculum_component_name %>) <%= component.curriculum_item_name %>
            </td>
            <td class="p-2">
              <%= component.ordinal_value_name ||
                :erlang.float_to_binary(component.score, decimals: 2) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(component.weight, decimals: 1) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(
                component.normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
          <tr class="font-bold bg-ltrn-lighter">
            <td colspan="2" class="p-2">
              <%= gettext("Final grade") %>
            </td>
            <td class="p-2">
              <%= case @student_grades_report_entry.composition_ordinal_value do
                nil ->
                  :erlang.float_to_binary(
                    @student_grades_report_entry.composition_score,
                    decimals: 2
                  )

                ov ->
                  ov.name
              end %>
            </td>
            <td colspan="2" class="p-2 text-right">
              <%= :erlang.float_to_binary(
                @student_grades_report_entry.composition_normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a final grade composition table.
  """
  attr :student_grades_report_final_entry, StudentGradesReportFinalEntry, required: true
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def final_grade_composition_table(assigns) do
    ~H"""
    <div id={@id} class="w-full overflow-x-auto">
      <table class={["w-full rounded font-mono text-xs bg-ltrn-lightest", @class]}>
        <thead>
          <tr>
            <th class="p-2 text-left"><%= gettext("Cycle") %></th>
            <th class="p-2 text-left"><%= gettext("Assessment") %></th>
            <th class="p-2 text-right"><%= gettext("Weight") %></th>
            <th class="p-2 text-right"><%= gettext("Normalized value") %></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={component <- @student_grades_report_final_entry.composition}>
            <td class="p-2">
              <%= component.school_cycle_name %>
            </td>
            <td class="p-2">
              <%= component.ordinal_value_name ||
                :erlang.float_to_binary(component.score, decimals: 2) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(component.weight, decimals: 1) %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(
                component.normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
          <tr class="font-bold bg-ltrn-lighter">
            <td class="p-2">
              <%= gettext("Final grade") %>
            </td>
            <td colspan="2" class="p-2">
              <%= case @student_grades_report_final_entry.composition_ordinal_value do
                nil ->
                  :erlang.float_to_binary(
                    @student_grades_report_final_entry.composition_score,
                    decimals: 2
                  )

                ov ->
                  ov.name
              end %>
            </td>
            <td class="p-2 text-right">
              <%= :erlang.float_to_binary(
                @student_grades_report_final_entry.composition_normalized_value,
                decimals: 2
              ) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
