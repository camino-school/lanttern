defmodule LantternWeb.Admin.CycleLive.Show do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:cycle, Schools.get_cycle!(id, preloads: :parent_cycle))}
  end

  defp page_title(:show), do: "Show Cycle"
  defp page_title(:edit), do: "Edit Cycle"
end
