defmodule LantternWeb.StudentLive do
  alias Lanttern.GradesReports
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Schools

  # shared components
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.FinalGradeDetailsOverlayComponent
  import LantternWeb.GradesReportsComponents
  import LantternWeb.ReportingComponents

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      case Schools.get_student(params["id"], preloads: [classes: [:cycle, :years]]) do
        student
        when is_nil(student) or
               student.school_id != socket.assigns.current_user.current_profile.school_id ->
          socket
          |> put_flash(:error, "Couldn't find student")
          |> redirect(to: ~p"/school")

        student ->
          socket
          |> assign(:student_id, student.id)
          |> assign(:student_name, student.name)
          |> stream(:classes, student.classes)
          |> assign(:page_title, student.name)
      end
      |> stream_student_report_cards()
      |> stream_grades_reports()

    {:ok, socket, temporary_assigns: [student_grades_maps: %{}]}
  end

  defp stream_student_report_cards(socket) do
    student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.student_id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    socket
    |> stream(:student_report_cards, student_report_cards)
    |> assign(:has_student_report_cards, student_report_cards != [])
  end

  defp stream_grades_reports(socket) do
    student_id = socket.assigns.student_id

    grades_reports =
      GradesReports.list_student_grades_reports_grids(student_id)

    grades_reports_ids = Enum.map(grades_reports, & &1.id)

    student_grades_maps =
      GradesReports.build_student_grades_maps(student_id, grades_reports_ids)

    student_grades_report_entries_ids =
      student_grades_maps
      |> Enum.map(fn {_, cycle_and_subjects_map} -> cycle_and_subjects_map end)
      |> Enum.flat_map(&Enum.map(&1, fn {_, subjects_entries_map} -> subjects_entries_map end))
      |> Enum.flat_map(&Enum.map(&1, fn {_, entry} -> entry && entry.id end))
      |> Enum.filter(&Function.identity/1)

    student_grades_report_final_entries_ids =
      student_grades_maps
      |> Enum.map(fn {_, cycle_and_subjects_map} -> cycle_and_subjects_map[:final] end)
      |> Enum.flat_map(&Enum.map(&1, fn {_, entry} -> entry && entry.id end))
      |> Enum.filter(&Function.identity/1)

    socket
    |> stream(:grades_reports, grades_reports)
    |> assign(:has_grades_reports, grades_reports != [])
    |> assign(:student_grades_maps, student_grades_maps)
    |> assign(:student_grades_report_entries_ids, student_grades_report_entries_ids)
    |> assign(:student_grades_report_final_entries_ids, student_grades_report_final_entries_ids)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {sgre_id, sgrfe_id} =
      case params do
        %{"student_grades_report_entry_id" => sgre_id} ->
          sgre_id = String.to_integer(sgre_id)
          # guard against user manipulated ids
          if sgre_id in socket.assigns.student_grades_report_entries_ids,
            do: {sgre_id, nil},
            else: {nil, nil}

        %{"student_grades_report_final_entry_id" => sgrfe_id} ->
          sgrfe_id = String.to_integer(sgrfe_id)
          # guard against user manipulated ids
          if sgrfe_id in socket.assigns.student_grades_report_final_entries_ids,
            do: {nil, sgrfe_id},
            else: {nil, nil}

        _ ->
          {nil, nil}
      end

    socket =
      socket
      |> assign(:student_grades_report_entry_id, sgre_id)
      |> assign(:student_grades_report_final_entry_id, sgrfe_id)

    {:noreply, socket}
  end
end
