defmodule LantternWeb.Admin.StrandReportLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Reporting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:strand_report, Reporting.get_strand_report!(id))}
  end

  defp page_title(:show), do: "Show Strand report"
  defp page_title(:edit), do: "Edit Strand report"
end
