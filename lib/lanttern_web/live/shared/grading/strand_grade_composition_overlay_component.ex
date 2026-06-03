defmodule LantternWeb.Grading.StrandGradeCompositionOverlayComponent do
  @moduledoc """
  Modal for setting up or managing a strand's grade composition.

  A strand grade composition is always **average-based**: the grade for a
  (grades report cycle × subject) pair is a weighted average of the selected
  strand goals.

  Has two internal views:
  - `:overview` — shows the current composition state (placeholder or component list)
  - `:setup` — shows the strand goals checklist for selecting which goals contribute

  Only **strand goals** (assessment points without a linked moment) are eligible
  components. The composition cannot be deleted — emptying the selection and
  saving clears it.

  Navigates between views without closing the modal. Persists via
  `Lanttern.Grading.replace_grade_composition/3`.
  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [format_float: 1]

  alias Lanttern.Assessments
  alias Lanttern.GradesReports
  alias Lanttern.Grading

  @goal_preloads [curriculum_item: :curriculum_component]

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{gettext("Grade composition")}</:title>
        <%= if @view == :overview do %>
          <div class="flex items-start justify-between gap-6">
            <div>
              <p class="font-bold text-ltrn-darkest">
                {@cycle_name}, {@subject_name}
              </p>
              <p class="font-display font-bold text-ltrn-subtle">
                {gettext("Average-based grade composition")}
              </p>
            </div>
            <.button
              type="button"
              theme={if @composition_components == [], do: "primary"}
              phx-click="show_setup"
              phx-target={@myself}
              class="shrink-0"
            >
              {if @composition_components == [],
                do: gettext("Setup composition"),
                else: gettext("Manage composition")}
            </.button>
          </div>
          <%= if @composition_components == [] do %>
            <div class="mt-6 p-4 rounded-sm border border-dashed border-ltrn-lighter text-center text-sm text-ltrn-subtle">
              {gettext("Grade composition not setup yet")}
            </div>
          <% else %>
            <div class="mt-6">
              <div class="flex items-center font-sans text-sm text-ltrn-subtle">
                <div class="flex-1">{gettext("Strand goal")}</div>
                <div>{gettext("Weight")}</div>
              </div>
              <div
                :for={comp <- @composition_components}
                class="flex items-center gap-6 mt-4"
              >
                <span class="truncate">{goal_display_name(comp.assessment_point)}</span>
                <span class="flex-1 border-b border-ltrn-lighter" />
                <span class="shrink-0 tabular-nums">{comp.weight}</span>
              </div>
              <div class="flex items-center gap-12 font-bold mt-4">
                <span class="flex-1 truncate">{gettext("Total weight")}</span>
                <span class="shrink-0 tabular-nums">
                  {composition_total(@composition_components)}
                </span>
              </div>
            </div>
          <% end %>
        <% else %>
          <p class="font-display font-bold text-ltrn-subtle mb-4">
            {gettext("Average-based grade composition")}
          </p>
          <p>{gettext("Select the strand goals that will be part of the grade composition")}</p>
          <div class="flex items-center px-4 mt-10 mb-2 font-sans text-sm text-ltrn-subtle">
            <div class="flex-1">{gettext("Strand goal")}</div>
            <div>{gettext("Weight")}</div>
          </div>
          <.card_base
            :for={goal <- @strand_goals}
            id={"comp-goal-#{goal.id}"}
            class="flex items-center gap-4 p-4 mt-2"
            bg_class={if(goal.id in @selected_ids, do: nil, else: "bg-ltrn-lightest")}
            remove_shadow={goal.id not in @selected_ids}
          >
            <label class="flex items-center gap-4 flex-1 min-w-0">
              <input
                type="checkbox"
                checked={goal.id in @selected_ids}
                phx-click={JS.push("toggle_ap", value: %{id: goal.id}, target: @myself)}
                class="appearance-none rounded-xs size-5 border-2 border-ltrn-subtle checked:border-ltrn-primary checked:bg-ltrn-primary indeterminate:border-ltrn-dark indeterminate:bg-ltrn-dark focus:outline-2 focus:outline-offset-2 focus:outline-ltrn-primary disabled:opacity-50 forced-colors:appearance-auto"
              />
              <div class="flex-1 min-w-0">
                <p>{goal_display_name(goal)}</p>
              </div>
            </label>
            <div class="w-16 text-right shrink-0">
              <form
                :if={goal.id in @selected_ids}
                phx-change="update_weight"
                phx-target={@myself}
              >
                <input type="hidden" name="ap_id" value={goal.id} />
                <input
                  type="number"
                  name="weight"
                  value={Map.get(@weights_map, goal.id, 1.0)}
                  step="0.01"
                  min="0.01"
                  phx-debounce="500"
                  class="w-16 rounded-xs border-none text-right text-sm bg-ltrn-lightest"
                />
              </form>
            </div>
          </.card_base>
          <div class="flex items-center justify-end gap-2 mt-6">
            <.button
              type="button"
              theme="ghost"
              phx-click="back_to_overview"
              phx-target={@myself}
            >
              {gettext("Cancel")}
            </.button>
            <.button
              type="button"
              theme="primary"
              phx-click="save_composition"
              phx-target={@myself}
            >
              {gettext("Save")}
            </.button>
          </div>
        <% end %>
      </.modal>
    </div>
    """
  end

  defp goal_display_name(ap),
    do: "(#{ap.curriculum_item.curriculum_component.name}) #{ap.curriculum_item.name}"

  defp composition_total(components) do
    components
    |> Enum.reduce(0.0, fn comp, acc -> acc + comp.weight end)
    |> format_float()
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:view, :overview)
      |> assign(:composition_components, [])
      |> assign(:strand_goals, [])
      |> assign(:selected_ids, MapSet.new())
      |> assign(:weights_map, %{})

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    composition_components =
      GradesReports.list_grade_composition(
        assigns.grades_report_cycle_id,
        assigns.grades_report_subject_id
      )

    initial_view = Map.get(assigns, :initial_view, :overview)

    socket =
      socket
      |> assign(assigns)
      |> assign(:view, initial_view)
      |> assign(:composition_components, composition_components)
      |> maybe_load_strand_goals()

    {:ok, socket}
  end

  defp maybe_load_strand_goals(%{assigns: %{view: :setup}} = socket),
    do: load_strand_goals(socket)

  defp maybe_load_strand_goals(socket), do: socket

  defp load_strand_goals(socket) do
    strand_goals =
      Assessments.list_assessment_points(
        strand_id: socket.assigns.strand_id,
        preloads: @goal_preloads
      )

    existing = socket.assigns.composition_components

    selected_ids =
      existing
      |> Enum.map(& &1.assessment_point_id)
      |> MapSet.new()

    weights_map =
      existing
      |> Enum.map(&{&1.assessment_point_id, &1.weight})
      |> Enum.into(%{})

    socket
    |> assign(:strand_goals, strand_goals)
    |> assign(:selected_ids, selected_ids)
    |> assign(:weights_map, weights_map)
  end

  # event handlers

  @impl true
  def handle_event("show_setup", _params, socket) do
    {:noreply, socket |> assign(:view, :setup) |> load_strand_goals()}
  end

  def handle_event("back_to_overview", _params, socket) do
    {:noreply, assign(socket, :view, :overview)}
  end

  def handle_event("toggle_ap", %{"id" => ap_id}, socket) do
    selected_ids =
      if ap_id in socket.assigns.selected_ids do
        MapSet.delete(socket.assigns.selected_ids, ap_id)
      else
        MapSet.put(socket.assigns.selected_ids, ap_id)
      end

    {:noreply, assign(socket, :selected_ids, selected_ids)}
  end

  def handle_event("update_weight", %{"ap_id" => ap_id_str, "weight" => weight_str}, socket) do
    ap_id = String.to_integer(ap_id_str)

    weights_map =
      case Float.parse(weight_str) do
        {weight, _} when weight > 0 ->
          Map.put(socket.assigns.weights_map, ap_id, weight)

        _ ->
          socket.assigns.weights_map
      end

    {:noreply, assign(socket, :weights_map, weights_map)}
  end

  def handle_event("save_composition", _params, socket) do
    scope = socket.assigns.current_scope
    selected_ids = socket.assigns.selected_ids
    weights_map = socket.assigns.weights_map

    components =
      Enum.map(selected_ids, fn ap_id ->
        %{assessment_point_id: ap_id, weight: Map.get(weights_map, ap_id, 1.0)}
      end)

    ids =
      Map.take(socket.assigns, [
        :grades_report_id,
        :grades_report_cycle_id,
        :grades_report_subject_id
      ])

    {:ok, :replaced} = Grading.replace_grade_composition(scope, ids, components)

    composition_components =
      GradesReports.list_grade_composition(
        socket.assigns.grades_report_cycle_id,
        socket.assigns.grades_report_subject_id
      )

    {:noreply,
     socket
     |> assign(:view, :overview)
     |> assign(:composition_components, composition_components)}
  end
end
