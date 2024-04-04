defmodule LantternWeb.RubricsLive do
  use LantternWeb, :live_view

  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  import LantternWeb.RubricsComponents

  # lifecycle

  def mount(_params, _session, socket) do
    rubrics = Rubrics.list_full_rubrics()
    results = length(rubrics)

    socket =
      socket
      |> stream(:rubrics, rubrics)
      |> assign(:results, results)
      |> assign(:page_title, gettext("Rubrics"))

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:overlay_title, "Edit rubric")
    |> assign(:rubric, Rubrics.get_rubric!(id, preloads: :descriptors))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:overlay_title, "Create Rubric")
    |> assign(:rubric, %Rubric{})
  end

  defp apply_action(socket, :index, _params), do: socket

  # event handlers

  def handle_event("delete", %{"id" => id}, socket) do
    rubric = Rubrics.get_rubric!(id)
    {:ok, _} = Rubrics.delete_rubric(rubric)

    socket =
      socket
      |> stream_delete(:rubrics, rubric)
      |> update(:results, &(&1 - 1))

    {:noreply, socket}
  end

  # info handlers

  def handle_info({LantternWeb.Rubrics.RubricFormComponent, {:created, rubric}}, socket) do
    rubric = Rubrics.get_full_rubric!(rubric.id)

    socket =
      socket
      |> stream_insert(:rubrics, rubric)
      |> update(:results, &(&1 + 1))

    {:noreply, socket}
  end

  def handle_info({LantternWeb.Rubrics.RubricFormComponent, {:updated, rubric}}, socket) do
    rubric = Rubrics.get_full_rubric!(rubric.id)
    {:noreply, stream_insert(socket, :rubrics, rubric)}
  end
end
