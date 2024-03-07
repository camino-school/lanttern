defmodule LantternWeb.GradeReportsLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.GradeReport

  # live components
  alias LantternWeb.Reporting.GradeReportFormComponent

  # shared
  import LantternWeb.GradingComponents

  # lifecycle

  @impl true
  def handle_params(params, _uri, socket) do
    grade_reports =
      Reporting.list_grade_reports(preloads: [:school_cycle, [scale: :ordinal_values]])

    socket =
      socket
      |> stream(:grade_reports, grade_reports)
      |> assign(:has_grade_reports, length(grade_reports) > 0)
      |> assign_show_grade_report_form(params)

    {:noreply, socket}
  end

  defp assign_show_grade_report_form(socket, %{"is_creating" => "true"}) do
    socket
    |> assign(:grade_report, %GradeReport{})
    |> assign(:form_overlay_title, gettext("Create grade report"))
    |> assign(:show_grade_report_form, true)
  end

  defp assign_show_grade_report_form(socket, %{"is_editing" => id}) do
    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case Reporting.get_grade_report(id) do
          %GradeReport{} = grade_report ->
            socket
            |> assign(:form_overlay_title, gettext("Edit grade report"))
            |> assign(:grade_report, grade_report)
            |> assign(:show_grade_report_form, true)

          _ ->
            assign(socket, :show_grade_report_form, false)
        end

      true ->
        assign(socket, :show_grade_report_form, false)
    end
  end

  defp assign_show_grade_report_form(socket, _),
    do: assign(socket, :show_grade_report_form, false)

  # event handlers

  @impl true
  def handle_event("delete_grade_report", _params, socket) do
    case Reporting.delete_grade_report(socket.assigns.grade_report) do
      {:ok, _grade_report} ->
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
