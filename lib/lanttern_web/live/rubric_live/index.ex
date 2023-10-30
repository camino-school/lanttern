defmodule LantternWeb.RubricLive.Index do
  use LantternWeb, :live_view

  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rubrics, Rubrics.list_rubrics(preloads: :scale))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Rubric")
    |> assign(:rubric, Rubrics.get_rubric!(id, preloads: :descriptors))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Rubric")
    |> assign(:rubric, %Rubric{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rubrics")
    |> assign(:rubric, nil)
  end

  @impl true
  def handle_info({LantternWeb.RubricLive.FormComponent, {:saved, rubric}}, socket) do
    {:noreply, stream_insert(socket, :rubrics, rubric)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    rubric = Rubrics.get_rubric!(id)
    {:ok, _} = Rubrics.delete_rubric(rubric)

    {:noreply, stream_delete(socket, :rubrics, rubric)}
  end
end
