defmodule LantternWeb.ReportCardLive.GradesComponent do
  alias Lanttern.Reporting.GradesReport
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  # shared
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <div class="container mx-auto lg:max-w-5xl">
        <div class="p-4 rounded mt-4 bg-white shadow-lg">
          <%= if @grades_report do %>
            <h3 class="mb-4 font-display font-bold text-2xl">
              <%= gettext("Grades report grid") %>: <%= @grades_report.name %>
            </h3>
            <.grades_report_grid
              grades_report={@grades_report}
              report_card_cycle_id={@report_card.school_cycle_id}
              on_composition_click={JS.push("edit_subject_grade_composition", target: @myself)}
            />
          <% else %>
            <h3 class="mb-4 font-display font-bold text-2xl">
              <%= gettext("Grades report grid") %>
            </h3>
            <.empty_state>
              <%= gettext("No grades report linked to this report card.") %>
            </.empty_state>
          <% end %>
        </div>
      </div>
      <.slide_over
        :if={@is_editing_grade_composition}
        id="report-card-grade-composition-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=grades")}
      >
        <:title><%= gettext("Edit grade composition") %></:title>
        <%= if length(@grade_composition) == 0 do %>
          <.empty_state>
            <%= gettext("No assesment points in this grade composition") %>
          </.empty_state>
        <% else %>
          <div
            :for={grade_component <- @grade_composition}
            id={"report-card-grade-component-#{grade_component.id}"}
            class="flex items-center gap-4 p-4 rounded mt-4 bg-white shadow-lg"
          >
            <div class="flex-1">
              <p class="text-xs">
                <%= grade_component.assessment_point.strand.name %>
                <span :if={grade_component.assessment_point.strand.type}>
                  (<%= grade_component.assessment_point.strand.type %>)
                </span>
              </p>
              <p class="mt-2 text-sm">
                <.badge>
                  <%= grade_component.assessment_point.curriculum_item.curriculum_component.name %>
                </.badge>
                <%= grade_component.assessment_point.curriculum_item.name %>
              </p>
            </div>
            <.button
              type="button"
              theme="ghost"
              phx-click={
                JS.push("delete_grade_component_from_composition",
                  value: %{id: grade_component.id},
                  target: @myself
                )
              }
            >
              Remove
            </.button>
          </div>
        <% end %>
        <h5 class="mt-10 font-display font-bold">
          <%= gettext("All report card assessment points") %>
        </h5>
        <div
          :for={assessment_point <- @assessment_points}
          id={"report-card-assessment-point-#{assessment_point.id}"}
          class="flex items-center gap-4 p-4 rounded mt-4 bg-white shadow-lg"
        >
          <div class="flex-1">
            <p class="text-xs">
              <%= assessment_point.strand.name %>
              <span :if={assessment_point.strand.type}>
                (<%= assessment_point.strand.type %>)
              </span>
            </p>
            <p class="mt-2 text-sm">
              <.badge><%= assessment_point.curriculum_item.curriculum_component.name %></.badge>
              <%= assessment_point.curriculum_item.name %>
            </p>
          </div>
          <.button
            type="button"
            theme="ghost"
            phx-click={
              JS.push("add_assessment_point_to_grade_comp",
                value: %{id: assessment_point.id},
                target: @myself
              )
            }
          >
            Add
          </.button>
        </div>
      </.slide_over>
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
          id -> Reporting.get_grades_report(id, load_grid: true)
        end
      end)
      |> assign_is_editing_grade_composition(assigns)

    {:ok, socket}
  end

  defp assign_is_editing_grade_composition(socket, %{
         params: %{"is_editing_grade_composition" => subject_id}
       }) do
    with %{grades_report: %GradesReport{} = grades_report} <- socket.assigns do
      grades_report_subjects = grades_report.grades_report_subjects
      subjects_ids = Enum.map(grades_report_subjects, &"#{&1.subject_id}")

      case subject_id in subjects_ids do
        true ->
          socket
          |> assign(:is_editing_grade_composition, true)
          |> assign_new(:assessment_points, fn ->
            Reporting.list_report_card_assessment_points(socket.assigns.report_card.id)
          end)
          |> assign(
            :grade_composition,
            Reporting.list_report_card_subject_grade_composition(
              socket.assigns.report_card.id,
              subject_id
            )
          )

        _ ->
          assign(socket, :is_editing_grade_composition, false)
      end
    else
      _ -> assign(socket, :is_editing_grade_composition, false)
    end
  end

  defp assign_is_editing_grade_composition(socket, _),
    do: assign(socket, :is_editing_grade_composition, false)

  @impl true
  def handle_event("edit_subject_grade_composition", %{"subjectid" => subject_id}, socket) do
    socket =
      socket
      |> push_patch(
        to:
          ~p"/report_cards/#{socket.assigns.report_card}?tab=grades&is_editing_grade_composition=#{subject_id}"
      )

    {:noreply, socket}
  end

  def handle_event("add_assessment_point_to_grade_comp", %{"id" => id}, socket) do
    subject_id = socket.assigns.params["is_editing_grade_composition"]

    %{
      report_card_id: socket.assigns.report_card.id,
      assessment_point_id: id,
      subject_id: subject_id
    }
    |> Reporting.create_grade_component()
    |> case do
      {:ok, _grade_component} ->
        socket =
          socket
          |> assign(
            :grade_composition,
            Reporting.list_report_card_subject_grade_composition(
              socket.assigns.report_card.id,
              subject_id
            )
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_grade_component_from_composition", %{"id" => id}, socket) do
    socket.assigns.grade_composition
    |> Enum.find(&(&1.id == id))
    |> Reporting.delete_grade_component()
    |> case do
      {:ok, _grade_component} ->
        socket =
          socket
          |> update(
            :grade_composition,
            &Enum.filter(&1, fn gc -> gc.id != id end)
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end
