defmodule LantternWeb.GradesReportLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  # alias Lanttern.GradesReports.GradesReport

  # # local view components
  # alias LantternWeb.ReportCardLive.GradesReportGridSetupOverlayComponent

  # live components
  alias LantternWeb.GradesReports.GradesReportFormComponent
  alias LantternWeb.GradesReports.GradesReportGridConfigurationOverlayComponent
  # alias LantternWeb.Grading.GradeCompositionOverlayComponent

  # # shared
  # import LantternWeb.GradesReportsComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    grades_report =
      case GradesReports.get_grades_report(params["id"],
             preloads: [:school_cycle, :year, scale: :ordinal_values]
           ) do
        nil -> raise LantternWeb.NotFoundError
        grades_report -> grades_report
      end

    socket =
      socket
      |> assign(:page_title, gettext("Grades reports"))
      |> assign(:grades_report, grades_report)
      |> assign(:is_editing, false)
      |> assign(:is_configuring, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {is_editing, is_configuring} =
      case params do
        %{"is_editing" => "true"} -> {true, false}
        %{"is_configuring" => "true"} -> {false, true}
        _ -> {false, false}
      end

    socket =
      socket
      |> assign(:is_editing, is_editing)
      |> assign(:is_configuring, is_configuring)

    {:noreply, socket}
  end

  # defp assign_show_grades_report_form(socket, %{"is_creating" => "true"}) do
  #   socket
  #   |> assign(:grades_report, %GradesReport{})
  #   |> assign(:form_overlay_title, gettext("Create grade report"))
  #   |> assign(:show_grades_report_form, true)
  # end

  # defp assign_show_grades_report_form(socket, %{"is_editing" => id}) do
  #   if String.match?(id, ~r/[0-9]+/) do
  #     case GradesReports.get_grades_report(id) do
  #       %GradesReport{} = grades_report ->
  #         socket
  #         |> assign(:form_overlay_title, gettext("Edit grade report"))
  #         |> assign(:grades_report, grades_report)
  #         |> assign(:show_grades_report_form, true)

  #       _ ->
  #         assign(socket, :show_grades_report_form, false)
  #     end
  #   else
  #     assign(socket, :show_grades_report_form, false)
  #   end
  # end

  # defp assign_show_grades_report_form(socket, _),
  #   do: assign(socket, :show_grades_report_form, false)

  # defp assign_show_grades_report_grid_editor(socket, %{"is_editing_grid" => id}) do
  #   if String.match?(id, ~r/[0-9]+/) do
  #     case GradesReports.get_grades_report(id) do
  #       %GradesReport{} = grades_report ->
  #         socket
  #         # |> assign(:form_overlay_title, gettext("Edit grade report"))
  #         |> assign(:grades_report, grades_report)
  #         |> assign(:show_grades_report_grid_editor, true)

  #       _ ->
  #         assign(socket, :show_grades_report_grid_editor, false)
  #     end
  #   else
  #     assign(socket, :show_grades_report_grid_editor, false)
  #   end
  # end

  # defp assign_show_grades_report_grid_editor(socket, _),
  #   do: assign(socket, :show_grades_report_grid_editor, false)

  # defp assign_is_editing_grade_composition(socket, %{
  #        "gr_id" => grades_report_id,
  #        "grc_id" => grades_report_cycle_id,
  #        "grs_id" => grades_report_subject_id
  #      }) do
  #   socket
  #   |> assign(:is_editing_grade_composition, true)
  #   |> assign(:grades_report_id, grades_report_id)
  #   |> assign(:grades_report_cycle_id, grades_report_cycle_id)
  #   |> assign(:grades_report_subject_id, grades_report_subject_id)
  # end

  # defp assign_is_editing_grade_composition(socket, _) do
  #   socket
  #   |> assign(:is_editing_grade_composition, false)
  #   |> assign(:grades_report_id, nil)
  #   |> assign(:grades_report_cycle_id, nil)
  #   |> assign(:grades_report_subject_id, nil)
  # end

  # event handlers

  @impl true
  def handle_event("delete_grades_report", _params, socket) do
    case GradesReports.delete_grades_report(socket.assigns.grades_report) do
      {:ok, _grades_report} ->
        socket =
          socket
          |> put_flash(:info, gettext("Grade report deleted"))
          |> push_navigate(to: ~p"/grades_reports")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting grade report"))

        {:noreply, socket}
    end
  end

  # def handle_event("edit_composition", params, socket) do
  #   url_params = %{
  #     gr_id: params["gradesreportid"],
  #     grc_id: params["gradesreportcycleid"],
  #     grs_id: params["gradesreportsubjectid"]
  #   }

  #   socket =
  #     socket
  #     |> push_patch(to: ~p"/grades_reports?#{url_params}")

  #   {:noreply, socket}
  # end
end
