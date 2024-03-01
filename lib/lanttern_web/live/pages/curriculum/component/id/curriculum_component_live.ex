defmodule LantternWeb.CurriculumComponentLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    socket =
      socket
      |> assign(
        :curriculum_component,
        Curricula.get_curriculum_component!(id, preloads: :curriculum)
      )
      |> stream(
        :curriculum_items,
        Curricula.list_curriculum_items(components_ids: [id])
      )

    {:noreply, socket}
  end
end
