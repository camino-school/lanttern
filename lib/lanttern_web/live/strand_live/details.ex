defmodule LantternWeb.StrandLive.Details do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias LantternWeb.StrandLive.DetailsTabs

  @tabs %{
    "about" => :about,
    "activities" => :activities,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :strand, nil), layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> set_current_tab(params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp set_current_tab(socket, %{"tab" => tab}),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :about))

  defp set_current_tab(socket, _params),
    do: assign(socket, :current_tab, :about)

  defp apply_action(%{assigns: %{strand: nil}} = socket, :show, %{"id" => id}) do
    # pattern match assigned strand to prevent unnecessary get_strand calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_strand(id,
           preloads: [
             :subjects,
             :years,
             curriculum_items: [curriculum_item: :curriculum_component]
           ]
         ) do
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
