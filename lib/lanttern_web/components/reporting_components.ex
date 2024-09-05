defmodule LantternWeb.ReportingComponents do
  @moduledoc """
  Shared function components related to `Reporting` context
  """

  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents

  import LantternWeb.AssessmentsComponents
  import LantternWeb.GradingComponents
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  # shared components
  alias LantternWeb.Assessments.EntryParticleComponent

  @doc """
  Renders a teacher or student comment area
  """

  attr :comment, :string, required: true
  attr :type, :string, default: "teacher", doc: "teacher | student"
  attr :class, :any, default: nil

  def comment_area(assigns) do
    {bg_class, icon_class, text_class, text} =
      case assigns.type do
        "teacher" ->
          {"bg-ltrn-teacher-lightest", "text-ltrn-teacher-accent", "text-ltrn-teacher-dark",
           gettext("Teacher comment")}

        "student" ->
          {"bg-ltrn-student-lightest", "text-ltrn-student-accent", "text-ltrn-student-dark",
           gettext("Student comment")}
      end

    assigns =
      assigns
      |> assign(:bg_class, bg_class)
      |> assign(:icon_class, icon_class)
      |> assign(:text_class, text_class)
      |> assign(:text, text)

    ~H"""
    <div class={["p-4 rounded", @bg_class, @class]}>
      <div class="flex items-center gap-2 font-bold text-sm">
        <.icon name="hero-chat-bubble-oval-left" class={["w-6 h-6", @icon_class]} />
        <span class={@text_class}><%= @text %></span>
      </div>
      <.markdown text={@comment} size="sm" class="max-w-none mt-4" />
    </div>
    """
  end

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

  def report_scale(%{scale: %{type: "ordinal"}, rubric: rubric} = assigns)
      when not is_nil(rubric) do
    %{ordinal_values: ordinal_values} = assigns.scale
    n = length(ordinal_values)

    grid_template_columns_style =
      "grid-template-columns: repeat(#{n}, minmax(200px, 1fr))"

    active_ordinal_value =
      assigns.scale.ordinal_values
      |> Enum.find(&(assigns.entry && assigns.entry.ordinal_value_id == &1.id))

    ordinal_values_and_descriptors =
      Enum.zip(ordinal_values, rubric.descriptors)

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:active_ordinal_value, active_ordinal_value)
      |> assign(:ordinal_values_and_descriptors, ordinal_values_and_descriptors)

    ~H"""
    <div class={["grid gap-1 min-w-full", @class]} id={@id} style={@grid_template_columns_style}>
      <%= for {ordinal_value, descriptor} <- @ordinal_values_and_descriptors do %>
        <% is_active = @entry && @entry.ordinal_value_id == ordinal_value.id %>
        <div
          class="p-2 border border-ltrn-lighter rounded font-mono bg-ltrn-lightest"
          {if is_active, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
        >
          <div
            class="p-1 rounded-sm text-xs text-center text-ltrn-subtle bg-ltrn-lighter shadow-lg"
            {if is_active, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
          >
            <%= ordinal_value.name %>
          </div>
          <.markdown
            text={descriptor.descriptor}
            size="sm"
            class="mt-2 text-[0.75rem]"
            {if is_active, do: apply_text_style_from_ordinal_value(ordinal_value), else: %{}}
          />
        </div>
      <% end %>
    </div>
    """
  end

  def report_scale(%{scale: %{type: "ordinal"}} = assigns) do
    %{ordinal_values: ordinal_values} = assigns.scale
    n = length(ordinal_values)

    grid_template_columns_style =
      if assigns.rubric,
        do: "grid-template-columns: repeat(#{n}, minmax(200px, 1fr))",
        else: "grid-template-columns: repeat(#{n}, minmax(min-content, 1fr))"

    grid_column_span_style = "grid-column: span #{n} / span #{n}"

    active_ordinal_value =
      assigns.scale.ordinal_values
      |> Enum.find(&(assigns.entry && assigns.entry.ordinal_value_id == &1.id))

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_span_style, grid_column_span_style)
      |> assign(:active_ordinal_value, active_ordinal_value)

    ~H"""
    <div class={["grid gap-1 min-w-full", @class]} id={@id} style={@grid_template_columns_style}>
      <div class="grid grid-cols-subgrid" style={@grid_column_span_style}>
        <div
          :for={ordinal_value <- @scale.ordinal_values}
          class="p-2 rounded font-mono text-xs text-center text-ltrn-subtle whitespace-nowrap bg-ltrn-lighter"
          {if @entry && @entry.ordinal_value_id == ordinal_value.id, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
        >
          <%= ordinal_value.name %>
        </div>
      </div>
      <div :if={@rubric} class="grid grid-cols-subgrid" style={@grid_column_span_style}>
        <.markdown
          :for={descriptor <- @rubric.descriptors}
          class="p-4 rounded bg-ltrn-lighter"
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
    <div id={@id} class={["min-w-full", @class]}>
      <.report_scale_numeric_bar score={@entry && @entry.score} scale={@scale} />
    </div>
    """
  end

  attr :scale, Scale, required: true
  attr :score, :float, default: nil
  attr :is_student, :boolean, default: false

  defp report_scale_numeric_bar(assigns) do
    ~H"""
    <div
      class="relative flex items-center justify-between rounded w-full h-6 px-2 font-mono text-xs text-ltrn-subtle bg-ltrn-lighter"
      {apply_gradient_from_scale(@scale)}
    >
      <div style={if @scale.start_text_color, do: "color: #{@scale.start_text_color}"}>
        <%= @scale.start %>
      </div>
      <div
        :if={@score}
        class="absolute z-10 flex-1 flex items-center h-full"
        style={"left: calc(#{(@score - @scale.start) * 100 / (@scale.stop - @scale.start)}% - #{((@score - @scale.start) / (@scale.stop - @scale.start)) * 48}px)"}
      >
        <div class={[
          "absolute flex items-center justify-center w-12 h-8 rounded text-sm shadow-lg",
          if(@is_student,
            do: "text-ltrn-student-dark bg-ltrn-student-lighter",
            else: "text-ltrn-dark bg-white"
          )
        ]}>
          <%= @score %>
        </div>
      </div>
      <div
        class="text-right"
        style={if @scale.stop_text_color, do: "color: #{@scale.stop_text_color}"}
      >
        <%= @scale.stop %>
      </div>
    </div>
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
        <div class="flex items-center justify-center w-10 h-10 rounded-full mb-6 text-ltrn-diff-lightest bg-ltrn-diff-accent">
          <.icon name="hero-document-text" />
        </div>
        <.markdown text={@footnote} size="sm" />
      </.responsive_container>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :assessment_point, AssessmentPoint, required: true
  attr :entry, :any, required: true

  def moment_assessment_point_entry(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <div class="flex items-center gap-2">
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
        <p class="flex-1 text-sm"><%= @assessment_point.name %></p>
        <.assessment_point_entry_badge entry={@entry} class="shrink-0" />
      </div>
      <.comment_area :if={@entry && @entry.report_note} comment={@entry.report_note} class="mt-2" />
    </div>
    """
  end

  @doc """
  Renders a student moments entries grid for a given report card.
  """

  attr :students_stream, :any, required: true
  attr :has_students, :boolean, required: true

  attr :strands, :list,
    required: true,
    doc: "requires `assessment_points_count` field to be calculated"

  attr :students_entries_map, :map, required: true
  attr :class, :any, default: nil

  def students_moments_entries_grid(assigns) do
    assessment_points_count =
      assigns.strands
      |> Enum.reduce(0, fn strand, count -> count + strand.assessment_points_count end)

    grid_template_columns_style =
      case assessment_points_count do
        n when n > 0 ->
          "grid-template-columns: 200px repeat(#{n}, 16px)"

        _ ->
          "grid-template-columns: 200px minmax(10px, 1fr)"
      end

    grid_column_style =
      case assessment_points_count do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)

    ~H"""
    <div class={[
      "relative w-full max-h-[calc(100vh-4rem)] rounded bg-white shadow-xl overflow-x-auto",
      @class
    ]}>
      <div class="relative grid gap-1 w-max min-w-full" style={@grid_template_columns_style}>
        <div
          class="sticky top-0 z-20 grid grid-cols-subgrid py-1 pr-1 bg-white"
          style={@grid_column_style}
        >
          <div class="sticky left-0 bg-white"></div>
          <%= if @strands != [] do %>
            <a
              :for={strand <- @strands}
              id={"moments-entries-grid-strand-#{strand.id}"}
              href={"/strands/#{strand.id}?tab=assessment"}
              target="_blank"
              class="w-full p-1 rounded-sm border border-ltrn-lighter text-center truncate bg-white hover:bg-ltrn-lighter"
              style={"grid-column: span #{strand.assessment_points_count} / span #{strand.assessment_points_count}"}
              title={"#{if strand.type, do: "#{strand.type} | "}#{strand.name}"}
            >
              <span class="font-display font-black text-sm">
                <%= if strand.type, do: "#{strand.type} | " %>
                <%= strand.name %>
              </span>
            </a>
          <% else %>
            <div class="w-full p-2 rounded text-ltrn-subtle text-center bg-ltrn-lightest">
              <%= gettext("No strands with moments assessment linked to this report card") %>
            </div>
          <% end %>
        </div>
        <%= if @has_students do %>
          <div
            :for={{dom_id, student} <- @students_stream}
            id={dom_id}
            class="group grid grid-cols-subgrid items-center pr-1 hover:bg-ltrn-mesh-cyan"
            style={@grid_column_style}
          >
            <div
              class="sticky left-0 z-10 p-2 text-xs truncate bg-white group-hover:bg-ltrn-mesh-cyan"
              title={student.name}
            >
              <%= student.name %>
            </div>
            <%= if @strands != [] do %>
              <%= for strand <- @strands do %>
                <%= for {moment_id, assessment_point_id, entry} <- @students_entries_map[student.id][strand.id] do %>
                  <a
                    href={"/strands/moment/#{moment_id}?tab=assessment"}
                    target="_blank"
                    class="block w-min rounded-sm outline-ltrn-primary text-center hover:outline"
                  >
                    <.live_component
                      module={EntryParticleComponent}
                      id={"student-#{student.id}-ap-#{assessment_point_id}"}
                      entry={entry}
                      size="sm"
                    />
                  </a>
                <% end %>
              <% end %>
            <% else %>
              <div class="h-full rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% else %>
          <div class="grid grid-cols-subgrid" style={@grid_column_style}>
            <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
              <%= gettext("No students linked to this grades report") %>
            </div>
            <%= if @strands != [] do %>
              TBD
            <% else %>
              <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
