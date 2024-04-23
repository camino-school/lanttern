defmodule LantternWeb.ReportCardLive.StudentsGradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Schools

  # shared
  alias LantternWeb.GradesReports.StudentGradeReportEntryFormComponent
  import LantternWeb.ReportingComponents
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@grades_report} class="py-10">
        <div class="container mx-auto lg:max-w-5xl">
          <h5 class="font-display font-bold text-2xl">
            <%= gettext("Students grades") %>
          </h5>
          <p class="mt-2">
            <%= gettext("View grades reports for all students linked in the students tab.") %>
          </p>
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
          <div class="p-6">
            <.students_grades_grid
              students={@students}
              grades_report_subjects={@grades_report.grades_report_subjects}
              students_grades_map={@students_grades_map}
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
                fn student_grade_report_entry_id ->
                  JS.patch(
                    ~p"/report_cards/#{@report_card}?tab=grades&student_grade_report_entry=#{student_grade_report_entry_id}"
                  )
                end
              }
            />
          </div>
        <% end %>
        <.slide_over
          :if={@is_editing_student_grade_report_entry}
          id="student-grades-report-entry-overlay"
          show={true}
          on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=grades")}
        >
          <:title><%= gettext("Edit student grade report entry") %></:title>
          <.metadata class="mb-4" icon_name="hero-user">
            <%= @student_grade_report_entry.student.name %>
          </.metadata>
          <.metadata class="mb-4" icon_name="hero-bookmark">
            <%= @student_grade_report_entry.grades_report_subject.subject.name %>
          </.metadata>
          <.metadata class="mb-4" icon_name="hero-calendar">
            <%= @student_grade_report_entry.grades_report_cycle.school_cycle.name %>
          </.metadata>
          <.live_component
            module={StudentGradeReportEntryFormComponent}
            id={@student_grade_report_entry.id}
            student_grade_report_entry={@student_grade_report_entry}
            scale_id={@grades_report.scale_id}
            navigate={~p"/report_cards/#{@report_card}?tab=grades"}
            hide_submit
          />
          <div class="py-10">
            <h6 class="font-display font-bold"><%= gettext("Grade composition") %></h6>
            <p class="mt-4 mb-6 text-sm">
              <%= gettext(
                "Lanttern automatic grade calculation info based on configured grade composition"
              ) %> (<%= Timex.local(@student_grade_report_entry.composition_datetime)
              |> Timex.format!("{0D}/{0M}/{YYYY} {h24}:{m}") %>).
            </p>
            <.grade_composition_table student_grade_report_entry={@student_grade_report_entry} />
          </div>
          <:actions_left>
            <.button
              type="button"
              theme="ghost"
              phx-click="delete_student_grade_report_entry"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
            >
              <%= gettext("Delete") %>
            </.button>
          </:actions_left>
          <:actions>
            <.button
              type="button"
              theme="ghost"
              phx-click={JS.exec("data-cancel", to: "#student-grades-report-entry-overlay")}
            >
              <%= gettext("Cancel") %>
            </.button>
            <.button type="submit" form="student-grade-report-entry-form">
              <%= gettext("Save") %>
            </.button>
          </:actions>
        </.slide_over>
        <.live_component
          module={LantternWeb.Personalization.FiltersOverlayComponent}
          id="students-grades-filters"
          current_user={@current_user}
          title={gettext("Students grades filter")}
          filter_type={:classes}
          navigate={~p"/report_cards/#{@report_card}?tab=grades"}
        />
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
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
      |> assign_is_editing_student_grade_report_entry(assigns)
      |> assign_students_grades_grid()

    IO.inspect(socket.assigns.current_grades_report_cycle, label: "current_grades_report_cycle")

    {:ok, socket}
  end

  defp assign_is_editing_student_grade_report_entry(socket, %{
         params: %{"student_grade_report_entry" => student_grade_report_entry_id}
       }) do
    %{current_grades_report_cycle: current_grades_report_cycle} = socket.assigns

    student_grade_report_entry =
      GradesReports.get_student_grade_report_entry!(
        student_grade_report_entry_id,
        preloads: [
          :student,
          :composition_ordinal_value,
          grades_report_subject: :subject,
          grades_report_cycle: :school_cycle
        ]
      )

    case student_grade_report_entry.grades_report_cycle_id == current_grades_report_cycle.id do
      true ->
        socket
        |> assign(:is_editing_student_grade_report_entry, true)
        |> assign(:student_grade_report_entry, student_grade_report_entry)

      _ ->
        assign(socket, :is_editing_student_grade_report_entry, false)
    end
  end

  defp assign_is_editing_student_grade_report_entry(socket, _),
    do: assign(socket, :is_editing_student_grade_report_entry, false)

  defp assign_students_grades_grid(socket) do
    students =
      Schools.list_students(report_card_id: socket.assigns.report_card.id)

    students_grades_map =
      case socket.assigns.grades_report do
        nil ->
          nil

        grades_report ->
          GradesReports.build_students_grades_map(
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
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

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
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

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
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

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
        grades_report_subject_id
      )
      |> case do
        {:ok, nil, _} ->
          socket
          |> put_flash(:error, gettext("No assessment point entries for this grade composition"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

        {:ok, _, _} ->
          socket
          |> put_flash(:info, gettext("Grade calculated succesfully"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

        {:error, _} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end

  def handle_event("delete_student_grade_report_entry", _params, socket) do
    case GradesReports.delete_student_grade_report_entry(
           socket.assigns.student_grade_report_entry
         ) do
      {:ok, _student_grade_report_entry} ->
        socket =
          socket
          |> put_flash(:info, gettext("Student grade report entry deleted"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting student grade report entry"))

        {:noreply, socket}
    end
  end

  # helper

  defp build_calculation_results_message(%{} = results),
    do: build_calculation_results_message(Enum.map(results, & &1), [])

  defp build_calculation_results_message([], msgs),
    do: Enum.join(msgs, ", ")

  defp build_calculation_results_message([{_operation, 0} | results], msgs),
    do: build_calculation_results_message(results, msgs)

  defp build_calculation_results_message([{:created, count} | results], msgs) do
    msg = ngettext("1 grade created", "%{count} grades created", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:updated, count} | results], msgs) do
    msg = ngettext("1 grade updated", "%{count} grades updated", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:deleted, count} | results], msgs) do
    msg = ngettext("1 grade removed", "%{count} grades removed", count)
    build_calculation_results_message(results, [msg | msgs])
  end

  defp build_calculation_results_message([{:noop, count} | results], msgs) do
    msg =
      ngettext(
        "1 grade calculation skipped (no assessment point entries)",
        "%{count} grades skipped (no assessment point entries)",
        count
      )

    build_calculation_results_message(results, [msg | msgs])
  end
end
