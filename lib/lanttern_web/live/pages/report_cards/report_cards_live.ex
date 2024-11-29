defmodule LantternWeb.ReportCardsLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, assign_cycle_filter: 2]

  # live components
  alias LantternWeb.Reporting.ReportCardFormComponent

  # shared components
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:years])
      |> assign_cycle_filter(only_subcycles: true)
      |> assign(:page_title, gettext("Report cards"))
      |> stream_configure(
        :cycles_and_report_cards,
        dom_id: fn
          {cycle, _report_cards} -> "cycle-#{cycle.id}"
          _ -> ""
        end
      )
      |> stream_cycles_and_report_cards()

    {:ok, socket}
  end

  defp stream_cycles_and_report_cards(socket) do
    cycles_and_report_cards =
      Reporting.list_report_cards_by_cycle(
        parent_cycle_id:
          Map.get(socket.assigns.current_user.current_profile.current_school_cycle || %{}, :id),
        cycles_ids: socket.assigns.selected_cycles_ids,
        years_ids: socket.assigns.selected_years_ids,
        preloads: :year
      )

    has_report_cards = length(cycles_and_report_cards) > 0

    socket
    |> stream(:cycles_and_report_cards, cycles_and_report_cards)
    |> assign(:has_report_cards, has_report_cards)
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
