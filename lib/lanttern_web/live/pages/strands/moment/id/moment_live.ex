defmodule LantternWeb.MomentLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.MomentLive.DetailsComponent
  alias LantternWeb.MomentLive.AssessmentComponent
  alias LantternWeb.MomentLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent

  @tabs %{
    "details" => :details,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :moment, nil), layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(%{"tab" => "assessment"} = params, _url, socket) do
    # when in assessment tab, sync classes_ids filter with profile
    {:noreply,
     handle_params_and_profile_filters_sync(
       socket,
       params,
       [:classes_ids],
       &handle_assigns/2,
       fn params -> ~p"/strands/moment/#{params["id"]}/?#{Map.drop(params, ["id"])}" end
     )}
  end

  def handle_params(params, _url, socket),
    do: {:noreply, handle_assigns(socket, params)}

  defp handle_assigns(socket, params) do
    socket
    |> assign(:params, params)
    |> assign(:assessment_point_id, nil)
    |> set_current_tab(params, socket.assigns.live_action)
    |> apply_action(socket.assigns.live_action, params)
  end

  defp set_current_tab(socket, _params, :new_assessment_point),
    do: assign(socket, :current_tab, @tabs["assessment"])

  defp set_current_tab(
         socket,
         %{"assessment_point_id" => assessment_point_id},
         :edit_assessment_point
       ) do
    socket
    |> assign(:current_tab, @tabs["assessment"])
    |> assign(:assessment_point_id, assessment_point_id)
  end

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :details))

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :details)

  defp apply_action(%{assigns: %{moment: nil}} = socket, _live_action, %{"id" => id}) do
    # pattern match assigned moment to prevent unnecessary get_moment calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_moment(id,
           preloads: [:strand, :subjects]
         ) do
      moment when is_nil(moment) ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket

  # event handlers

  @impl true
  def handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment deleted"))
         |> push_navigate(to: ~p"/strands/#{socket.assigns.moment.strand}?tab=moments")}

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
