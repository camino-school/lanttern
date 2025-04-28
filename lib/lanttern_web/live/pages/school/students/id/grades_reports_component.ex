defmodule LantternWeb.StudentLive.GradesReportsComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  # shared components
  alias LantternWeb.GradesReports.FinalGradeDetailsOverlayComponent
  alias LantternWeb.GradesReports.GradeDetailsOverlayComponent
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @has_grades_reports do %>
        <div phx-update="stream" id="grades-report-grid">
          <.grades_report_grid
            :for={{dom_id, grades_report} <- @streams.grades_reports}
            id={dom_id}
            grades_report={grades_report}
            student_grades_map={@student_grades_maps[grades_report.id]}
            on_student_grade_click={
              fn id ->
                JS.patch(
                  ~p"/school/students/#{@student}/grades_reports?student_grades_report_entry_id=#{id}"
                )
              end
            }
            on_student_final_grade_click={
              fn id ->
                JS.patch(
                  ~p"/school/students/#{@student}/grades_reports?student_grades_report_final_entry_id=#{id}"
                )
              end
            }
            title_navigate={~p"/grades_reports/#{grades_report}"}
            class="mt-4"
          />
        </div>
      <% else %>
        <.empty_state><%= gettext("No grades report linked to student") %></.empty_state>
      <% end %>
      <.live_component
        :if={@student_grades_report_entry_id}
        module={GradeDetailsOverlayComponent}
        id="grade-details-overlay-component-overlay"
        student_grades_report_entry_id={@student_grades_report_entry_id}
        on_cancel={JS.patch(~p"/school/students/#{@student}/grades_reports")}
      />
      <.live_component
        :if={@student_grades_report_final_entry_id}
        module={FinalGradeDetailsOverlayComponent}
        id="final-grade-details-overlay-component-overlay"
        student_grades_report_final_entry_id={@student_grades_report_final_entry_id}
        on_cancel={JS.patch(~p"/school/students/#{@student}/grades_reports")}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_student_grades_report_entry()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_grades_reports()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_grades_reports(socket) do
    student_id = socket.assigns.student.id

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

  defp assign_student_grades_report_entry(
         %{assigns: %{params: %{"student_grades_report_entry_id" => sgre_id}}} = socket
       ) do
    sgre_id = String.to_integer(sgre_id)

    # guard against user manipulated ids
    sgre_id =
      if sgre_id in socket.assigns.student_grades_report_entries_ids,
        do: sgre_id

    socket
    |> assign(:student_grades_report_entry_id, sgre_id)
    |> assign(:student_grades_report_final_entry_id, nil)
  end

  defp assign_student_grades_report_entry(
         %{
           assigns: %{
             params: %{
               "student_grades_report_final_entry_id" => sgrfe_id
             }
           }
         } = socket
       ) do
    sgrfe_id = String.to_integer(sgrfe_id)

    # guard against user manipulated ids
    sgrfe_id =
      if sgrfe_id in socket.assigns.student_grades_report_final_entries_ids,
        do: sgrfe_id

    socket
    |> assign(:student_grades_report_entry_id, nil)
    |> assign(:student_grades_report_final_entry_id, sgrfe_id)
  end

  defp assign_student_grades_report_entry(socket) do
    socket
    |> assign(:student_grades_report_entry_id, nil)
    |> assign(:student_grades_report_final_entry_id, nil)
  end
end
