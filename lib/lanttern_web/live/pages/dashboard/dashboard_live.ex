defmodule LantternWeb.DashboardLive do
  @moduledoc """
  Dashboard live view
  """

  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # shared components
  import LantternWeb.LearningContextComponents, only: [strand_card: 1]

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Dashboard"))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      |> stream_starred_strands()

    {:noreply, socket}
  end

  defp stream_starred_strands(socket) do
    starred_strands =
      LearningContext.list_strands(
        only_starred_for_profile_id: socket.assigns.current_user.current_profile.id,
        preloads: [:subjects, :years]
      )

    has_strands = starred_strands != []

    socket
    |> stream(:starred_strands, starred_strands, reset: true)
    |> assign(:has_strands, has_strands)
  end

  # event handlers

  @impl true
  def handle_event("unstar", %{"id" => id, "dom_id" => dom_id}, socket) do
    profile_id = socket.assigns.current_user.current_profile.id

    with {:ok, _} <- LearningContext.unstar_strand(id, profile_id) do
      socket =
        socket
        |> put_flash(:info, gettext("Strand removed from your starred list"))
        |> stream_delete_by_dom_id(:starred_strands, dom_id)

      {:noreply, socket}
    end
  end
end
