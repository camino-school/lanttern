defmodule LantternWeb.Admin.NoteLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Personalization
  alias Lanttern.Personalization.Note

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :notes, Personalization.list_notes(preloads: [author: [:teacher, :student]]))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Note")
    |> assign(:note, Personalization.get_note!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Note")
    |> assign(:note, %Note{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Notes")
    |> assign(:note, nil)
  end

  @impl true
  def handle_info({LantternWeb.Admin.NoteLive.FormComponent, {:saved, note}}, socket) do
    {:noreply, stream_insert(socket, :notes, note)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    note = Personalization.get_note!(id)
    {:ok, _} = Personalization.delete_note(note)

    {:noreply, stream_delete(socket, :notes, note)}
  end
end
