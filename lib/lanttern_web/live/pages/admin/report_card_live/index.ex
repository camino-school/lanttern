defmodule LantternWeb.Admin.ReportCardLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :report_cards, Reporting.list_report_cards())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Report card")
    |> assign(:report_card, Reporting.get_report_card!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Report card")
    |> assign(:report_card, %ReportCard{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Report cards")
    |> assign(:report_card, nil)
  end

  @impl true
  def handle_info({LantternWeb.Reporting.ReportCardFormComponent, {:saved, report_card}}, socket) do
    {:noreply, stream_insert(socket, :report_cards, report_card)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    report_card = Reporting.get_report_card!(id)
    {:ok, _} = Reporting.delete_report_card(report_card)

    {:noreply, stream_delete(socket, :report_cards, report_card)}
  end
end
