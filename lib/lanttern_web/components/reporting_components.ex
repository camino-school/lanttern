defmodule LantternWeb.ReportingComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Reporting.GradesReport
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  @doc """
  Renders a report card card (yes, card card, 2x).
  """
  attr :report_card, ReportCard, required: true
  attr :cycle, Cycle, default: nil
  attr :year, Year, default: nil
  attr :navigate, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_card_card(assigns) do
    ~H"""
    <div
      class={[
        "rounded shadow-xl bg-white overflow-hidden",
        @class
      ]}
      id={@id}
    >
      <div
        class="relative w-full h-40 bg-center bg-cover"
        style={"background-image: url(#{"/images/cover-placeholder-sm.jpg"}?width=400&height=200)"}
      />
      <div class="flex flex-col gap-6 p-6">
        <h5 class="font-display font-black text-3xl line-clamp-3">
          <%= if @navigate do %>
            <.link navigate={@navigate} class="underline hover:text-ltrn-subtle">
              <%= @report_card.name %>
            </.link>
          <% else %>
            <%= @report_card.name %>
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
    active_ordinal_value =
      assigns.scale.ordinal_values
      |> Enum.find(&(assigns.entry && assigns.entry.ordinal_value_id == &1.id))

    assigns = assign(assigns, :active_ordinal_value, active_ordinal_value)

    ~H"""
    <div class={@class} id={@id}>
      <div class="flex items-stretch gap-1">
        <div
          :for={ordinal_value <- @scale.ordinal_values}
          class={[
            "flex-1 shrink-0 p-2 font-mono text-sm text-center text-ltrn-subtle bg-ltrn-lighter",
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
      <div :if={@rubric} class="flex items-stretch gap-1 mt-1">
        <.markdown
          :for={descriptor <- @rubric.descriptors}
          class="flex-1 shrink-0 p-4 first:rounded-bl last:rounded-br bg-ltrn-lighter"
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
    <div :if={@footnote} class={["p-10 bg-ltrn-diff-light", @class]}>
      <div class="container mx-auto lg:max-w-5xl">
        <div class="flex items-center justify-center w-10 h-10 rounded-full mb-6 text-ltrn-diff-light bg-ltrn-diff-highlight">
          <.icon name="hero-document-text" />
        </div>
        <.markdown text={@footnote} size="sm" />
      </div>
    </div>
    """
  end

  @doc """
  Renders a grades report grid.

  Expects `[:school_cycle, grades_report_cycles: :school_cycle, grades_report_subjects: :subject]` preloads.
  """

  attr :grades_report, GradesReport, required: true
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
          "grid-template-columns: 160px repeat(#{n + 1}, minmax(0, 1fr))"

        _ ->
          "grid-template-columns: 160px minmax(0, 1fr)"
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
          <div class="p-4 rounded bg-white shadow-lg">
            <%= grades_report_subject.subject.name %>
          </div>
          <%= if @has_cycles do %>
            <.grades_report_grid_cell
              :for={grades_report_cycle <- @grades_report.grades_report_cycles}
              on_click={
                @report_card_cycle_id == grades_report_cycle.school_cycle_id &&
                  @on_composition_click
              }
              subject_id={grades_report_subject.subject_id}
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
    """
  end

  attr :on_click, JS
  attr :subject_id, :integer

  defp grades_report_grid_cell(%{on_click: %JS{}} = assigns) do
    ~H"""
    <.button
      type="button"
      theme="ghost"
      icon_name="hero-calculator-mini"
      phx-click={@on_click}
      phx-value-subjectid={@subject_id}
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

  def student_grades_grid(assigns) do
    %{
      students: students,
      grades_report_subjects: grades_report_subjects
    } = assigns

    grid_template_columns_style =
      case length(grades_report_subjects) do
        n when n > 0 ->
          "grid-template-columns: 160px repeat(#{n}, minmax(0, 1fr))"

        _ ->
          "grid-template-columns: 160px minmax(0, 1fr)"
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
      <.button type="button" theme="ghost" icon_name="hero-cog-6-tooth-mini" phx-click={%JS{}}>
        <%= gettext("Calculate") %>
      </.button>
      <%= if @has_subjects do %>
        <div
          :for={grades_report_subject <- @grades_report_subjects}
          id={"students-grades-grid-header-subject-#{grades_report_subject.id}"}
          class="p-4 rounded text-center bg-white shadow-lg"
        >
          <%= grades_report_subject.subject.name %>
        </div>
      <% else %>
        <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
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
          <div class="p-4 rounded bg-white shadow-lg">
            <%= student.name %>
          </div>
          <%= if @has_subjects do %>
            <.student_grades_grid_cell
              :for={grades_report_subject <- @grades_report_subjects}
              student_grade_report_entry={@students_grades_map[student.id][grades_report_subject.id]}
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

  defp student_grades_grid_cell(assigns) do
    ~H"""
    <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
    """
  end
end
