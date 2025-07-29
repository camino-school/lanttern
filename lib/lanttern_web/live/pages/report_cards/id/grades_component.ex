defmodule LantternWeb.ReportCardLive.GradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  # live components
  alias LantternWeb.Grading.GradeCompositionOverlayComponent

  # shared
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <.markdown
          :if={@report_card.grading_info || @grades_report.info}
          text={@report_card.grading_info || @grades_report.info}
          class="mb-10"
        />
        <%= if @grades_report do %>
          <.grades_report_grid
            grades_report={@grades_report}
            report_card_cycle_id={@report_card.school_cycle_id}
            on_composition_click={JS.push("edit_composition", target: @myself)}
            title_navigate={~p"/grades_reports/#{@grades_report}"}
          />
        <% else %>
          <.card_base class="p-4">
            <.empty_state>
              {gettext("No grades report linked to this report card.")}
            </.empty_state>
          </.card_base>
        <% end %>
      </.responsive_container>
      <.live_component
        :if={@is_editing_grade_composition}
        title={gettext("Edit grade composition")}
        module={GradeCompositionOverlayComponent}
        id="grade-composition-overlay"
        grades_report_id={@grades_report_id}
        grades_report_cycle_id={@grades_report_cycle_id}
        grades_report_subject_id={@grades_report_subject_id}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}/grades")}
        use_assessment_points_from_report_card_id={@report_card.id}
      />
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
      |> assign_is_editing_grade_composition(assigns)

    {:ok, socket}
  end

  defp assign_is_editing_grade_composition(socket, %{
         params: %{
           "gr_id" => grades_report_id,
           "grc_id" => grades_report_cycle_id,
           "grs_id" => grades_report_subject_id
         }
       }) do
    socket
    |> assign(:is_editing_grade_composition, true)
    |> assign(:grades_report_id, grades_report_id)
    |> assign(:grades_report_cycle_id, grades_report_cycle_id)
    |> assign(:grades_report_subject_id, grades_report_subject_id)
  end

  defp assign_is_editing_grade_composition(socket, _) do
    socket
    |> assign(:is_editing_grade_composition, false)
    |> assign(:grades_report_id, nil)
    |> assign(:grades_report_cycle_id, nil)
    |> assign(:grades_report_subject_id, nil)
  end

  @impl true
  def handle_event("edit_composition", params, socket) do
    url_params = %{
      gr_id: params["gradesreportid"],
      grc_id: params["gradesreportcycleid"],
      grs_id: params["gradesreportsubjectid"]
    }

    socket =
      socket
      |> push_patch(to: ~p"/report_cards/#{socket.assigns.report_card}/grades?#{url_params}")

    {:noreply, socket}
  end
end
