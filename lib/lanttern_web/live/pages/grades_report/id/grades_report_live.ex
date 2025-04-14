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
  alias LantternWeb.GradesReports.StudentGradesReportFinalEntryOverlayComponent
  # alias LantternWeb.Grading.GradeCompositionOverlayComponent

  # shared
  import LantternWeb.GradesReportsHelpers, only: [build_calculation_results_message: 1]

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
        nil ->
          raise LantternWeb.NotFoundError

        %{school_cycle: %{school_id: school_id}}
        when school_id != socket.assigns.current_user.current_profile.school_id ->
          # prevent access to other schools grades reports
          raise LantternWeb.NotFoundError

        grades_report ->
          grades_report
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
    |> assign(:students_ids, Enum.map(students, & &1.id))
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
      |> assign_student_grades_report_final_entry(params)

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

  defp assign_student_grades_report_final_entry(socket, %{
         "student_grades_report_final_entry" => student_grades_report_final_entry_id
       }) do
    grades_report = socket.assigns.grades_report

    student_grades_report_final_entry =
      GradesReports.get_student_grades_report_final_entry!(
        student_grades_report_final_entry_id,
        preloads: [
          :student,
          :composition_ordinal_value,
          grades_report_subject: :subject
        ]
      )

    case student_grades_report_final_entry.grades_report_id == grades_report.id do
      true ->
        socket
        |> assign(:is_editing_student_grades_report_final_entry, true)
        |> assign(:student_grades_report_final_entry, student_grades_report_final_entry)

      _ ->
        assign(socket, :is_editing_student_grades_report_final_entry, false)
    end
  end

  defp assign_student_grades_report_final_entry(socket, _),
    do: assign(socket, :is_editing_student_grades_report_final_entry, false)

  # event handlers

  @impl true
  def handle_event("toggle_final_grades_visibility", _params, socket) do
    GradesReports.update_grades_report(socket.assigns.grades_report, %{
      final_is_visible: !socket.assigns.grades_report.final_is_visible
    })
    |> case do
      {:ok, updated_grades_report} ->
        {:noreply, assign(socket, :grades_report, updated_grades_report)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Error updating final grades visibility"))}
    end
  end

  def handle_event("delete_grades_report", _params, socket) do
    case GradesReports.delete_grades_report(socket.assigns.grades_report) do
      {:ok, _grades_report} ->
        socket =
          socket
          |> put_flash(:info, gettext("Grades report deleted"))
          |> push_navigate(to: ~p"/grades_reports")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting grade report"))

        {:noreply, socket}
    end
  end

  def handle_event("calculate_all", _params, socket) do
    socket =
      GradesReports.calculate_grades_report_final_grades(
        socket.assigns.students_ids,
        socket.assigns.grades_report.id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("All final grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/grades_reports/#{socket.assigns.grades_report}")

        {:error, _, results} ->
          put_flash(
            socket,
            :error,
            "#{gettext("Something went wrong")}. #{gettext("Partial results")}: #{build_calculation_results_message(results)}"
          )
      end

    {:noreply, socket}
  end

  def handle_event("calculate_student", params, socket) do
    %{"student_id" => student_id} = params

    socket =
      GradesReports.calculate_student_final_grades(
        student_id,
        socket.assigns.grades_report.id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("Student final grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/grades_reports/#{socket.assigns.grades_report}")

        {:error, _, results} ->
          put_flash(
            socket,
            :error,
            "#{gettext("Something went wrong")}. #{gettext("Partial results")}: #{build_calculation_results_message(results)}"
          )
      end

    {:noreply, socket}
  end

  def handle_event("calculate_subject", params, socket) do
    %{"grades_report_subject_id" => grades_report_subject_id} = params

    socket =
      GradesReports.calculate_subject_final_grades(
        socket.assigns.students_ids,
        socket.assigns.grades_report.id,
        grades_report_subject_id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("Students final subject grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/grades_reports/#{socket.assigns.grades_report}")

        {:error, _, results} ->
          put_flash(
            socket,
            :error,
            "#{gettext("Something went wrong")}. #{gettext("Partial results")}: #{build_calculation_results_message(results)}"
          )
      end

    {:noreply, socket}
  end

  def handle_event("calculate_cell", params, socket) do
    %{
      "grades_report_subject_id" => grades_report_subject_id,
      "student_id" => student_id
    } = params

    socket =
      GradesReports.calculate_student_final_grade(
        student_id,
        socket.assigns.grades_report.id,
        grades_report_subject_id,
        force_overwrite: true
      )
      |> case do
        {:ok, nil, _} ->
          socket
          |> put_flash(:error, gettext("No subcycle entries for this subject"))
          |> push_navigate(to: ~p"/grades_reports/#{socket.assigns.grades_report}")

        {:ok, _, _} ->
          socket
          |> put_flash(:info, gettext("Grade calculated succesfully"))
          |> push_navigate(to: ~p"/grades_reports/#{socket.assigns.grades_report}")

        {:error, _} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end
end
