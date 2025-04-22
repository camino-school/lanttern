defmodule LantternWeb.MomentLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.MomentLive.AssessmentComponent
  alias LantternWeb.MomentLive.CardsComponent
  alias LantternWeb.MomentLive.NotesComponent
  alias LantternWeb.MomentLive.OverviewComponent

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  @live_action_select_classes_overlay_title %{
    assessment: gettext("Select classes to view assessments info")
  }

  @live_action_select_classes_overlay_navigate_path %{
    assessment: "assessment"
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:assessment_point_id, nil)
      |> assign_moment(params)
      |> assign_strand()
      |> assign_strand_classes_filter()

    {:ok, socket}
  end

  defp assign_moment(socket, %{"id" => id}) do
    case LearningContext.get_moment(id, preloads: :subjects) do
      moment when is_nil(moment) ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
    end
  end

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.moment.strand_id,
        preloads: [:subjects, :years]
      )

    socket
    |> assign(:strand, strand)
    |> assign(:page_title, "#{socket.assigns.moment.name} • #{strand.name}")
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_select_classes_overlay_title()
      |> assign_select_classes_overlay_navigate()

    {:noreply, socket}
  end

  defp assign_select_classes_overlay_title(socket) do
    title =
      Map.get(
        @live_action_select_classes_overlay_title,
        socket.assigns.live_action
      )

    assign(socket, :select_classes_overlay_title, title)
  end

  defp assign_select_classes_overlay_navigate(socket) do
    path_final =
      Map.get(
        @live_action_select_classes_overlay_navigate_path,
        socket.assigns.live_action
      )

    navigate = "/strands/moment/#{socket.assigns.moment.id}/#{path_final}"

    assign(socket, :select_classes_overlay_navigate, navigate)
  end

  # event handlers

  @impl true
  def handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment deleted"))
         |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/moments")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("Moment has linked assessments. Deleting it would cause some data loss.")
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({MomentFormComponent, {:saved, moment}}, socket) do
    {:noreply, assign(socket, :moment, moment)}
  end
end
