defmodule LantternWeb.AssessmentPointsFilterViewLive.Show do
  use LantternWeb, :live_view

  alias Lanttern.Explorer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assessment_points_filter_view, Explorer.get_assessment_points_filter_view!(id))}
  end

  defp page_title(:show), do: "Show Assessment points filter view"
  defp page_title(:edit), do: "Edit Assessment points filter view"
end
