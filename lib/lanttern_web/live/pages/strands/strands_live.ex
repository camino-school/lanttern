defmodule LantternWeb.StrandsLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    strands = LearningContext.list_strands(preloads: [:subjects, :years])
    strands_count = length(strands)

    {:ok,
     socket
     |> assign(:strands_count, strands_count)
     |> stream(:strands, strands)}
  end

  # event handlers

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, stream_insert(socket, :strands, strand)}
  end
end
