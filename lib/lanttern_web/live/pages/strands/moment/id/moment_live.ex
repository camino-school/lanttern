defmodule LantternWeb.MomentLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  import LantternWeb.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # page components
  alias LantternWeb.MomentLive.OverviewComponent
  alias LantternWeb.MomentLive.AssessmentComponent
  alias LantternWeb.MomentLive.CardsComponent
  alias LantternWeb.MomentLive.NotesComponent

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent

  @tabs %{
    "overview" => :overview,
    "assessment" => :assessment,
    "cards" => :cards,
    "notes" => :notes
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:moment, nil)
      |> maybe_redirect(params)

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, params)
       when live_action in [:edit_card],
       do: redirect(socket, to: ~p"/strands/moment/#{params["id"]}?tab=cards")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:assessment_point_id, nil)
      |> set_current_tab(params, socket.assigns.live_action)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp set_current_tab(socket, _params, :new_assessment_point),
    do: assign(socket, :current_tab, @tabs["assessment"])

  defp set_current_tab(
         socket,
         %{"assessment_point_id" => assessment_point_id},
         :edit_assessment_point
       ) do
    socket
    |> assign(:current_tab, @tabs["assessment"])
    |> assign(:assessment_point_id, assessment_point_id)
  end

  defp set_current_tab(socket, _params, :edit_card),
    do: assign(socket, :current_tab, @tabs["cards"])

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :overview))

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :overview)

  defp apply_action(%{assigns: %{moment: nil}} = socket, _live_action, %{"id" => id}) do
    # pattern match assigned moment to prevent unnecessary get_moment calls
    # (during handle_params triggered by tab change for example)

    case LearningContext.get_moment(id,
           preloads: [:strand, :subjects]
         ) do
      moment when is_nil(moment) ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))
        |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
        |> assign(
          :cover_image_url,
          object_url_to_render_url(moment.strand.cover_image_url, width: 1280, height: 640)
        )
        |> assign(:page_title, "#{moment.name} • #{moment.strand.name}")
    end
  end

  defp apply_action(socket, _live_action, _params), do: socket

  # event handlers

  @impl true
  def handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment deleted"))
         |> push_navigate(to: ~p"/strands/#{socket.assigns.moment.strand}?tab=moments")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("Moment has linked assessments. Deleting it would cause some data loss.")
         )}
    end
  end

  # info handlers

  @impl true
  def handle_info({MomentFormComponent, {:saved, moment}}, socket) do
    {:noreply, assign(socket, :moment, moment)}
  end
end
