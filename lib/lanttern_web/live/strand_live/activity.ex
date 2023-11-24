defmodule LantternWeb.StrandLive.Activity do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias LantternWeb.StrandLive.ActivityTabs

  alias LantternWeb.AssessmentPointLive.ActivityAssessmentPointFormComponent

  @tabs %{
    "details" => :details,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :activity, nil), layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> set_current_tab(params, socket.assigns.live_action)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp set_current_tab(socket, _params, :new_assessment_point),
    do: assign(socket, :current_tab, @tabs["assessment"])

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :details))

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :details)

  defp apply_action(%{assigns: %{activity: nil}} = socket, _live_action, %{"id" => id}) do
    # pattern match assigned activity to prevent unnecessary get_activity calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_activity(id, preloads: [:strand, :subjects]) do
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

  # info handlers

  def handle_info({ActivityAssessmentPointFormComponent, {:created, _assessment_point}}, socket) do
    {:noreply,
     socket
     |> push_patch(to: ~p"/strands/activity/#{socket.assigns.activity}?tab=assessment")}
  end
end
