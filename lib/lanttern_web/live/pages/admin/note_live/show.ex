defmodule LantternWeb.Admin.NoteLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Notes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:note, Notes.get_note!(id, preloads: [author: [:student, :staff_member]]))}
  end

  defp page_title(:show), do: "Show Note"
  defp page_title(:edit), do: "Edit Note"
end
