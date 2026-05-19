defmodule LantternWeb.MarkingLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias __MODULE__.GoalsAssessmentComponent

  # shared components
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)
      |> assign_strand_classes_filter()

    {:ok, socket}
  end

  defp assign_strand(socket, %{"id" => id}) do
    LearningContext.get_strand(id,
      show_starred_for_profile_id: socket.assigns.current_user.current_profile_id,
      preloads: [:subjects, :years]
    )
    |> case do
      strand when is_nil(strand) ->
        socket
        |> put_flash(:error, gettext("Couldn't find strand"))
        |> redirect(to: ~p"/strands")

      strand ->
        socket
        |> assign(:strand, strand)
        |> assign(:page_title, strand.name)
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = assign(socket, :params, params)
    {:noreply, socket}
  end
end
