defmodule LantternWeb.ReportingComponents do
  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents

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
end
