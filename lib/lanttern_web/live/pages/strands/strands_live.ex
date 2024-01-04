defmodule LantternWeb.StrandsLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_strands(socket)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # event handlers

  @impl true
  def handle_event("load-more", _params, socket) do
    {:noreply, load_strands(socket)}
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, stream_insert(socket, :strands, strand)}
  end

  # helpers

  defp load_strands(socket) do
    {strands, meta} =
      LearningContext.list_strands(
        preloads: [:subjects, :years],
        after: socket.assigns[:end_cursor]
      )

    strands_count = length(strands)

    socket
    |> stream(:strands, strands)
    |> assign(:strands_count, strands_count)
    |> assign(:end_cursor, meta.end_cursor)
    |> assign(:has_next_page, meta.has_next_page?)
  end
end
