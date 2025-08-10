defmodule LantternWeb.Admin.StudentReportCardLive.Show do
  use LantternWeb, :live_view

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
     |> assign(:student_report_card, Reporting.get_student_report_card!(id))}
  end

  defp page_title(:show), do: "Show Student report card"
  defp page_title(:edit), do: "Edit Student report card"
end
