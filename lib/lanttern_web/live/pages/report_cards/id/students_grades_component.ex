defmodule LantternWeb.ReportCardLive.StudentsGradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Reporting

  import LantternWeb.FiltersHelpers,
    only: [
      assign_report_card_linked_student_classes_filter: 2,
      save_profile_filters: 3
    ]

  import LantternWeb.GradesReportsHelpers, only: [build_calculation_results_message: 1]

  # shared
  alias LantternWeb.GradesReports.StudentGradesReportEntryOverlayComponent
  import LantternWeb.GradesReportsComponents
  alias LantternWeb.Filters.InlineFiltersComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@grades_report}>
        <div class="container mx-auto lg:max-w-5xl">
          <h5 class="font-display font-bold text-2xl">
            <%= gettext("Students grades") %>
          </h5>
          <p class="mt-2">
            <%= gettext("View grades reports for all students linked in the students tab.") %>
          </p>
          <.live_component
            module={InlineFiltersComponent}
            id="linked-students-grades-classes-filter"
            filter_items={@linked_students_classes}
            selected_items_ids={@selected_linked_students_classes_ids}
            class="mt-4"
            notify_component={@myself}
          />
        </div>
        <%= if @students == [] do %>
          <div class="container mx-auto mt-4 lg:max-w-5xl">
            <div class="p-10 rounded shadow-xl bg-white">
              <.empty_state>
                <%= gettext("Add students to report card to view grades") %>
              </.empty_state>
            </div>
          </div>
        <% else %>
          <.students_grades_grid
            class="mt-6"
            students={@students}
            grades_report_subjects={@grades_report.grades_report_subjects}
            students_grades_map={@students_grades_map}
            student_navigate={fn student -> ~p"/school/students/#{student}/grades_reports" end}
            on_calculate_cycle={fn -> JS.push("calculate_cycle", target: @myself) end}
            on_calculate_student={
              fn student_id ->
                JS.push("calculate_student",
                  value: %{student_id: student_id},
                  target: @myself
                )
              end
            }
            on_calculate_subject={
              fn grades_report_subject_id ->
                JS.push("calculate_subject",
                  value: %{grades_report_subject_id: grades_report_subject_id},
                  target: @myself
                )
              end
            }
            on_calculate_cell={
              fn student_id, grades_report_subject_id ->
                JS.push("calculate_cell",
                  value: %{
                    student_id: student_id,
                    grades_report_subject_id: grades_report_subject_id
                  },
                  target: @myself
                )
              end
            }
            on_entry_click={
              fn student_grades_report_entry_id ->
                JS.patch(
                  ~p"/report_cards/#{@report_card}/grades?student_grades_report_entry=#{student_grades_report_entry_id}"
                )
              end
            }
          />
        <% end %>
        <.live_component
          :if={@is_editing_student_grades_report_entry}
          module={StudentGradesReportEntryOverlayComponent}
          id={@student_grades_report_entry.id}
          student_grades_report_entry={@student_grades_report_entry}
          scale_id={@grades_report.scale_id}
          navigate={~p"/report_cards/#{@report_card}/grades"}
          on_cancel={JS.patch(~p"/report_cards/#{@report_card}/grades")}
        />
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{action: {InlineFiltersComponent, {:apply, classes_ids}}}, socket) do
    socket =
      socket
      |> assign(:selected_linked_students_classes_ids, classes_ids)
      |> save_profile_filters(
        [:linked_students_classes],
        report_card_id: socket.assigns.report_card.id
      )
      |> assign_students_grades_grid()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_report_card_linked_student_classes_filter(assigns.report_card)
      |> assign_new(:grades_report, fn %{report_card: report_card} ->
        case report_card.grades_report_id do
          nil -> nil
          id -> GradesReports.get_grades_report(id, load_grid: true)
        end
      end)
      |> assign_new(:current_grades_report_cycle, fn
        %{grades_report: nil} ->
          nil

        %{report_card: report_card, grades_report: grades_report} ->
          grades_report.grades_report_cycles
          |> Enum.find(&(&1.school_cycle_id == report_card.school_cycle_id))
      end)
      |> assign_is_editing_student_grades_report_entry(assigns)
      |> assign_students_grades_grid()

    {:ok, socket}
  end

  defp assign_is_editing_student_grades_report_entry(socket, %{
         params: %{"student_grades_report_entry" => student_grades_report_entry_id}
       }) do
    %{current_grades_report_cycle: current_grades_report_cycle} = socket.assigns

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

    case student_grades_report_entry.grades_report_cycle_id == current_grades_report_cycle.id do
      true ->
        socket
        |> assign(:is_editing_student_grades_report_entry, true)
        |> assign(:student_grades_report_entry, student_grades_report_entry)

      _ ->
        assign(socket, :is_editing_student_grades_report_entry, false)
    end
  end

  defp assign_is_editing_student_grades_report_entry(socket, _),
    do: assign(socket, :is_editing_student_grades_report_entry, false)

  defp assign_students_grades_grid(socket) do
    students =
      Reporting.list_students_linked_to_report_card(
        socket.assigns.report_card,
        classes_ids: socket.assigns.selected_linked_students_classes_ids,
        students_only: true
      )

    students_grades_map =
      case socket.assigns.grades_report do
        nil ->
          nil

        grades_report ->
          GradesReports.build_students_grades_cycle_map(
            Enum.map(students, & &1.id),
            grades_report.id,
            socket.assigns.report_card.school_cycle_id
          )
      end

    socket
    |> assign(:students, students)
    |> assign(:students_grades_map, students_grades_map)
  end

  @impl true
  def handle_event("calculate_cycle", _params, socket) do
    students_ids =
      socket.assigns.students
      |> Enum.map(& &1.id)

    socket =
      GradesReports.calculate_cycle_grades(
        students_ids,
        socket.assigns.grades_report.id,
        socket.assigns.current_grades_report_cycle.id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("Grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/grades")

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
    %{
      "student_id" => student_id
    } = params

    socket =
      GradesReports.calculate_student_grades(
        student_id,
        socket.assigns.grades_report.id,
        socket.assigns.current_grades_report_cycle.id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("Student grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/grades")

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
    %{
      "grades_report_subject_id" => grades_report_subject_id
    } = params

    students_ids =
      socket.assigns.students
      |> Enum.map(& &1.id)

    socket =
      GradesReports.calculate_subject_grades(
        students_ids,
        socket.assigns.grades_report.id,
        socket.assigns.current_grades_report_cycle.id,
        grades_report_subject_id
      )
      |> case do
        {:ok, results} ->
          socket
          |> put_flash(
            :info,
            "#{gettext("Subject grades calculated succesfully")}. #{build_calculation_results_message(results)}"
          )
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/grades")

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
      GradesReports.calculate_student_grade(
        student_id,
        socket.assigns.grades_report.id,
        socket.assigns.current_grades_report_cycle.id,
        grades_report_subject_id,
        force_overwrite: true
      )
      |> case do
        {:ok, nil, _} ->
          socket
          |> put_flash(:error, gettext("No assessment point entries for this grade composition"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/grades")

        {:ok, _, _} ->
          socket
          |> put_flash(:info, gettext("Grade calculated succesfully"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}/grades")

        {:error, _} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end
end
