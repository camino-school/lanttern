defmodule LantternWeb.StrandLive.List do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  # live components
  alias LantternWeb.StrandLive.StrandFormComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    strands = LearningContext.list_strands(preloads: [:subjects, :years])

    {:ok,
     socket
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
