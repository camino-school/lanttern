defmodule LantternWeb.MomentLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.MomentLive.OverviewComponent
  alias LantternWeb.MomentLive.AssessmentComponent
  alias LantternWeb.MomentLive.CardsComponent
  alias LantternWeb.MomentLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:assessment_point_id, nil)
      |> assign_moment(params)
      |> assign_strand()

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
  def handle_params(params, _url, socket),
    do: {:noreply, assign(socket, :params, params)}

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
