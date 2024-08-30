defmodule LantternWeb.Reporting.StrandReportOverviewComponent do
  use LantternWeb, :live_component

  alias Lanttern.Rubrics

  # shared components
  import LantternWeb.RubricsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <.markdown :if={@strand_report.description} text={@strand_report.description} />
        <div :if={@has_rubric} class={if @strand_report.description, do: "mt-10"}>
          <h3 class="font-display font-black text-xl"><%= gettext("Strand rubrics") %></h3>
          <.card_base :for={{dom_id, rubric} <- @streams.rubrics} id={dom_id} class="mt-6">
            <div class="p-4 text-sm">
              <p>
                <span class="font-bold"><%= rubric.curriculum_item.curriculum_component.name %></span>
                <%= rubric.curriculum_item.name %>
              </p>
              <p class="mt-2">
                <span class="font-bold"><%= gettext("Criteria:") %></span>
                <%= rubric.criteria %>
              </p>
            </div>
            <div class="border-t border-ltrn-lighter overflow-x-auto">
              <%!-- extra div with min-w-min prevent clamped right padding issue --%>
              <%!-- https://stackoverflow.com/a/26892899 --%>
              <div class="p-4 min-w-min">
                <.rubric_descriptors rubric={rubric} />
              </div>
            </div>
          </.card_base>
        </div>
        <.empty_state :if={!@strand_report.description && !@has_rubric}>
          <%= gettext("No strand report info yet.") %>
        </.empty_state>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream_strand_rubrics()

    {:ok, socket}
  end

  defp stream_strand_rubrics(socket) do
    rubrics =
      Rubrics.list_strand_rubrics(socket.assigns.strand_report.strand_id)

    socket
    |> stream(:rubrics, rubrics)
    |> assign(:has_rubric, rubrics != [])
  end
end
