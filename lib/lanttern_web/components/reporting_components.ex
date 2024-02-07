defmodule LantternWeb.ReportingComponents do
  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents

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
end
