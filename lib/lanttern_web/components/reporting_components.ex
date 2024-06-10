defmodule LantternWeb.ReportingComponents do
  @moduledoc """
  Shared function components related to `Reporting` context
  """

  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  alias Lanttern.Assessments.AssessmentPointEntry
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
          class="p-2 rounded font-mono text-sm text-center text-ltrn-subtle bg-ltrn-lighter"
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
      <div
        :if={@entry.student_ordinal_value_id}
        class="grid grid-cols-subgrid border-t-2 pt-1 border-ltrn-student-accent"
        style={@grid_column_span_style}
      >
        <div
          :for={ordinal_value <- @scale.ordinal_values}
          class="p-2 rounded font-mono text-sm text-center text-ltrn-subtle bg-ltrn-lighter"
          {if @entry && @entry.student_ordinal_value_id == ordinal_value.id, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
        >
          <%= ordinal_value.name %>
        </div>
        <div class="border-t-2 border-ltrn-student-accent mt-1" style={@grid_column_span_style}>
          <div class="inline-block p-2 rounded-bl rounded-br text-xs text-ltrn-sudent-dark bg-ltrn-student-accent">
            <%= gettext("Student self-assessment") %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def report_scale(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div id={@id} class={["min-w-full", @class]}>
      <.report_scale_numeric_bar score={@entry && @entry.score} scale={@scale} />
      <div
        :if={@entry && @entry.student_score}
        class="mt-1 py-1 border-y-2 border-ltrn-student-accent"
      >
        <.report_scale_numeric_bar score={@entry.student_score} scale={@scale} is_student />
      </div>
      <div
        :if={@entry && @entry.student_score}
        class="inline-block p-2 rounded-bl rounded-br text-xs text-ltrn-sudent-dark bg-ltrn-student-accent"
      >
        <%= gettext("Student self-assessment") %>
      </div>
    </div>
    """
  end

  attr :scale, Scale, required: true
  attr :score, :float, default: nil
  attr :is_student, :boolean, default: false

  defp report_scale_numeric_bar(assigns) do
    ~H"""
    <div
      class="relative flex items-center justify-between rounded w-full h-10 px-4 font-mono text-sm text-ltrn-subtle bg-ltrn-lighter"
      {apply_gradient_from_scale(@scale)}
    >
      <div
        class="absolute left-4"
        style={if @scale.start_text_color, do: "color: #{@scale.start_text_color}"}
      >
        <%= @scale.start %>
      </div>
      <div :if={@score} class="relative z-10 flex-1 flex items-center h-full">
        <div
          class={[
            "absolute flex items-center justify-center w-16 h-16 rounded-full -ml-8 font-bold text-lg shadow-lg",
            if(@is_student,
              do: "text-ltrn-student-dark bg-ltrn-student-lighter",
              else: "text-ltrn-dark bg-white"
            )
          ]}
          style={"left: #{(@score - @scale.start) * 100 / (@scale.stop - @scale.start)}%"}
        >
          <%= @score %>
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
        <div class="flex items-center justify-center w-10 h-10 rounded-full mb-6 text-ltrn-diff-lightest bg-ltrn-diff-accent">
          <.icon name="hero-document-text" />
        </div>
        <.markdown text={@footnote} size="sm" />
      </.responsive_container>
    </div>
    """
  end
end
