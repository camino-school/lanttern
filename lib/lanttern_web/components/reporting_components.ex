defmodule LantternWeb.ReportingComponents do
  use Phoenix.Component
  alias Lanttern.GradesReports.StudentGradeReportEntry
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents
  import LantternWeb.SupabaseHelpers, only: [object_url_to_render_url: 2]

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  @doc """
  Renders a report card card (yes, card card, 2x).
  """
  attr :report_card, ReportCard, required: true
  attr :cycle, Cycle, default: nil
  attr :year, Year, default: nil
  attr :is_wip, :boolean, default: false
  attr :navigate, :string, default: nil
  attr :hide_description, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_card_card(assigns) do
    cover_image_url =
      assigns.report_card.cover_image_url
      |> object_url_to_render_url(width: 400, height: 200)

    assigns = assign(assigns, :cover_image_url, cover_image_url)

    ~H"""
    <div
      class={[
        "flex flex-col rounded shadow-xl bg-white overflow-hidden",
        @class
      ]}
      id={@id}
    >
      <div
        class="relative w-full h-40 bg-center bg-cover"
        style={"background-image: url('#{@cover_image_url || "/images/cover-placeholder-sm.jpg"}')"}
      />
      <div class="flex-1 flex flex-col gap-6 p-6">
        <h5 class={[
          "font-display font-black text-2xl line-clamp-3",
          "md:text-3xl"
        ]}>
          <%= if @navigate && not @is_wip do %>
            <.link navigate={@navigate} class="underline hover:text-ltrn-subtle">
              <%= @report_card.name %>
            </.link>
          <% else %>
            <span :if={@is_wip} class="text-ltrn-subtle"><%= @report_card.name %></span>
            <%= if !@is_wip, do: @report_card.name %>
          <% end %>
        </h5>
        <div :if={@cycle || @report_card.year} class="flex flex-wrap gap-2">
          <.badge :if={@cycle}>
            <%= gettext("Cycle") %>: <%= @cycle.name %>
          </.badge>
          <.badge :if={@year}>
            <%= @year.name %>
          </.badge>
        </div>
        <div :if={!@hide_description && @report_card.description} class="line-clamp-3">
          <.markdown text={@report_card.description} size="sm" />
        </div>
      </div>
      <div :if={@is_wip} class="flex items-center gap-2 p-4 text-sm text-ltrn-subtle bg-ltrn-lightest">
        <.icon name="hero-lock-closed-mini" />
        <%= gettext("Under development") %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a scale.
  """
  attr :scale, Scale, required: true, doc: "Requires `ordinal_values` preload"
  attr :rubric, Rubric, default: nil, doc: "Requires `descriptors` preload"
  attr :entry, AssessmentPointEntry, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_scale(%{scale: %{type: "ordinal"}} = assigns) do
    %{ordinal_values: ordinal_values} = assigns.scale
    n = length(ordinal_values)

    grid_template_columns_style =
      cond do
        assigns.rubric -> "grid-template-columns: repeat(#{n}, minmax(200px, 1fr))"
        true -> "grid-template-columns: repeat(#{n}, minmax(min-content, 1fr))"
      end

    grid_column_style = "grid-column: span #{n} / span #{n}"

    active_ordinal_value =
      assigns.scale.ordinal_values
      |> Enum.find(&(assigns.entry && assigns.entry.ordinal_value_id == &1.id))

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:active_ordinal_value, active_ordinal_value)

    ~H"""
    <div class={["grid gap-1 min-w-full", @class]} id={@id} style={@grid_template_columns_style}>
      <div class="grid grid-cols-subgrid" style={@grid_column_style}>
        <div
          :for={ordinal_value <- @scale.ordinal_values}
          class={[
            "p-2 font-mono text-sm text-center text-ltrn-subtle bg-ltrn-lighter",
            if(@rubric,
              do: "first:rounded-tl last:rounded-tr",
              else: "first:rounded-l last:rounded-r"
            )
          ]}
          {if @entry && @entry.ordinal_value_id == ordinal_value.id, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
        >
          <%= ordinal_value.name %>
        </div>
      </div>
      <div :if={@rubric} class="grid grid-cols-subgrid" style={@grid_column_style}>
        <.markdown
          :for={descriptor <- @rubric.descriptors}
          class="p-4 first:rounded-bl last:rounded-br bg-ltrn-lighter"
          text={descriptor.descriptor}
          size="sm"
          {if @active_ordinal_value && @active_ordinal_value.id == descriptor.ordinal_value_id, do: apply_style_from_ordinal_value(@active_ordinal_value), else: %{style: "color: #94a3b8"}}
        />
      </div>
    </div>
    """
  end

  def report_scale(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "relative flex items-center justify-between rounded h-10 px-4 font-mono text-sm text-ltrn-subtle bg-ltrn-lighter",
        @class
      ]}
      {apply_gradient_from_scale(@scale)}
    >
      <div
        class="absolute left-4"
        style={if @scale.start_text_color, do: "color: #{@scale.start_text_color}"}
      >
        <%= @scale.start %>
      </div>
      <div :if={@entry && @entry.score} class="relative z-10 flex-1 flex items-center h-full">
        <div
          class="absolute flex items-center justify-center w-16 h-16 rounded-full -ml-8 font-bold text-lg text-ltrn-dark bg-white shadow-lg"
          style={"left: #{(@entry.score - @scale.start) * 100 / (@scale.stop - @scale.start)}%"}
        >
          <%= @entry.score %>
        </div>
      </div>
      <div
        class="absolute right-4 text-right"
        style={if @scale.stop_text_color, do: "color: #{@scale.stop_text_color}"}
      >
        <%= @scale.stop %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an assessment point entry preview.
  """
  attr :entry, AssessmentPointEntry,
    required: true,
    doc: "Requires `scale` and `ordinal_value` preloads"

  # attr :scale, Scale, required: true, doc: "Requires `ordinal_values` preload"
  # attr :rubric, Rubric, default: nil, doc: "Requires `descriptors` preload"
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def assessment_point_entry_preview(%{entry: %{scale: %{type: "ordinal"}}} = assigns) do
    ~H"""
    <.ordinal_value_badge ordinal_value={@entry.ordinal_value} class={@class} id={@id}>
      <%= String.slice(@entry.ordinal_value.name, 0..2) %>
    </.ordinal_value_badge>
    """
  end

  def assessment_point_entry_preview(%{entry: %{scale: %{type: "numeric"}}} = assigns) do
    ~H"""
    <.badge class={@class} id={@id}>
      <%= @entry.score %>
    </.badge>
    """
  end

  attr :footnote, :string, required: true
  attr :class, :any, default: nil

  def footnote(assigns) do
    ~H"""
    <div
      :if={@footnote}
      class={[
        "py-6 bg-ltrn-diff-lightest",
        "sm:py-10",
        @class
      ]}
    >
      <.responsive_container>
        <div class="flex items-center justify-center w-10 h-10 rounded-full mb-6 text-ltrn-diff-lightest bg-ltrn-diff-highlight">
          <.icon name="hero-document-text" />
        </div>
        <.markdown text={@footnote} size="sm" />
      </.responsive_container>
    </div>
    """
  end

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
              "p-4 rounded text-center shadow-lg",
              if(@report_card_cycle_id == grades_report_cycle.school_cycle_id,
                do: "font-bold bg-ltrn-mesh-cyan",
                else: "bg-white"
              )
            ]}
          >
            <%= grades_report_cycle.school_cycle.name %>
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
                  @report_card_cycle_id == grades_report_cycle.school_cycle_id &&
                    @on_composition_click
                }
                grades_report_subject_id={grades_report_subject.id}
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
  attr :grades_report_subject_id, :integer

  defp grades_report_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{ordinal_value: %OrdinalValue{}}} =
           assigns
       ) do
    ~H"""
    <.button
      type="button"
      phx-click={@on_student_grade_click}
      phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
      phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
      {apply_style_from_ordinal_value(@student_grade_report_entry.ordinal_value)}
    >
      <%= @student_grade_report_entry.ordinal_value.name %>
    </.button>
    """
  end

  defp grades_report_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{}} = assigns
       ) do
    ~H"""
    <.button
      type="button"
      phx-click={@on_student_grade_click}
      phx-value-gradesreportsubjectid={@student_grade_report_entry.grades_report_subject_id}
      phx-value-gradesreportcycleid={@student_grade_report_entry.grades_report_cycle_id}
      class="border border-ltrn-lighter"
    >
      <%= @student_grade_report_entry.score %>
    </.button>
    """
  end

  defp grades_report_grid_cell(%{on_composition_click: %JS{}} = assigns) do
    ~H"""
    <.button
      type="button"
      theme="ghost"
      icon_name="hero-calculator-mini"
      phx-click={@on_composition_click}
      phx-value-gradesreportsubjectid={@grades_report_subject_id}
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

    grid_template_columns_style =
      case length(grades_report_subjects) do
        n when n > 0 ->
          "grid-template-columns: 200px repeat(#{n}, minmax(0, 1fr))"

        _ ->
          "grid-template-columns: 200px minmax(0, 1fr)"
      end

    grid_column_style =
      case length(grades_report_subjects) do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:has_subjects, length(grades_report_subjects) > 0)
      |> assign(:has_students, length(students) > 0)

    ~H"""
    <div id={@id} class={["grid gap-1 text-sm", @class]} style={@grid_template_columns_style}>
      <%= if @on_calculate_cycle do %>
        <.button
          type="button"
          theme="ghost"
          icon_name="hero-arrow-path-mini"
          phx-click={@on_calculate_cycle.()}
        >
          <%= gettext("Calculate all") %>
        </.button>
      <% else %>
        <div></div>
      <% end %>
      <%= if @has_subjects do %>
        <div
          :for={grades_report_subject <- @grades_report_subjects}
          id={"students-grades-grid-header-subject-#{grades_report_subject.id}"}
          class="flex items-center justify-center gap-2 px-1 py-4 rounded text-center bg-white shadow-lg"
        >
          <span class="flex-1 truncate">
            <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", grades_report_subject.subject.name) %>
          </span>
          <.icon_button
            :if={@on_calculate_subject}
            name="hero-arrow-path-mini"
            theme="white"
            rounded
            size="sm"
            sr_text={gettext("Calculate subject grades")}
            phx-click={@on_calculate_subject.(grades_report_subject.id)}
          />
        </div>
      <% else %>
        <div class="p-2 rounded text-ltrn-subtle bg-ltrn-lightest">
          <%= gettext("No cycles linked to this grades report") %>
        </div>
      <% end %>
      <%= if @has_students do %>
        <div
          :for={student <- @students}
          id={"students-grades-grid-student-#{student.id}"}
          class="grid grid-cols-subgrid"
          style={@grid_column_style}
        >
          <div class="flex items-center gap-2 px-2 py-4 rounded bg-white shadow-lg">
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
            />
          </div>
          <%= if @has_subjects do %>
            <.students_grades_grid_cell
              :for={grades_report_subject <- @grades_report_subjects}
              student_grade_report_entry={@students_grades_map[student.id][grades_report_subject.id]}
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
    """
  end

  attr :student_grade_report_entry, StudentGradeReportEntry, default: nil
  attr :student_id, :integer, default: nil
  attr :grades_report_subject_id, :integer, default: nil
  attr :on_calculate_cell, :any, required: true
  attr :on_entry_click, :any, required: true

  defp students_grades_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{ordinal_value: %OrdinalValue{}}} =
           assigns
       ) do
    bg_class =
      if assigns.student_grade_report_entry.ordinal_value_id ==
           assigns.student_grade_report_entry.composition_ordinal_value_id,
         do: "border-ltrn-lighter bg-ltrn-lightest",
         else: "border-ltrn-secondary bg-ltrn-mesh-rose"

    assigns =
      assigns
      |> assign(:bg_class, bg_class)

    ~H"""
    <div class={[
      "relative flex items-center justify-center gap-2 p-1 border rounded",
      @bg_class
    ]}>
      <button
        class="flex-1 self-stretch flex items-center justify-center rounded-sm"
        {apply_style_from_ordinal_value(@student_grade_report_entry.ordinal_value)}
        phx-click={if(@on_entry_click, do: @on_entry_click.(@student_grade_report_entry.id))}
      >
        <%= @student_grade_report_entry.ordinal_value.name %>
      </button>
      <.icon_button
        :if={@on_calculate_cell}
        name="hero-arrow-path-mini"
        theme="white"
        rounded
        size="sm"
        sr_text={gettext("Recalculate grade")}
        phx-click={@on_calculate_cell.(@student_id, @grades_report_subject_id)}
      />
      <div
        :if={@student_grade_report_entry.comment}
        class="absolute top-1 right-1 w-2 h-2 rounded-full bg-ltrn-dark"
      >
        <span class="sr-only"><%= gettext("Entry with comments") %></span>
      </div>
    </div>
    """
  end

  defp students_grades_grid_cell(
         %{student_grade_report_entry: %StudentGradeReportEntry{}} = assigns
       ) do
    bg_class =
      if assigns.student_grade_report_entry.score ==
           assigns.student_grade_report_entry.composition_score,
         do: "bg-ltrn-lightest",
         else: "bg-ltrn-mesh-yellow"

    assigns =
      assigns
      |> assign(:bg_class, bg_class)

    ~H"""
    <div class={[
      "flex items-center justify-center gap-2 rounded border border-ltrn-lighter",
      @bg_class
    ]}>
      <%= @student_grade_report_entry.score %>
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
end
