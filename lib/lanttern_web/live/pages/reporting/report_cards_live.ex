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

    {:ok, socket}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, _params)
       when live_action in [:new],
       do: redirect(socket, to: ~p"/reporting")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(_params, _url, socket) do
    report_cards = Reporting.list_report_cards(preloads: :school_cycle)
    report_cards_count = length(report_cards)

    socket =
      socket
      |> stream(:report_cards, report_cards)
      |> assign(:report_cards_count, report_cards_count)

    {:noreply, socket}
  end
end
