defmodule LantternWeb.Admin.MomentCardLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.LearningContext

  # shared components
  alias LantternWeb.LearningContext.MomentCardFormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:moment_card, LearningContext.get_moment_card!(id))}
  end

  defp page_title(:show), do: "Show Moment card"
  defp page_title(:edit), do: "Edit Moment card"
end
