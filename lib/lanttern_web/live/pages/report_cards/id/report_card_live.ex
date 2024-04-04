defmodule LantternWeb.ReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  import LantternWeb.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # page components
  alias __MODULE__.StudentsComponent
  alias __MODULE__.StrandsReportsComponent
  alias __MODULE__.GradesComponent
  alias __MODULE__.StudentsGradesComponent

  # shared components
  alias LantternWeb.Reporting.ReportCardFormComponent

  @tabs %{
    "students" => :students,
    "strands" => :strands,
    "grades" => :grades
  }

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_new(:report_card, fn ->
        Reporting.get_report_card!(id, preloads: [:school_cycle, :year])
      end)
      |> assign_new(
        :cover_image_url,
        fn %{report_card: report_card} ->
          object_url_to_render_url(report_card.cover_image_url, width: 1280, height: 640)
        end
      )
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
