defmodule LantternWeb.ReportingComponents do
  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.GradingComponents

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard

  @doc """
  Renders a report card card (yes, card card, 2x).
  """
  attr :report_card, ReportCard, required: true, doc: "Requires school_cycle preload"
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
        <div class="flex flex-wrap gap-2">
          <.badge>
            <%= gettext("Cycle") %>: <%= @report_card.school_cycle.name %>
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
  attr :entry, AssessmentPointEntry, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def report_scale(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div
      class={[
        "flex items-center gap-1",
        @class
      ]}
      id={@id}
    >
      <div
        :for={ordinal_value <- @scale.ordinal_values}
        class="flex-1 shrink-0 p-2 first:rounded-l last:rounded-r text-sm text-center text-ltrn-subtle bg-ltrn-lighter"
        {if @entry && @entry.ordinal_value_id == ordinal_value.id, do: apply_style_from_ordinal_value(ordinal_value), else: %{}}
      >
        <%= ordinal_value.name %>
      </div>
    </div>
    """
  end

  def report_scale(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "relative flex items-center justify-between rounded-full h-10 px-8 bg-ltrn-lighter",
        @class
      ]}
      {apply_gradient_from_scale(@scale)}
    >
      <div
        class="absolute left-4 text-sm text-ltrn-subtle"
        style={if @scale.start_text_color, do: "color: #{@scale.start_text_color}"}
      >
        <%= @scale.start %>
      </div>
      <div :if={@entry && @entry.score} class="relative z-10 flex-1 flex items-center h-full">
        <div
          class="absolute flex items-center justify-center w-16 h-16 rounded-full -ml-8 font-display font-black text-lg bg-white shadow-lg"
          style={"left: #{(@entry.score - @scale.start) * 100 / (@scale.stop - @scale.start)}%"}
        >
          <%= @entry.score %>
        </div>
      </div>
      <div
        class="absolute right-4 text-sm text-right text-ltrn-subtle"
        style={if @scale.stop_text_color, do: "color: #{@scale.stop_text_color}"}
      >
        <%= @scale.stop %>
      </div>
    </div>
    """
  end
end
