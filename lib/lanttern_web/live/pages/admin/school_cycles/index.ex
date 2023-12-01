defmodule LantternWeb.Admin.CycleLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :school_cycles, Schools.list_cycles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Cycle")
    |> assign(:cycle, Schools.get_cycle!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Cycle")
    |> assign(:cycle, %Cycle{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing School cycles")
    |> assign(:cycle, nil)
  end

  @impl true
  def handle_info({LantternWeb.Admin.CycleLive.FormComponent, {:saved, cycle}}, socket) do
    {:noreply, stream_insert(socket, :school_cycles, cycle)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cycle = Schools.get_cycle!(id)
    {:ok, _} = Schools.delete_cycle(cycle)

    {:noreply, stream_delete(socket, :school_cycles, cycle)}
  end
end
