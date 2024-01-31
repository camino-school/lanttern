defmodule LantternWeb.Admin.MomentCardLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.MomentCard

  # shared components
  alias LantternWeb.LearningContext.MomentCardFormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :moment_cards, LearningContext.list_moment_cards())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Moment card")
    |> assign(:moment_card, LearningContext.get_moment_card!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Moment card")
    |> assign(:moment_card, %MomentCard{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Moment cards")
    |> assign(:moment_card, nil)
  end

  @impl true
  def handle_info({MomentCardFormComponent, {:saved, moment_card}}, socket) do
    {:noreply, stream_insert(socket, :moment_cards, moment_card)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    moment_card = LearningContext.get_moment_card!(id)
    {:ok, _} = LearningContext.delete_moment_card(moment_card)

    {:noreply, stream_delete(socket, :moment_cards, moment_card)}
  end
end
