defmodule LantternWeb.CurriculumLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    curriculum = Curricula.get_curriculum!(id)

    socket =
      socket
      |> assign(:curriculum, curriculum)
      |> stream(:curriculum_components, Curricula.list_curriculum_components(curricula_ids: [id]))
      |> assign(:page_title, curriculum.name)

    {:noreply, socket}
  end
end
