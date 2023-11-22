defmodule LantternWeb.StrandLive.Details do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    case LearningContext.get_strand(id, preloads: [:subjects, :years]) do
      strand when is_nil(strand) ->
        socket
        |> put_flash(:error, "Couldn't find strand")
        |> redirect(to: ~p"/strands")

      strand ->
        socket
        |> assign(:strand, strand)
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket
end
