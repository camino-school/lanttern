defmodule LantternWeb.ReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting

  # page components
  alias __MODULE__.StrandsReportsComponent

  # shared components
  alias LantternWeb.Reporting.ReportCardFormComponent

  @tabs %{
    "students" => :students,
    "strands" => :strands
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> maybe_redirect(params)

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  # prevent user from navigating directly to nested views

  defp maybe_redirect(%{assigns: %{live_action: :edit}} = socket, params),
    do: redirect(socket, to: ~p"/report_cards/#{params["id"]}?tab=students")

  defp maybe_redirect(%{assigns: %{live_action: :edit_strand_report}} = socket, params),
    do: redirect(socket, to: ~p"/report_cards/#{params["id"]}?tab=strands")

  defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    report_card =
      Reporting.get_report_card!(id, preloads: :school_cycle)

    socket =
      socket
      |> assign(:params, params)
      |> assign(:report_card, report_card)
      |> set_current_tab(params, socket.assigns.live_action)

    {:noreply, socket}
  end

  defp set_current_tab(socket, _params, :edit_strand_report),
    do: assign(socket, :current_tab, @tabs["strands"])

  defp set_current_tab(socket, %{"tab" => tab}, _live_action),
    do: assign(socket, :current_tab, Map.get(@tabs, tab, :students))

  defp set_current_tab(socket, _params, _live_action),
    do: assign(socket, :current_tab, :students)

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
