defmodule LantternWeb.Admin.StrandLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(
       socket,
       :strands,
       LearningContext.list_strands(
         preloads: [:subjects, :years, curriculum_items: [curriculum_item: :curriculum_component]]
       )
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Strand")
    |> assign(
      :strand,
      LearningContext.get_strand!(id,
        preloads: [:subjects, :years, curriculum_items: [curriculum_item: :curriculum_component]]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Strand")
    |> assign(:strand, %Strand{curriculum_items: [], subjects: [], years: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Strands")
    |> assign(:strand, nil)
  end

  @impl true
  def handle_info({LantternWeb.StrandLive.StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, stream_insert(socket, :strands, strand)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    strand = LearningContext.get_strand!(id)
    {:ok, _} = LearningContext.delete_strand(strand)

    {:noreply, stream_delete(socket, :strands, strand)}
  end
end
