defmodule LantternWeb.StrandLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.StrandLive.AboutComponent
  alias LantternWeb.StrandLive.ActivitiesComponent
  alias LantternWeb.StrandLive.AssessmentComponent
  alias LantternWeb.StrandLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.StrandFormComponent

  @tabs %{
    "about" => :about,
    "activities" => :activities,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :strand, nil), layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(%{"tab" => "assessment"} = params, _url, socket) do
    # when in assessment tab, sync classes_ids filter with profile
    handle_params_and_profile_filters_sync(
      params,
      socket,
      [:classes_ids],
      &handle_assigns/2,
      fn params -> ~p"/strands/#{params["id"]}/?#{Map.drop(params, ["id"])}" end
    )
  end

  def handle_params(params, _url, socket),
    do: {:noreply, handle_assigns(socket, params)}

  defp handle_assigns(socket, params) do
    socket
    |> assign(:params, params)
    |> set_current_tab(params, socket.assigns.live_action)
    |> apply_action(socket.assigns.live_action, params)
  end

  defp set_current_tab(socket, _params, :new_activity),
    do: assign(socket, :current_tab, @tabs["activities"])

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :about))

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :about)

  defp apply_action(%{assigns: %{strand: nil}} = socket, live_action, %{"id" => id})
       when live_action in [:show, :edit, :new_activity] do
    # pattern match assigned strand to prevent unnecessary get_strand calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_strand(id, preloads: [:subjects, :years, :curriculum_items]) do
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

  # event handlers

  @impl true
  def handle_event("delete_strand", _params, socket) do
    case LearningContext.delete_strand(socket.assigns.strand) do
      {:ok, _strand} ->
        {:noreply,
         socket
         |> put_flash(:info, "Strand deleted")
         |> push_navigate(to: ~p"/strands")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Strand has linked activities. Deleting it would cause some data loss."
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, assign(socket, :strand, strand)}
  end
end
