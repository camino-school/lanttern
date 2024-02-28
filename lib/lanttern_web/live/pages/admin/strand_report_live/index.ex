defmodule LantternWeb.Admin.StrandReportLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StrandReport
  alias LantternWeb.Reporting.StrandReportFormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :strand_reports, Reporting.list_strands_reports())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Strand report")
    |> assign(:strand_report, Reporting.get_strand_report!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Strand report")
    |> assign(:strand_report, %StrandReport{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Strand reports")
    |> assign(:strand_report, nil)
  end

  @impl true
  def handle_info({StrandReportFormComponent, {:saved, strand_report}}, socket) do
    {:noreply, stream_insert(socket, :strand_reports, strand_report)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    strand_report = Reporting.get_strand_report!(id)
    {:ok, _} = Reporting.delete_strand_report(strand_report)

    {:noreply, stream_delete(socket, :strand_reports, strand_report)}
  end
end
