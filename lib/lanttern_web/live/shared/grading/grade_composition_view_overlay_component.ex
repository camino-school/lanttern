defmodule LantternWeb.Grading.GradeCompositionViewOverlayComponent do
  @moduledoc """
  Read-only modal for viewing a grades report's grade composition.

  A grade composition is always **average-based**: the grade for a
  (grades report cycle × subject) pair is a weighted average of the selected
  strand goals. This overlay only **displays** the composition — editing happens
  in the strand context (`StrandGradeCompositionOverlayComponent`).

  A composition may reference goals from more than one strand, so each component
  is displayed as "(Strand name) Assessment point name". The "Manage in strand
  context" dropdown lists every strand related to the composition, navigating to
  the strand assessment view for editing.
  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [format_float: 1]

  alias Lanttern.GradesReports
  alias Lanttern.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{gettext("Grade composition")}</:title>
        <div class="flex items-start justify-between gap-6">
          <div>
            <p class="font-bold text-ltrn-darkest">
              {@cycle_name}, {@subject_name}
            </p>
            <p class="font-display font-bold text-ltrn-subtle">
              {gettext("Average-based grade composition")}
            </p>
          </div>
          <%= case @strands do %>
            <% [] -> %>
            <% [strand] -> %>
              <.button
                type="link"
                navigate={~p"/strands/#{strand.id}/assessment"}
                class="shrink-0"
              >
                {gettext("Manage in strand context")}
              </.button>
            <% strands -> %>
              <div class="relative shrink-0">
                <.button type="button" id={"#{@id}-manage-strand-button"}>
                  {gettext("Manage in strand context")}
                </.button>
                <.dropdown_menu
                  id={"#{@id}-manage-strand-menu"}
                  button_id={"#{@id}-manage-strand-button"}
                  position="right"
                  z_index="30"
                >
                  <:item
                    :for={strand <- strands}
                    type="link"
                    text={strand.name}
                    navigate={~p"/strands/#{strand.id}/assessment"}
                  />
                </.dropdown_menu>
              </div>
          <% end %>


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
              <div class="min-w-0">
                <div class="truncate">{comp.assessment_point.curriculum_item.name}</div>
                <div class="mt-1 font-sans text-sm text-ltrn-subtle truncate">
                  {comp.assessment_point.strand.name}
                </div>
                <.tooltip id={"grade-composition-component-tooltip-#{comp.id}"}>
                  <p>{comp.assessment_point.curriculum_item.name}</p>
                  <p class="mt-1 text-ltrn-lighter">{comp.assessment_point.strand.name}</p>
                </.tooltip>
              </div>
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
      </.modal>
    </div>
    """
  end

  defp composition_total(components) do
    components
    |> Enum.reduce(0.0, fn comp, acc -> acc + comp.weight end)
    |> format_float()
  end

  # lifecycle

  @impl true
  def update(assigns, socket) do
    composition_components =
      GradesReports.list_grade_composition(
        assigns.grades_report_cycle_id,
        assigns.grades_report_subject_id
      )

    strands =
      Reporting.list_grades_report_subject_strands(
        assigns.current_scope,
        assigns.grades_report_cycle_id,
        assigns.grades_report_subject_id
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:composition_components, composition_components)
      |> assign(:strands, strands)

    {:ok, socket}
  end
end
