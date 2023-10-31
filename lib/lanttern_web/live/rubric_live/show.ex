defmodule LantternWeb.RubricLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Rubrics

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:rubric, Rubrics.get_rubric!(id, preloads: [:scale, :descriptors]))}
  end

  defp page_title(:show), do: "Show Rubric"
  defp page_title(:edit), do: "Edit Rubric"
end
