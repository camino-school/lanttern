defmodule LantternWeb.Admin.MomentLive.Index do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(
       socket,
       :moments,
       LearningContext.list_moments(
         preloads: [
           :strand,
           :subjects,
           curriculum_items: :curriculum_component
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
    |> assign(:page_title, "Edit Moment")
    |> assign(
      :moment,
      LearningContext.get_moment!(id,
        preloads: [:subjects, curriculum_items: :curriculum_component]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Moment")
    |> assign(:moment, %Moment{curriculum_items: [], subjects: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Moments")
    |> assign(:moment, nil)
  end

  @impl true
  def handle_info({LantternWeb.LearningContext.MomentFormComponent, {action, moment}}, socket)
      when action in [:created, :updated] do
    {:noreply, stream_insert(socket, :moments, moment)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    moment = LearningContext.get_moment!(id)
    {:ok, _} = LearningContext.delete_moment(moment)

    {:noreply, stream_delete(socket, :moments, moment)}
  end
end
