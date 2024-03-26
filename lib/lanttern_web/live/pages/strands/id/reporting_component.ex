defmodule LantternWeb.StrandLive.ReportingComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Reporting
  alias Lanttern.Schools.Student

  import LantternWeb.PersonalizationHelpers

  # shared components
  alias LantternWeb.Assessments.EntryEditorComponent
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10">
      <div class="container mx-auto lg:max-w-5xl">
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <%= gettext("Final strand goals assessment for") %>
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= gettext("Select a class") %>
              </button>
              <%= gettext("to view students assessments") %>
            </p>
          <% end %>
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div :if={@assessment_points_count == 0} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No goals for this strand yet") %></.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={@selected_classes == [] && @assessment_points_count > 0}
          class="p-10 mt-4 rounded shadow-xl bg-white"
        >
          <p class="mb-6 font-bold text-ltrn-subtle"><%= gettext("Strands goals") %></p>
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <li
              :for={{dom_id, {assessment_point, i}} <- @streams.assessment_points}
              id={"no-class-#{dom_id}"}
            >
              <%= "#{i + 1}. #{assessment_point.name}" %>
            </li>
          </ol>
        </div>
      </div>
      <%!-- show entries only with class filter selected --%>
      <div
        :if={@selected_classes != [] && @assessment_points_count > 0}
        class="relative w-full max-h-[calc(100vh-4rem)] mt-6 rounded shadow-xl bg-white overflow-x-auto"
      >
        <div
          class="relative grid w-max"
          style={"grid-template-columns: 240px repeat(#{@assessment_points_count}, minmax(240px, 1fr))"}
        >
          <div
            class="sticky top-0 z-20 grid grid-cols-subgrid bg-white"
            style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
          >
            <div class="sticky left-0 bg-white"></div>
            <div
              id="grid-assessment-points"
              phx-update="stream"
              class="grid grid-cols-subgrid"
              style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
            >
              <.assessment_point
                :for={{dom_id, assessment_point} <- @streams.assessment_points}
                id={dom_id}
                assessment_point={assessment_point}
              />
            </div>
          </div>
          <div
            id="grid-student-entries"
            phx-update="stream"
            class="grid grid-cols-subgrid pb-4 pr-4"
            style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
          >
            <.student_entries
              :for={{dom_id, {student, entries}} <- @streams.students_entries}
              id={dom_id}
              student={student}
              entries={entries}
              scale_ov_map={@scale_ov_map}
            />
          </div>
        </div>
      </div>
      <div class="container py-10 mx-auto lg:max-w-5xl">
        <div class="flex items-end justify-between gap-6">
          <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Report cards") %></h3>
          <.collection_action
            type="button"
            icon_name="hero-plus-circle"
            phx-click="add_to_report"
            phx-target={@myself}
          >
            <%= gettext("Add to report card") %>
          </.collection_action>
        </div>
        <p class="mt-4">
          <%= gettext("List of report cards linked to this strand.") %>
        </p>
        <div id={@id} phx-update="stream" class="grid grid-cols-3 gap-10 mt-12">
          <.report_card_card
            :for={{dom_id, report_card} <- @streams.report_cards}
            id={dom_id}
            report_card={report_card}
            navigate={~p"/report_cards/#{report_card}"}
          />
        </div>
        <.live_component
          module={LantternWeb.Personalization.GlobalFiltersOverlayComponent}
          id="classes-filter-modal"
          current_user={@current_user}
          title={gettext("Select classes for assessment")}
          filter_type={:classes}
          navigate={~p"/strands/#{@strand}?tab=reporting"}
        />
      </div>
    </div>
    """
  end

  # function components

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true

  def assessment_point(assigns) do
    ~H"""
    <div id={@id} class="max-w-80 pt-6 px-2 pb-2 text-sm">
      <div class="flex items-center gap-2 mb-2">
        <.badge>
          <%= @assessment_point.curriculum_item.curriculum_component.name %>
        </.badge>
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
      </div>
      <p class="line-clamp-3" title={@assessment_point.curriculum_item.name}>
        <%= @assessment_point.curriculum_item.name %>
      </p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :student, Student, required: true
  attr :entries, :list, required: true
  attr :scale_ov_map, :map, required: true

  def student_entries(assigns) do
    ~H"""
    <div
      id={@id}
      class="grid grid-cols-subgrid"
      style={"grid-column: span #{length(@entries) + 1} / span #{length(@entries) + 1}"}
    >
      <div class="sticky left-0 z-10 pl-6 py-2 pr-2 bg-white">
        <.profile_icon_with_name profile_name={@student.name} />
      </div>
      <div :for={{entry, assessment_point} <- @entries} class="p-2">
        <.live_component
          module={EntryEditorComponent}
          id={"student-#{@student.id}-entry-for-#{assessment_point.id}"}
          student={@student}
          assessment_point={assessment_point}
          entry={entry}
          class="w-full h-full"
          wrapper_class="w-full h-full"
        >
          <:marking_input class="w-full h-full" />
        </.live_component>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:classes, nil)
      |> assign(:classes_ids, [])
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(
        :report_cards,
        Reporting.list_report_cards(preloads: :school_cycle, strands_ids: [assigns.strand.id])
      )
      |> assign_user_filters([:classes], assigns.current_user)
      |> assign_assessment_points_and_student_entries()

    {:ok, socket}
  end

  defp assign_assessment_points_and_student_entries(socket) do
    %{assigns: %{strand: strand, selected_classes_ids: classes_ids}} = socket

    assessment_points =
      Assessments.list_assessment_points(
        strand_id: strand.id,
        preloads: [
          curriculum_item: :curriculum_component,
          scale: :ordinal_values
        ]
      )

    scale_ov_map =
      assessment_points
      |> Enum.map(& &1.scale)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(fn scale ->
        {
          scale.id,
          scale.ordinal_values
          |> Enum.map(fn ov ->
            {
              ov.id,
              %{
                name: ov.name,
                style: "background-color: #{ov.bg_color}; color: #{ov.text_color}"
              }
            }
          end)
          |> Enum.into(%{})
        }
      end)
      |> Enum.into(%{})

    # zip assessment points with entries
    students_entries =
      Assessments.list_strand_goals_students_entries(strand.id,
        classes_ids: classes_ids
      )
      |> Enum.map(fn {student, entries} ->
        {
          student,
          Enum.zip(entries, assessment_points)
        }
      end)

    socket
    |> stream(:assessment_points, assessment_points)
    |> assign(:assessment_points_count, length(assessment_points))
    |> assign(:scale_ov_map, scale_ov_map)
    |> stream(:students_entries, students_entries)
  end

  # event handlers

  @impl true
  def handle_event("add_to_report", _params, socket) do
    {:noreply, socket}
  end

  # def handle_event("edit_goal", %{"id" => assessment_point_id}, socket) do
  #   assessment_point = Assessments.get_assessment_point(assessment_point_id)

  #   {:noreply,
  #    socket
  #    |> assign(:assessment_point, assessment_point)
  #    |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/goal/edit")}
  # end

  # def handle_event("delete_assessment_point", _params, socket) do
  #   case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
  #     {:ok, _assessment_point} ->
  #       {:noreply,
  #        socket
  #        |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

  #     {:error, _changeset} ->
  #       # we may have more error types, but for now we are handling only this one
  #       message =
  #         gettext("This goal already have some entries. Deleting it will cause data loss.")

  #       {:noreply, socket |> assign(:delete_assessment_point_error, message)}
  #   end
  # end

  # def handle_event("delete_assessment_point_and_entries", _, socket) do
  #   case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
  #     {:ok, _} ->
  #       {:noreply,
  #        socket
  #        |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

  #     {:error, _} ->
  #       {:noreply, socket}
  #   end
  # end

  # def handle_event("dismiss_assessment_point_error", _, socket) do
  #   {:noreply,
  #    socket
  #    |> assign(:delete_assessment_point_error, nil)}
  # end

  # def handle_event("swap_goal_position", %{"from" => i, "to" => j}, socket) do
  #   curriculum_items =
  #     socket.assigns.curriculum_items
  #     |> Enum.map(fn {ap, _i} -> ap end)
  #     |> swap(i, j)
  #     |> Enum.with_index()

  #   {:noreply,
  #    socket
  #    |> assign(:curriculum_items, curriculum_items)
  #    |> assign(:has_goal_position_change, true)}
  # end

  # def handle_event("save_order", _, socket) do
  #   assessment_points_ids =
  #     socket.assigns.curriculum_items
  #     |> Enum.map(fn {ci, _i} -> ci.assessment_point_id end)

  #   case Assessments.update_assessment_points_positions(assessment_points_ids) do
  #     {:ok, _assessment_points} ->
  #       {:noreply, assign(socket, :has_goal_position_change, false)}

  #     {:error, msg} ->
  #       {:noreply, put_flash(socket, :error, msg)}
  #   end
  # end

  # # helpers

  # # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  # defp swap(a, i1, i2) do
  #   e1 = Enum.at(a, i1)
  #   e2 = Enum.at(a, i2)

  #   a
  #   |> List.replace_at(i1, e2)
  #   |> List.replace_at(i2, e1)
  # end
end
