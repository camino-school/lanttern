defmodule LantternWeb.MarkingLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias __MODULE__.GoalsAssessmentComponent
  alias __MODULE__.MomentAssessmentComponent

  # shared components
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)
      |> assign_moments()
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

  defp assign_moments(socket) do
    moments = LearningContext.list_moments(strands_ids: [socket.assigns.strand.id])
    assign(socket, :moments, moments)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_moment(params)
      |> assign_select_classes_overlay_navigate()

    {:noreply, socket}
  end

  defp assign_moment(socket, %{"moment_id" => moment_id}) do
    case LearningContext.get_moment(moment_id) do
      %{strand_id: strand_id} = moment when strand_id == socket.assigns.strand.id ->
        assign(socket, :moment, moment)

      _ ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment/marking")
    end
  end

  defp assign_moment(socket, _params), do: assign(socket, :moment, nil)

  defp assign_select_classes_overlay_navigate(socket) do
    navigate =
      case socket.assigns.live_action do
        :moment_assessment ->
          ~p"/strands/#{socket.assigns.strand.id}/assessment/marking/moment/#{socket.assigns.moment.id}"

        :goals_assessment ->
          ~p"/strands/#{socket.assigns.strand.id}/assessment/marking"
      end

    assign(socket, :select_classes_overlay_navigate, navigate)
  end
end
