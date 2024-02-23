defmodule LantternWeb.ReportCardsLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard

  # live components
  alias LantternWeb.Reporting.ReportCardFormComponent

  # shared components
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> maybe_redirect(params)
      |> stream_configure(
        :cycles_and_report_cards,
        dom_id: fn
          {cycle, _report_cards} -> "cycle-#{cycle.id}"
          _ -> ""
        end
      )

    {:ok, socket}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, _params)
       when live_action in [:new],
       do: redirect(socket, to: ~p"/reporting")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(_params, _url, socket) do
    cycles_and_report_cards = Reporting.list_report_cards_by_cycle()
    has_report_cards = length(cycles_and_report_cards) > 0

    socket =
      socket
      |> stream(:cycles_and_report_cards, cycles_and_report_cards)
      |> assign(:has_report_cards, has_report_cards)

    {:noreply, socket}
  end
end
