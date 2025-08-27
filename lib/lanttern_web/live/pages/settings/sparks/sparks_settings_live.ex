defmodule LantternWeb.SparksSettingsLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsInsights
  alias Lanttern.StudentsInsights.Tag

  # shared components
  alias LantternWeb.StudentsInsights.SparksTagFormOverlayComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      StudentsInsights.subscribe_student_insight_tags(socket.assigns.current_user)
    end

    socket =
      socket
      |> stream_tags()

    {:ok, socket}
  end

  defp stream_tags(socket) do
    tags = StudentsInsights.list_tags(socket.assigns.current_user)

    socket
    |> stream(:tags, tags)
    |> assign(:tags_count, length(tags))
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_tag(params)

    {:noreply, socket}
  end

  defp assign_tag(socket, %{"new" => "true"}) do
    assign(socket, :tag, %Tag{})
  end

  defp assign_tag(socket, %{"tag_id" => tag_id}) do
    case Integer.parse(tag_id) do
      {id, _} ->
        case StudentsInsights.get_tag(socket.assigns.current_user, id) do
          %Tag{} = tag ->
            assign(socket, :tag, tag)

          nil ->
            assign(socket, :tag, nil)
        end

      :error ->
        assign(socket, :tag, nil)
    end
  end

  defp assign_tag(socket, _params) do
    assign(socket, :tag, nil)
  end

  # info handlers

  @impl true
  def handle_info({action, tag}, socket) when action in [:created, :updated] do
    {:noreply, stream_insert(socket, :tags, tag)}
  end

  def handle_info({action, tag}, socket) when action == :deleted do
    {:noreply, stream_delete(socket, :tags, tag)}
  end
end
