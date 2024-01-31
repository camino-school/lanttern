defmodule LantternWeb.StrandLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext

  # page components
  alias LantternWeb.StrandLive.AboutComponent
  alias LantternWeb.StrandLive.MomentsComponent
  alias LantternWeb.StrandLive.AssessmentComponent
  alias LantternWeb.StrandLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.StrandFormComponent

  @tabs %{
    "about" => :about,
    "moments" => :moments,
    "assessment" => :assessment,
    "notes" => :notes
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:strand, nil)
      |> maybe_redirect(params)

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, params)
       when live_action in [:manage_rubric],
       do: redirect(socket, to: ~p"/strands/#{params["id"]}?tab=assessment")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(%{"tab" => "assessment"} = params, _url, socket) do
    # when in assessment tab, sync classes_ids filter with profile
    {:noreply,
     handle_params_and_profile_filters_sync(
       socket,
       params,
       [:classes_ids],
       &handle_assigns/2,
       fn params -> ~p"/strands/#{params["id"]}/?#{Map.drop(params, ["id"])}" end
     )}
  end

  def handle_params(params, _url, socket),
    do: {:noreply, handle_assigns(socket, params)}

  defp handle_assigns(socket, params) do
    socket
    |> assign(:params, params)
    |> set_current_tab(params, socket.assigns.live_action)
    |> apply_action(socket.assigns.live_action, params)
  end

  defp set_current_tab(socket, _params, :new_moment),
    do: assign(socket, :current_tab, @tabs["moments"])

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :about))

  defp set_current_tab(socket, _params, live_action)
       when live_action in [:manage_rubric],
       do: assign(socket, :current_tab, :assessment)

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :about)

  defp apply_action(%{assigns: %{strand: nil}} = socket, _live_action, %{"id" => id}) do
    # pattern match assigned strand to prevent unnecessary get_strand calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_strand(id, preloads: [:subjects, :years]) do
      strand when is_nil(strand) ->
        socket
        |> put_flash(:error, gettext("Couldn't find strand"))
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
         |> put_flash(:info, gettext("Strand deleted"))
         |> push_navigate(to: ~p"/strands")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext(
             "Strand has linked moments and/or assessment points (goals). Deleting it would cause some data loss."
           )
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, assign(socket, :strand, strand)}
  end
end
