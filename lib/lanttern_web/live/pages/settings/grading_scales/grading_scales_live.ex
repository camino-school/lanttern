defmodule LantternWeb.GradingScalesLive do
  @moduledoc """
  Live view for managing grading scales with CRUD operations.
  """

  use LantternWeb, :live_view

  alias Lanttern.Grading
  alias Lanttern.Grading.Scale

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :live_action, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case socket.assigns.live_action do
      :show ->
        scale = Grading.get_scale!(id)
        {:noreply, assign(socket, scale: scale)}

      :edit ->
        scale = Grading.get_scale!(id)
        changeset = Grading.change_scale(scale)
        {:noreply, assign(socket, scale: scale, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    case socket.assigns.live_action do
      :index ->
        scales = Grading.list_scales()
        {:noreply, assign(socket, scales: scales)}

      :new ->
        changeset = Grading.change_scale(%Scale{})
        {:noreply, assign(socket, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    scale = Grading.get_scale!(id)
    {:ok, _} = Grading.delete_scale(scale)

    scales = Grading.list_scales()

    {:noreply,
     socket
     |> put_flash(:info, "Scale deleted successfully.")
     |> assign(scales: scales)}
  end
end
