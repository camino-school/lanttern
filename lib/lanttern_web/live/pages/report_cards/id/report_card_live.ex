defmodule LantternWeb.ReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.ReportCard
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # page components
  alias __MODULE__.GradesComponent
  alias __MODULE__.StrandsReportsComponent
  alias __MODULE__.StudentsComponent
  alias __MODULE__.StudentsGradesComponent
  alias __MODULE__.StudentsTrackingComponent

  # shared components
  alias LantternWeb.Filters.InlineFiltersComponent
  alias LantternWeb.Reporting.ReportCardFormComponent

  import LantternWeb.FiltersHelpers,
    only: [url_filter_params: 1, path_with_url_filters: 2, path_with_url_filters: 3]

  @tabs %{
    "students" => :students,
    "strands" => :strands,
    "grades" => :grades,
    "tracking" => :tracking
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_report_card(params)

    {:ok, socket}
  end

  defp assign_report_card(socket, %{"id" => id}) do
    report_card =
      case Reporting.get_report_card(id, preloads: [:year, school_cycle: :parent_cycle]) do
        %ReportCard{school_cycle: %{school_id: school_id}} = report_card
        when school_id == socket.assigns.current_user.current_profile.school_id ->
          report_card

        _ ->
          # nil or access to other schools report cards
          raise LantternWeb.NotFoundError
      end

    socket
    |> assign(:report_card, report_card)
    |> assign(
      :cover_image_url,
      object_url_to_render_url(report_card.cover_image_url, width: 1280, height: 640)
    )
    |> assign(:page_title, report_card.name)
  end

  @impl true
  def handle_params(params, _url, socket) do
    url_filter_params = url_filter_params(Map.drop(params, ["id"]))

    socket =
      socket
      |> assign(:params, params)
      |> assign(:url_filter_params, url_filter_params)
      |> assign_current_tab(params)
      |> assign_is_editing(params)

    {:noreply, assign(socket, :page_title, socket.assigns.report_card.name)}
  end

  defp assign_current_tab(socket, %{"tab" => tab}),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :students))

  defp assign_current_tab(socket, _params),
    do: assign(socket, :current_tab, :students)

  defp assign_is_editing(socket, %{"is_editing" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _),
    do: assign(socket, :is_editing, false)

  # event handlers

  @impl true
  def handle_event("delete_report_card", _params, socket) do
    case Reporting.delete_report_card(socket.assigns.report_card) do
      {:ok, _report_card} ->
        socket =
          socket
          |> put_flash(:info, gettext("Report card deleted"))
          |> push_navigate(to: ~p"/report_cards")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting report card"))

        {:noreply, socket}
    end
  end

  # info handlers

  @impl true
  def handle_info({InlineFiltersComponent, {:apply, classes_ids}}, socket) do
    params =
      case Enum.join(classes_ids, ",") do
        "" -> Map.delete(socket.assigns.url_filter_params, "classes_ids")
        ids -> Map.put(socket.assigns.url_filter_params, "classes_ids", ids)
      end

    report_card = socket.assigns.report_card

    path =
      case socket.assigns.live_action do
        :students -> ~p"/report_cards/#{report_card}/students?#{params}"
        :grades -> ~p"/report_cards/#{report_card}/grades?#{params}"
        :tracking -> ~p"/report_cards/#{report_card}/tracking?#{params}"
      end

    {:noreply, push_patch(socket, to: path)}
  end
end
