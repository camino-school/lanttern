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
  alias LantternWeb.Reporting.ReportCardFormComponent

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
    socket =
      socket
      |> assign(:params, params)
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
end
