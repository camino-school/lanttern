defmodule LantternWeb.ReportCardLive.GradesComponent do
  alias Lanttern.Reporting.GradesReport
  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Reporting
  alias Lanttern.Reporting.GradeComponent
  alias Lanttern.Schools

  import Lanttern.Utils, only: [swap: 3]
  import LantternWeb.PersonalizationHelpers

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
            <.empty_state>
              <%= gettext("No grades report linked to this report card.") %>
            </.empty_state>
          <% end %>
        </div>
      </div>
      <div :if={@grades_report}>
        <div class="container mx-auto lg:max-w-5xl mt-10">
          <p class="font-display font-bold text-2xl">
            <%= gettext("Viewing") %>
            <button
              type="button"
              class="inline text-left underline hover:text-ltrn-subtle"
              phx-click={JS.exec("data-show", to: "#global-filters")}
            >
              <%= if length(@selected_classes) > 0 do
                @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ")
              else
                gettext("all classes")
              end %>
            </button>
          </p>
        </div>
        <div>
          <.student_grades_grid
            students={@students}
            grades_report_subjects={@grades_report.grades_report_subjects}
            students_grades_map={@students_grades_map}
            on_calculate_student={
              fn student_id ->
                JS.push("calculate_student",
                  value: %{student_id: student_id},
                  target: @myself
                )
              end
            }
            on_calculate_cell={
              fn student_id, grades_report_subject_id ->
                JS.push("calculate_cell",
                  value: %{student_id: student_id, grades_report_subject_id: grades_report_subject_id},
                  target: @myself
                )
              end
            }
          />
        </div>
      </div>
      <.slide_over
        :if={@is_editing_grade_composition}
        id="report-card-grade-composition-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=grades")}
      >
        <:title><%= gettext("Edit grade composition") %></:title>
        <%= if length(@indexed_grade_components) == 0 do %>
          <.empty_state>
            <%= gettext("No assesment points in this grade composition") %>
          </.empty_state>
        <% else %>
          <div class="grid grid-cols-[minmax(0,_1fr)_repeat(2,_max-content)] gap-x-4 gap-y-2">
            <div class="grid grid-cols-subgrid col-span-3 px-4 py-2 rounded mt-4 text-sm text-ltrn-subtle bg-ltrn-lighter">
              <div><%= gettext("Strand goal") %></div>
              <div class="text-right"><%= gettext("Weight") %></div>
            </div>
            <.grade_component_form
              :for={{grade_component, i} <- @indexed_grade_components}
              id={"report-card-grade-component-#{grade_component.id}"}
              grade_component={grade_component}
              myself={@myself}
              index={i}
              is_last={i + 1 == length(@indexed_grade_components)}
            />
          </div>
        <% end %>
        <h5 class="mt-10 font-display font-bold">
          <%= gettext("All report card strands' goals") %>
        </h5>
        <%= for assessment_point <- @assessment_points, assessment_point.id not in @grade_composition_assessment_point_ids do %>
          <div
            id={"report-card-assessment-point-#{assessment_point.id}"}
            class="flex items-center gap-4 p-4 rounded mt-2 bg-white shadow-lg"
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
            <.icon_button
              type="button"
              theme="ghost"
              name="hero-plus"
              phx-click={
                JS.push("add_assessment_point_to_grade_comp",
                  value: %{id: assessment_point.id},
                  target: @myself
                )
              }
              sr_text={gettext("Add to grade composition")}
              rounded
            />
          </div>
        <% end %>
      </.slide_over>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :grade_component, GradeComponent, required: true
  attr :index, :integer, required: true
  attr :is_last, :boolean, required: true
  attr :myself, :any, required: true

  def grade_component_form(assigns) do
    form =
      assigns.grade_component
      |> GradeComponent.changeset(%{})
      |> to_form()

    assigns =
      assigns
      |> assign(:form, form)

    ~H"""
    <.form
      id={@id}
      for={@form}
      class="grid grid-cols-subgrid col-span-3 items-center p-4 rounded bg-white shadow-lg"
      phx-change={JS.push("update_grade_component", target: @myself)}
      phx-value-id={@grade_component.id}
    >
      <div>
        <p class="text-xs">
          <%= @grade_component.assessment_point.strand.name %>
          <span :if={@grade_component.assessment_point.strand.type}>
            (<%= @grade_component.assessment_point.strand.type %>)
          </span>
        </p>
        <p class="mt-2 text-sm">
          <.badge>
            <%= @grade_component.assessment_point.curriculum_item.curriculum_component.name %>
          </.badge>
          <%= @grade_component.assessment_point.curriculum_item.name %>
        </p>
      </div>
      <input
        type="number"
        name={@form[:weight].name}
        value={@form[:weight].value}
        step="0.01"
        min="0"
        phx-debounce="1500"
        class="w-20 rounded-sm border-none text-right text-sm bg-ltrn-lightest"
      />
      <div class="flex flex-col items-center gap-1">
        <.icon_button
          type="button"
          sr_text={gettext("Move up")}
          name="hero-chevron-up-mini"
          theme="ghost"
          rounded
          size="sm"
          phx-click={
            JS.push("swap_grade_components_position",
              value: %{from: @index, to: @index - 1},
              target: @myself
            )
          }
          disabled={@index == 0}
        />
        <.icon_button
          type="button"
          theme="ghost"
          name="hero-x-mark"
          phx-click={
            JS.push("delete_grade_component_from_composition",
              value: %{id: @grade_component.id},
              target: @myself
            )
          }
          sr_text={gettext("Remove")}
          rounded
        />
        <.icon_button
          type="button"
          sr_text={gettext("Move down")}
          name="hero-chevron-down-mini"
          theme="ghost"
          rounded
          size="sm"
          phx-click={
            JS.push("swap_grade_components_position",
              value: %{from: @index, to: @index + 1},
              target: @myself
            )
          }
          disabled={@is_last}
        />
      </div>
    </.form>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:indexed_grade_components, [])
      |> assign(:grade_composition_assessment_point_ids, [])

    {:ok, socket}
  end

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
      |> assign_new(:current_grades_report_cycle, fn
        %{grades_report: nil} ->
          nil

        %{report_card: report_card, grades_report: grades_report} ->
          grades_report.grades_report_cycles
          |> Enum.find(&(&1.school_cycle_id == report_card.school_cycle_id))
      end)
      |> assign_is_editing_grade_composition(assigns)
      |> assign_user_filters([:classes], assigns.current_user)
      |> assign_students_grades_grid()

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
          grade_components =
            Reporting.list_report_card_subject_grade_composition(
              socket.assigns.report_card.id,
              subject_id
            )

          socket
          |> assign(:is_editing_grade_composition, true)
          |> assign_new(:assessment_points, fn ->
            Reporting.list_report_card_assessment_points(socket.assigns.report_card.id)
          end)
          |> assign(:indexed_grade_components, Enum.with_index(grade_components))
          |> assign(
            :grade_composition_assessment_point_ids,
            Enum.map(grade_components, & &1.assessment_point_id)
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

  defp assign_students_grades_grid(socket) do
    students =
      Schools.list_students(classes_ids: socket.assigns.selected_classes_ids)

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
        grade_components =
          Reporting.list_report_card_subject_grade_composition(
            socket.assigns.report_card.id,
            subject_id
          )

        socket =
          socket
          |> assign(:indexed_grade_components, Enum.with_index(grade_components))
          |> assign(
            :grade_composition_assessment_point_ids,
            Enum.map(grade_components, & &1.assessment_point_id)
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("update_grade_component", %{"id" => id, "grade_component" => params}, socket) do
    socket.assigns.indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component end)
    |> Enum.find(&("#{&1.id}" == id))
    |> Reporting.update_grade_component(params)
    |> case do
      {:ok, _grades_component} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, gettext("Error updating grades report cycle weight"))}
    end
  end

  def handle_event("delete_grade_component_from_composition", %{"id" => id}, socket) do
    socket.assigns.indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component end)
    |> Enum.find(&(&1.id == id))
    |> Reporting.delete_grade_component()
    |> case do
      {:ok, _grade_component} ->
        indexed_grade_components =
          socket.assigns.indexed_grade_components
          |> Enum.map(fn {grade_component, _i} -> grade_component end)
          |> Enum.filter(&(&1.id != id))
          |> Enum.with_index()

        socket =
          socket
          |> assign(:indexed_grade_components, indexed_grade_components)
          |> assign(
            :grade_composition_assessment_point_ids,
            Enum.map(indexed_grade_components, fn {grade_component, _i} ->
              grade_component.assessment_point_id
            end)
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("swap_grade_components_position", %{"from" => i, "to" => j}, socket) do
    indexed_grade_components =
      socket.assigns.indexed_grade_components
      |> Enum.map(fn {grade_component, _i} -> grade_component end)
      |> swap(i, j)
      |> Enum.with_index()

    indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component.id end)
    |> Reporting.update_grade_components_positions()
    |> case do
      :ok ->
        socket =
          socket
          |> assign(:indexed_grade_components, indexed_grade_components)

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
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
        {:ok, _} ->
          socket
          |> put_flash(:info, gettext("Grades calculated succesfully"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

        {:error, _} ->
          put_flash(socket, :error, gettext("Something went wrong"))
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
        {:ok, _} ->
          socket
          |> put_flash(:info, gettext("Grade calculated succesfully"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

        {:error, _} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end
end
