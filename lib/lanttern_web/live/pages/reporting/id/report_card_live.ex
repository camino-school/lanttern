defmodule LantternWeb.ReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StrandReport

  # live components
  alias LantternWeb.Reporting.ReportCardFormComponent
  alias LantternWeb.Reporting.StrandReportFormComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> maybe_redirect(params)

    {:ok, socket}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, params)
       when live_action in [:edit, :edit_strand_report],
       do: redirect(socket, to: ~p"/reporting/#{params["id"]}")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    report_card = Reporting.get_report_card!(id, preloads: [strand_reports: :strand])

    socket =
      socket
      |> assign(:report_card, report_card)

    {:noreply, socket}
  end

  # event handlers

  @impl true
  def handle_event("delete_report_card", _params, socket) do
    case Reporting.delete_report_card(socket.assigns.report_card) do
      {:ok, _report_card} ->
        socket =
          socket
          |> put_flash(:info, gettext("Report card deleted"))
          |> push_navigate(to: ~p"/reporting")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting report card"))

        {:noreply, socket}
    end
  end

  def handle_event("add_strand", _params, socket) do
    report_card = socket.assigns.report_card

    strand_report = %StrandReport{
      report_card_id: report_card.id
    }

    socket =
      socket
      |> assign(:strand_report, strand_report)
      |> push_patch(to: ~p"/reporting/#{report_card}/edit_strand_report")

    {:noreply, socket}
  end
end
