defmodule LantternWeb.GradesReportsComponents do
  @moduledoc """
  Shared function components related to `GradesReports` context
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents, only: [apply_style_from_ordinal_value: 1]

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.GradesReports.StudentGradeReportEntry
  alias Lanttern.Grading.OrdinalValue

  @doc """
  Renders a grades report grid.

  Expects `[:school_cycle, grades_report_cycles: :school_cycle, grades_report_subjects: :subject]` preloads.
  """

  attr :grades_report, GradesReport, required: true
  attr :student_grades_map, :map, default: nil
  attr :on_student_grade_click, JS, default: nil
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :on_setup, JS, default: nil
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
        <%= if @on_setup do %>
          <.button type="button" theme="ghost" icon_name="hero-cog-6-tooth-mini" phx-click={@on_setup}>
            <%= gettext("Setup") %>
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
                  else: "text-ltrn-subtle bg-ltrn-lighter"
                )
              ]}
            >
              <.icon name={if grades_report_cycle.is_visible, do: "hero-eye", else: "hero-eye-slash"} />
            </div>
          </div>
          <div class="p-4 rounded text-center bg-white shadow-lg">
            <%= @grades_report.school_cycle.name %>
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
                student_grade_report_entry={
                  @student_grades_map &&
                    @student_grades_map[grades_report_cycle.id][grades_report_subject.id]
                }
                on_student_grade_click={@on_student_grade_click}
              />
              <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
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
  attr :student_grade_report_entry, StudentGradeReportEntry
  attr :grades_report_id, :integer, default: nil
  attr :grades_report_subject_id, :integer, default: nil
  attr :grades_report_cycle_id, :integer, default: nil

  defp grades_report_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{ordinal_value: %OrdinalValue{}}} =
           assigns
       ) do
    ~H"""
    <div class="flex items-stretch justify-stretch gap-1">
      <.button
        :if={@student_grade_report_entry.pre_retake_ordinal_value}
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
        {apply_style_from_ordinal_value(@student_grade_report_entry.pre_retake_ordinal_value)}
        class="flex-1 my-2 opacity-70"
      >
        <%= @student_grade_report_entry.pre_retake_ordinal_value.name %>
      </.button>
      <.button
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
        {apply_style_from_ordinal_value(@student_grade_report_entry.ordinal_value)}
        class="flex-[2]"
      >
        <%= @student_grade_report_entry.ordinal_value.name %>
      </.button>
    </div>
    """
  end

  defp grades_report_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{}} = assigns
       ) do
    ~H"""
    <div class="flex items-stretch justify-stretch gap-1 font-mono font-bold">
      <button
        :if={@student_grade_report_entry.pre_retake_score}
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
        class="flex-1 rounded border border-ltrn-lighter my-2 text-sm bg-ltrn-lightest opacity-70"
      >
        <%= @student_grade_report_entry.pre_retake_score %>
      </button>
      <button
        type="button"
        phx-click={@on_student_grade_click}
        phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
        phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
        class="flex-[2] rounded border border-ltrn-lighter text-base bg-ltrn-lightest"
      >
        <%= @student_grade_report_entry.score %>
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
        "relative w-full max-h-[calc(100vh-4rem)] rounded bg-white shadow-xl overflow-x-auto",
        @class
      ]}
    >
      <div class="relative grid gap-1 w-max text-sm" style={@grid_template_columns_style}>
        <div class="sticky top-0 z-20 grid grid-cols-subgrid p-1 bg-white" style={@grid_column_style}>
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
              class="sticky left-1 z-10"
            >
              <%= gettext("Calculate all") %>
            </.button>
          <% else %>
            <div class="sticky left-1"></div>
          <% end %>
          <%= if @has_subjects do %>
            <div
              :for={grades_report_subject <- @grades_report_subjects}
              id={"students-grades-grid-header-subject-#{grades_report_subject.id}"}
              class="flex items-center justify-center gap-2 px-1 py-4 rounded text-center bg-white shadow-lg"
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
            class="grid grid-cols-subgrid px-1"
            style={@grid_column_style}
          >
            <div class="sticky left-1 z-10 flex items-center gap-2 px-2 py-4 rounded bg-white shadow-lg">
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
                student_grade_report_entry={
                  @students_grades_map[student.id][grades_report_subject.id]
                }
                on_calculate_cell={@on_calculate_cell}
                on_entry_click={@on_entry_click}
                grades_report_subject_id={grades_report_subject.id}
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
    </div>
    """
  end

  attr :student_grade_report_entry, StudentGradeReportEntry, default: nil
  attr :student_id, :integer, default: nil
  attr :grades_report_subject_id, :integer, default: nil
  attr :on_calculate_cell, :any, required: true
  attr :on_entry_click, :any, required: true

  defp students_grades_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{}} =
           assigns
       ) do
    bg_class =
      case assigns.student_grade_report_entry do
        %StudentGradeReportEntry{ordinal_value: %OrdinalValue{}} = sgre ->
          if sgre.ordinal_value_id == sgre.composition_ordinal_value_id,
            do: "border-ltrn-lighter bg-ltrn-lightest",
            else: "border-ltrn-teacher-accent bg-ltrn-teacher-lightest"

        %StudentGradeReportEntry{} = sgre ->
          if sgre.score == sgre.composition_score,
            do: "border-ltrn-lighter bg-ltrn-lightest",
            else: "border-ltrn-teacher-accent bg-ltrn-teacher-lightest"
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)

    ~H"""
    <div class={[
      "relative flex items-center justify-center gap-1 p-1 border rounded",
      @bg_class
    ]}>
      <.students_grades_grid_cell_value
        student_grade_report_entry={@student_grade_report_entry}
        on_entry_click={@on_entry_click}
      />
      <div
        :if={@student_grade_report_entry.comment || @on_calculate_cell}
        class="flex flex-col gap-1 justify-center items-center ml-1"
      >
        <.icon
          :if={@student_grade_report_entry.comment}
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
        />
      </div>
    </div>
    """
  end

  defp students_grades_grid_cell(assigns) do
    ~H"""
    <div class="flex items-center justify-center gap-2 p-1 rounded border border-ltrn-lighter text-ltrn-subtle bg-ltrn-lightest">
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

  attr :student_grade_report_entry, StudentGradeReportEntry, required: true
  attr :on_entry_click, :any, required: true

  defp students_grades_grid_cell_value(
         %{student_grade_report_entry: %StudentGradeReportEntry{ordinal_value: %OrdinalValue{}}} =
           assigns
       ) do
    has_retake_history = assigns.student_grade_report_entry.pre_retake_ordinal_value_id != nil

    assigns =
      assigns
      |> assign(:has_retake_history, has_retake_history)

    ~H"""
    <button
      :if={@has_retake_history}
      class="flex-1 self-stretch flex items-center justify-center border rounded-sm my-2 text-xs opacity-70"
      {apply_style_from_ordinal_value(@student_grade_report_entry.pre_retake_ordinal_value)}
      phx-click={if(@on_entry_click, do: @on_entry_click.(@student_grade_report_entry.id))}
    >
      <%= @student_grade_report_entry.pre_retake_ordinal_value.name %>
    </button>
    <button
      class="flex-[2] self-stretch flex items-center justify-center rounded-sm"
      {apply_style_from_ordinal_value(@student_grade_report_entry.ordinal_value)}
      phx-click={if(@on_entry_click, do: @on_entry_click.(@student_grade_report_entry.id))}
    >
      <%= @student_grade_report_entry.ordinal_value.name %>
    </button>
    """
  end

  defp students_grades_grid_cell_value(
         %{student_grade_report_entry: %StudentGradeReportEntry{}} = assigns
       ) do
    has_retake_history = assigns.student_grade_report_entry.pre_retake_score != nil

    assigns =
      assigns
      |> assign(:has_retake_history, has_retake_history)

    ~H"""
    <div
      :if={@has_retake_history}
      class="flex-1 flex items-center justify-center rounded-sm text-xs bg-white opacity-70"
    >
      <%= @student_grade_report_entry.pre_retake_score %>
    </div>
    <div class="flex-[2] flex items-center justify-center rounded-sm bg-white">
      <%= @student_grade_report_entry.score %>
    </div>
    """
  end

  @doc """
  Renders a grade composition table.
  """
  attr :student_grade_report_entry, StudentGradeReportEntry, required: true
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
          <tr :for={component <- @student_grade_report_entry.composition}>
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
              <%= case @student_grade_report_entry.composition_ordinal_value do
                nil ->
                  :erlang.float_to_binary(
                    @student_grade_report_entry.composition_score,
                    decimals: 2
                  )

                ov ->
                  ov.name
              end %>
            </td>
            <td colspan="2" class="p-2 text-right">
              <%= :erlang.float_to_binary(
                @student_grade_report_entry.composition_normalized_value,
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
