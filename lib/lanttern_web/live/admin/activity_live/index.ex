defmodule LantternWeb.Admin.ActivityLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Activity

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(
       socket,
       :activities,
       LearningContext.list_activities(
         preloads: [
           :strand,
           :subjects,
           curriculum_items: [curriculum_item: :curriculum_component]
         ]
       )
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Activity")
    |> assign(
      :activity,
      LearningContext.get_activity!(id,
        preloads: [:subjects, curriculum_items: [curriculum_item: :curriculum_component]]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Activity")
    |> assign(:activity, %Activity{curriculum_items: [], subjects: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Activities")
    |> assign(:activity, nil)
  end

  @impl true
  def handle_info({LantternWeb.Admin.ActivityLive.FormComponent, {:saved, activity}}, socket) do
    {:noreply, stream_insert(socket, :activities, activity)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    activity = LearningContext.get_activity!(id)
    {:ok, _} = LearningContext.delete_activity(activity)

    {:noreply, stream_delete(socket, :activities, activity)}
  end
end
