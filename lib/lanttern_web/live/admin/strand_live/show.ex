defmodule LantternWeb.Admin.StrandLive.Show do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:strand, LearningContext.get_strand!(id))}
  end

  defp page_title(:show), do: "Show Strand"
  defp page_title(:edit), do: "Edit Strand"
end
