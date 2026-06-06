defmodule LantternWeb.ReportCardLive.GradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <%= if @grades_report do %>
          <.markdown
            :if={@report_card.grading_info || @grades_report.info}
            text={@report_card.grading_info || @grades_report.info}
            class="mb-10"
          />
        <% else %>
          <.markdown
            :if={@report_card.grading_info}
            text={@report_card.grading_info}
            class="mb-10"
          />
          <.card_base class="p-4">
            <.empty_state>
              {gettext("No grades report linked to this report card.")}
            </.empty_state>
          </.card_base>
        <% end %>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:grades_report, fn %{report_card: report_card} ->
        case report_card.grades_report_id do
          nil -> nil
          id -> GradesReports.get_grades_report(id, load_grid: true)
        end
      end)

    {:ok, socket}
  end
end
