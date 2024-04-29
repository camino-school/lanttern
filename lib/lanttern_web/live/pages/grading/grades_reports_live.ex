defmodule LantternWeb.GradesReportsLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  alias Lanttern.GradesReports.GradesReport

  # local view components
  alias LantternWeb.ReportCardLive.GradesReportGridSetupOverlayComponent

  # live components
  alias LantternWeb.GradesReports.GradesReportFormComponent

  # shared
  import LantternWeb.GradingComponents
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Grades reports"))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    grades_reports =
      GradesReports.list_grades_reports(
        preloads: [:year, scale: :ordinal_values],
        load_grid: true
      )

    socket =
      socket
      |> stream(:grades_reports, grades_reports)
      |> assign(:has_grades_reports, length(grades_reports) > 0)
      |> assign_show_grades_report_form(params)
      |> assign_show_grades_report_grid_editor(params)

    {:noreply, socket}
  end

  defp assign_show_grades_report_form(socket, %{"is_creating" => "true"}) do
    socket
    |> assign(:grades_report, %GradesReport{})
    |> assign(:form_overlay_title, gettext("Create grade report"))
    |> assign(:show_grades_report_form, true)
  end

  defp assign_show_grades_report_form(socket, %{"is_editing" => id}) do
    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case GradesReports.get_grades_report(id) do
          %GradesReport{} = grades_report ->
            socket
            |> assign(:form_overlay_title, gettext("Edit grade report"))
            |> assign(:grades_report, grades_report)
            |> assign(:show_grades_report_form, true)

          _ ->
            assign(socket, :show_grades_report_form, false)
        end

      true ->
        assign(socket, :show_grades_report_form, false)
    end
  end

  defp assign_show_grades_report_form(socket, _),
    do: assign(socket, :show_grades_report_form, false)

  defp assign_show_grades_report_grid_editor(socket, %{"is_editing_grid" => id}) do
    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case GradesReports.get_grades_report(id) do
          %GradesReport{} = grades_report ->
            socket
            # |> assign(:form_overlay_title, gettext("Edit grade report"))
            |> assign(:grades_report, grades_report)
            |> assign(:show_grades_report_grid_editor, true)

          _ ->
            assign(socket, :show_grades_report_grid_editor, false)
        end

      true ->
        assign(socket, :show_grades_report_grid_editor, false)
    end
  end

  defp assign_show_grades_report_grid_editor(socket, _),
    do: assign(socket, :show_grades_report_grid_editor, false)

  # event handlers

  @impl true
  def handle_event("delete_grades_report", _params, socket) do
    case GradesReports.delete_grades_report(socket.assigns.grades_report) do
      {:ok, _grades_report} ->
        socket =
          socket
          |> put_flash(:info, gettext("Grade report deleted"))
          |> push_navigate(to: ~p"/grading")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting grade report"))

        {:noreply, socket}
    end
  end
end
