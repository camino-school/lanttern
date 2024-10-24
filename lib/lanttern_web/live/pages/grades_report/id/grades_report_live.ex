defmodule LantternWeb.GradesReportLive do
  use LantternWeb, :live_view

  alias Lanttern.GradesReports
  # alias Lanttern.GradesReports.GradesReport

  # # local view components
  # alias LantternWeb.ReportCardLive.GradesReportGridSetupOverlayComponent

  # live components
  import LantternWeb.GradesReportsComponents
  alias LantternWeb.GradesReports.GradesReportFormComponent
  alias LantternWeb.GradesReports.GradesReportGridConfigurationOverlayComponent
  alias LantternWeb.GradesReports.StudentGradesReportEntryOverlayComponent
  # alias LantternWeb.Grading.GradeCompositionOverlayComponent

  # # shared
  # import LantternWeb.GradesReportsComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Grades reports"))
      |> assign_grades_report(params)
      |> stream_students()
      |> assign_students_grades_map()
      |> assign(:is_editing, false)
      |> assign(:is_configuring, false)

    {:ok, socket}
  end

  defp assign_grades_report(socket, %{"id" => id}) do
    grades_report =
      case GradesReports.get_grades_report(id,
             preloads: [
               :school_cycle,
               :year,
               scale: :ordinal_values,
               grades_report_cycles: :school_cycle,
               grades_report_subjects: :subject
             ]
           ) do
        nil -> raise LantternWeb.NotFoundError
        grades_report -> grades_report
      end

    grades_report_cycles =
      grades_report.grades_report_cycles
      |> Enum.sort_by(& &1.school_cycle.start_at, Date)

    grades_report_subjects =
      grades_report.grades_report_subjects
      |> Enum.sort_by(& &1.position)

    socket
    |> assign(:grades_report, grades_report)
    |> assign(:grades_report_cycles, grades_report_cycles)
    |> assign(:grades_report_subjects, grades_report_subjects)
  end

  defp stream_students(socket) do
    grades_report = socket.assigns.grades_report
    students = GradesReports.list_grades_report_students(grades_report.id, grades_report.year_id)

    socket
    |> stream(:students, students)
    |> assign(:has_students, length(students) > 0)
  end

  defp assign_students_grades_map(socket) do
    students_grades_map =
      GradesReports.build_students_full_grades_report_map(socket.assigns.grades_report.id)

    assign(socket, :students_grades_map, students_grades_map)
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
      |> assign_student_grades_report_entry(params)

    {:noreply, socket}
  end

  defp assign_student_grades_report_entry(socket, %{
         "student_grades_report_entry" => student_grades_report_entry_id
       }) do
    grades_report = socket.assigns.grades_report

    student_grades_report_entry =
      GradesReports.get_student_grades_report_entry!(
        student_grades_report_entry_id,
        preloads: [
          :student,
          :composition_ordinal_value,
          grades_report_subject: :subject,
          grades_report_cycle: :school_cycle
        ]
      )

    case student_grades_report_entry.grades_report_id == grades_report.id do
      true ->
        socket
        |> assign(:is_editing_student_grades_report_entry, true)
        |> assign(:student_grades_report_entry, student_grades_report_entry)

      _ ->
        assign(socket, :is_editing_student_grades_report_entry, false)
    end
  end

  defp assign_student_grades_report_entry(socket, _),
    do: assign(socket, :is_editing_student_grades_report_entry, false)

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
