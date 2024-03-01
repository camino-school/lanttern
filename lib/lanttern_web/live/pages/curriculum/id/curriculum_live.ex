defmodule LantternWeb.CurriculumLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    socket =
      socket
      |> assign(:curriculum, Curricula.get_curriculum!(id))
      |> stream(:curriculum_components, Curricula.list_curriculum_components(curricula_ids: [id]))

    {:noreply, socket}
  end
end
