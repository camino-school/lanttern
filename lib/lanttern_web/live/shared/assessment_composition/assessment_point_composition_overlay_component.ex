defmodule LantternWeb.AssessmentComposition.AssessmentPointCompositionOverlayComponent do
  @moduledoc """
  Modal for setting up or managing an assessment point's grade composition.

  Has two internal views:
  - `:overview` — shows the current composition state (type select, placeholder or component list)
  - `:setup` — shows the AP checklist for selecting which APs contribute to the composition

  Navigates between views without closing the modal. Notifies the parent on
  composition updates (so the card refreshes) and on deletion (which closes the modal).
  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [format_float: 1]

  alias Lanttern.AssessmentComposition
  alias Lanttern.Assessments
  alias Lanttern.LearningContext

  @ap_preloads [:scale, :moment, curriculum_item: :curriculum_component]

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{gettext("Grade composition")}</:title>
        <%= if @view == :overview do %>
          <div class="flex items-start justify-between gap-6">
            <form phx-change="update_type" phx-target={@myself}>
              <.input
                type="select"
                name="composition_type"
                label={gettext("Composition type")}
                options={[{gettext("Sum"), "sum"}, {gettext("Average"), "avg"}]}
                value={@ap.composition_type}
                class="w-56"
              />
            </form>
            <.button
              type="button"
              theme={if @composition_components == [], do: "primary"}
              phx-click="show_setup"
              phx-target={@myself}
              class="mt-6 shrink-0"
            >
              {if @composition_components == [],
                do: gettext("Setup composition"),
                else: gettext("Manage composition")}
            </.button>
          </div>
          <%= if @composition_components == [] do %>
            <div class="mt-6 p-4 rounded-sm border border-dashed border-ltrn-lighter text-center text-sm text-ltrn-subtle">
              {gettext("%{name} grading composition not setup yet",
                name: ap_display_name(@ap)
              )}
            </div>
          <% else %>
            <div class="mt-6">
              <div class="flex items-center font-sans text-sm text-ltrn-subtle">
                <div class="flex-1">{gettext("Assessment point")}</div>
                <div>
                  {if @ap.composition_type == :sum, do: gettext("Score"), else: gettext("Weight")}
                </div>
              </div>
              <div
                :for={comp <- @composition_components}
                class="flex items-center gap-6 mt-4"
              >
                <span class="truncate">{ap_display_name(comp.component)}</span>
                <span class="flex-1 border-b border-ltrn-lighter" />
                <span class="shrink-0 tabular-nums">
                  {if @ap.composition_type == :sum,
                    do: ap_score_display(comp.component),
                    else: comp.weight}
                </span>
              </div>
              <div class="flex items-center gap-12 font-bold mt-4">
                <span class="flex-1 truncate">{ap_display_name(@ap)}</span>
                <span :if={@ap.composition_type == :sum} class="shrink-0 tabular-nums">
                  {composition_total(@ap.composition_type, @composition_components)}
                </span>
              </div>
            </div>
          <% end %>
        <% else %>
          <p class="font-display font-bold text-ltrn-subtle mb-4">
            {composition_subtitle(@ap.composition_type)}
          </p>
          <p>{gettext("Select the assessment points that will be part of the grade composition")}</p>
          <div class="flex items-center px-4 mt-10 mb-2 font-sans text-sm text-ltrn-subtle">
            <div class="flex-1">{gettext("Assessment point")}</div>
            <div>
              {if @ap.composition_type == :sum, do: gettext("Score"), else: gettext("Weight")}
            </div>
          </div>
          <.card_base
            :for={sibling_ap <- @all_aps}
            id={"comp-ap-#{sibling_ap.id}"}
            class="flex items-center gap-4 p-4 mt-2"
            bg_class={if(sibling_ap.id in @selected_ids, do: nil, else: "bg-ltrn-lightest")}
            remove_shadow={sibling_ap.id not in @selected_ids}
          >
            <label class="flex items-center gap-4 flex-1 min-w-0">
              <input
                type="checkbox"
                checked={sibling_ap.id in @selected_ids}
                phx-click={JS.push("toggle_ap", value: %{id: sibling_ap.id}, target: @myself)}
                class="appearance-none rounded-xs size-5 border-2 border-ltrn-subtle checked:border-ltrn-primary checked:bg-ltrn-primary indeterminate:border-ltrn-dark indeterminate:bg-ltrn-dark focus:outline-2 focus:outline-offset-2 focus:outline-ltrn-primary disabled:border-ltrn-subtle disabled:bg-ltrn-light disabled:checked:bg-ltrn-light forced-colors:appearance-auto"
              />
              <div class="flex-1 min-w-0">
                <p>{ap_display_name(sibling_ap)}</p>
                <p :if={sibling_ap.moment_id} class="mt-1 font-sans text-sm text-ltrn-subtle truncate">
                  {sibling_ap.moment.name}
                </p>
              </div>
            </label>
            <div class="w-16 text-right shrink-0">
              <%= if @ap.composition_type == :sum do %>
                <span class={[
                  "tabular-nums",
                  if(sibling_ap.id in @selected_ids, do: "font-bold", else: "text-ltrn-subtle")
                ]}>
                  {ap_score_display(sibling_ap)}
                </span>
              <% else %>
                <form
                  :if={sibling_ap.id in @selected_ids}
                  phx-change="update_weight"
                  phx-target={@myself}
                >
                  <input type="hidden" name="ap_id" value={sibling_ap.id} />
                  <input
                    type="number"
                    name="weight"
                    value={Map.get(@weights_map, sibling_ap.id, 1.0)}
                    step="0.01"
                    min="0.01"
                    phx-debounce="500"
                    class="w-16 rounded-xs border-none text-right text-sm bg-ltrn-lightest"
                  />
                </form>
              <% end %>
            </div>
          </.card_base>
          <div class="flex items-center justify-between mt-6">
            <.button
              type="button"
              theme="ghost"
              phx-click="delete_composition"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
            >
              {gettext("Delete")}
            </.button>
            <div class="flex items-center gap-2">
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
          </div>
        <% end %>
      </.modal>
    </div>
    """
  end

  defp composition_subtitle(:sum), do: gettext("Sum-based grade composition")
  defp composition_subtitle(:avg), do: gettext("Average-based grade composition")

  defp ap_display_name(%{moment_id: nil} = ap),
    do: "(#{ap.curriculum_item.curriculum_component.name}) #{ap.curriculum_item.name}"

  defp ap_display_name(ap), do: ap.name

  defp ap_score_display(%{scale: %{type: "numeric", max_score: max_score}})
       when not is_nil(max_score),
       do: format_float(max_score)

  defp ap_score_display(_), do: "—"

  defp composition_total(:sum, components) do
    total =
      components
      |> Enum.reduce(0, fn comp, acc ->
        case comp.component do
          %{scale: %{type: "numeric", max_score: max_score}} when not is_nil(max_score) ->
            acc + max_score

          _ ->
            acc
        end
      end)

    format_float(total)
  end

  defp composition_total(:avg, components) do
    components
    |> Enum.reduce(0.0, fn comp, acc -> acc + comp.weight end)
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:view, :overview)
      |> assign(:composition_components, [])
      |> assign(:all_aps, [])
      |> assign(:selected_ids, MapSet.new())
      |> assign(:weights_map, %{})

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    composition_components =
      AssessmentComposition.list_assessment_point_components(assigns.current_scope, assigns.ap.id)

    initial_view = Map.get(assigns, :initial_view, :overview)

    socket =
      socket
      |> assign(assigns)
      |> assign(:view, initial_view)
      |> assign(:composition_components, composition_components)
      |> maybe_load_all_aps()

    {:ok, socket}
  end

  defp maybe_load_all_aps(%{assigns: %{view: :setup}} = socket), do: load_all_aps(socket)
  defp maybe_load_all_aps(socket), do: socket

  defp load_all_aps(socket) do
    strand_id = socket.assigns.strand_id
    parent_id = socket.assigns.ap.id

    moments = LearningContext.list_moments(strands_ids: [strand_id])
    moment_ids = Enum.map(moments, & &1.id)

    moment_aps =
      if moment_ids == [] do
        []
      else
        Assessments.list_assessment_points(moments_ids: moment_ids, preloads: @ap_preloads)
      end

    strand_aps =
      Assessments.list_assessment_points(strand_id: strand_id, preloads: @ap_preloads)

    composition_type = socket.assigns.ap.composition_type

    all_aps =
      (moment_aps ++ strand_aps)
      |> Enum.reject(&(&1.id == parent_id))
      |> then(fn aps ->
        if composition_type == :sum do
          Enum.filter(aps, &match?(%{scale: %{type: "numeric"}}, &1))
        else
          aps
        end
      end)

    existing = socket.assigns.composition_components

    selected_ids =
      existing
      |> Enum.map(& &1.component_id)
      |> MapSet.new()

    weights_map =
      existing
      |> Enum.map(&{&1.component_id, &1.weight})
      |> Enum.into(%{})

    socket
    |> assign(:all_aps, all_aps)
    |> assign(:selected_ids, selected_ids)
    |> assign(:weights_map, weights_map)
  end

  # event handlers

  @impl true
  def handle_event("update_type", %{"composition_type" => type}, socket) do
    ap = socket.assigns.ap

    {:ok, updated_ap} =
      Assessments.update_assessment_point(socket.assigns.current_scope, ap, %{
        composition_type: type
      })

    notify(__MODULE__, {:composition_updated, ap.id}, socket.assigns)
    {:noreply, assign(socket, :ap, %{ap | composition_type: updated_ap.composition_type})}
  end

  def handle_event("show_setup", _params, socket) do
    {:noreply, socket |> assign(:view, :setup) |> load_all_aps()}
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

  def handle_event(
        "update_weight",
        %{"ap_id" => ap_id_str, "weight" => weight_str},
        socket
      ) do
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
    ap = socket.assigns.ap
    scope = socket.assigns.current_scope
    selected_ids = socket.assigns.selected_ids
    weights_map = socket.assigns.weights_map

    components =
      Enum.map(selected_ids, fn ap_id ->
        %{component_id: ap_id, weight: Map.get(weights_map, ap_id, 1.0)}
      end)

    {:ok, _} = AssessmentComposition.replace_assessment_point_components(scope, ap.id, components)

    composition_components = AssessmentComposition.list_assessment_point_components(scope, ap.id)

    notify(__MODULE__, {:composition_updated, ap.id}, socket.assigns)

    {:noreply,
     socket
     |> assign(:view, :overview)
     |> assign(:composition_components, composition_components)}
  end

  def handle_event("delete_composition", _params, socket) do
    ap = socket.assigns.ap

    AssessmentComposition.delete_all_assessment_point_components(
      socket.assigns.current_scope,
      ap.id
    )

    Assessments.update_assessment_point(socket.assigns.current_scope, ap, %{composition_type: nil})

    notify(__MODULE__, {:deleted, ap.id}, socket.assigns)
    {:noreply, socket}
  end
end
