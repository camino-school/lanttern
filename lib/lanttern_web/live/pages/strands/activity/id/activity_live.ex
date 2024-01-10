defmodule LantternWeb.ActivityLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.ActivityLive.DetailsComponent
  alias LantternWeb.ActivityLive.AssessmentComponent
  alias LantternWeb.ActivityLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.ActivityFormComponent

  @tabs %{
    "details" => :details,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :activity, nil), layout: {LantternWeb.Layouts, :app_logged_in_blank}}
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
       fn params -> ~p"/strands/activity/#{params["id"]}/?#{Map.drop(params, ["id"])}" end
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

  defp apply_action(%{assigns: %{activity: nil}} = socket, _live_action, %{"id" => id}) do
    # pattern match assigned activity to prevent unnecessary get_activity calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_activity(id,
           preloads: [:strand, :subjects]
         ) do
      activity when is_nil(activity) ->
        socket
        |> put_flash(:error, "Couldn't find activity")
        |> redirect(to: ~p"/strands")

      activity ->
        socket
        |> assign(:activity, activity)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket

  # event handlers

  @impl true
  def handle_event("delete_activity", _params, socket) do
    case LearningContext.delete_activity(socket.assigns.activity) do
      {:ok, _activity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Activity deleted")
         |> push_navigate(to: ~p"/strands/#{socket.assigns.activity.strand}?tab=activities")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Activity has linked assessments. Deleting it would cause some data loss."
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({ActivityFormComponent, {:saved, activity}}, socket) do
    {:noreply, assign(socket, :activity, activity)}
  end
end
