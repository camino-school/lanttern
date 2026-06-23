defmodule LantternWeb.Assessments.StudentAssessmentPointDetailsOverlayComponent do
  @moduledoc """
  Renders an assessment point info overlay.

  For composed assessment points (`uses_composition`), a composition breakdown table is
  rendered (components, weights, and current marking). When the assessment point is hidden,
  its own marking is masked — the composition, if any, is still shown.

  ### Required attrs:

  - `assessment_point_id`
  - `student_id`
  - `current_scope` - the current `%Scope{}`
  - `on_cancel` - a `%JS{}` struct to execute on overlay close
  - `base_path` - the base URL path used to build prev/next and component navigation patches
  - `displayed_assessment_points_ids` - ordered list of viewable assessment point id strings,
    used to compute prev/next navigation and to gate composition row links
  """

  use LantternWeb, :live_component

  alias Lanttern.AssessmentComposition
  alias Lanttern.Assessments
  alias Lanttern.Attachments
  alias Lanttern.Rubrics

  # shared components
  import LantternWeb.AssessmentsComponents
  import LantternWeb.AttachmentsComponents
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={"#{@id}-modal"} show={true} on_cancel={@on_cancel}>
        <:title>
          {@assessment_point.name}
        </:title>
        <%!-- keyed by AP id so navigating between APs remounts the hook and scrolls to top --%>
        <.scroll_to_top
          overlay_id={"#{@id}-modal"}
          id={"#{@id}-scroll-top-#{@assessment_point_id}"}
        />
        <.markdown
          :if={@assessment_point.report_info}
          text={@assessment_point.report_info}
          class="mt-4"
        />
        <div class="mt-10">
          <%!-- composed ordinal (visible): marked ordinal value box + normalized value box --%>
          <div :if={@scale_normalized_badge} class="flex items-center gap-2">
            <div
              class="flex-1 flex items-center justify-center p-4 rounded-sm font-sans font-bold text-sm text-center shadow-lg"
              style={create_color_map_style(@entry.ordinal_value)}
            >
              {@entry.ordinal_value.name}
            </div>
            <div class="flex items-center justify-center p-4 rounded-sm font-sans font-bold text-sm text-center shadow-lg border border-ltrn-lighter bg-white">
              {@scale_normalized_badge}
            </div>
          </div>
          <.assessment_point_entry_display
            :if={!@scale_normalized_badge}
            entry={@entry}
            scale={@assessment_point.scale}
            show_student_assessment
            prevent_preview={@assessment_point.is_hidden}
          />
          <div :if={@show_scale_visual} class="py-4 overflow-x-auto">
            <.report_scale_numeric_bar
              :if={@scale_display_mode == :numeric}
              id={"#{@id}-scale"}
              class="min-w-full"
              scale={@assessment_point.scale}
              score={if !@assessment_point.is_hidden && @entry, do: @entry.score}
            />
            <.report_scale_ordinal_columns
              :if={@scale_display_mode == :ordinal_columns}
              id={"#{@id}-scale"}
              scale={@assessment_point.scale}
              entry={!@assessment_point.is_hidden && @entry}
            />
            <.report_scale_ordinal_bar
              :if={@scale_display_mode == :ordinal_bar}
              id={"#{@id}-ordinal-bar"}
              scale={@assessment_point.scale}
              entry={!@assessment_point.is_hidden && @entry}
            />
          </div>
        </div>
        <div :if={@entry && (@entry.report_note || @entry.student_report_note)} class="mt-10">
          <.comment_area :if={@entry.report_note} comment={@entry.report_note} />
          <.comment_area
            :if={@entry.student_report_note}
            comment={@entry.student_report_note}
            class="mt-4"
            type="student"
          />
        </div>
        <div :if={@assessment_point.uses_composition} class="mt-10">
          <h5 class="font-display font-black text-base">{gettext("Grade composition")}</h5>
          <p :if={@composition_help_text} class="mt-2 text-sm text-ltrn-subtle">
            {@composition_help_text}
          </p>
          <.composition_breakdown_table
            breakdown={@composition_breakdown}
            composed_name={@assessment_point.name}
            mask_hidden_components
            mask_composed={@assessment_point.is_hidden}
            component_patch_fn={@component_patch_fn}
            class="mt-4"
          />
        </div>
        <div :if={@rubric && @assessment_point.scale.type == "ordinal"} class="mt-10">
          <div class="flex items-center justify-between gap-2">
            <h5 class="flex items-center gap-2 font-display font-black text-base">
              <.icon name="hero-view-columns" /> {gettext("Assessment rubric")}
            </h5>
            <.badge :if={@rubric.is_differentiation} theme="diff">
              {gettext("Differentiation")}
            </.badge>
          </div>
          <p class="mt-2 text-sm">
            <span class="font-bold">{gettext("Criteria:")}</span> {@rubric.criteria}
          </p>
          <div class="py-4 overflow-x-auto">
            <.report_scale
              id={"#{@id}-rubric-scale"}
              scale={@assessment_point.scale}
              rubric={@rubric}
              entry={!@assessment_point.is_hidden && @entry}
            />
          </div>
        </div>
        <div :if={@entry && @entry.evidences != []} class="mt-10">
          <h5 class="flex items-center gap-2 font-display font-black text-base">
            <.icon name="hero-paper-clip" class="w-6 h-6" /> {gettext("Learning evidences")}
          </h5>
          <.attachments_list
            id="goals-attachments-list"
            attachments={@entry.evidences}
          />
        </div>
        <div class="mt-10">
          <h5 class="font-display font-black text-base">
            {gettext("Curriculum")}
          </h5>
          <p class="text-base mt-4">
            {@assessment_point.curriculum_item.name}
          </p>
          <div class="flex flex-wrap items-center gap-2 mt-4">
            <.badge theme="dark">
              {@assessment_point.curriculum_item.curriculum_component.name}
            </.badge>
            <.badge :if={@assessment_point.curriculum_item.code} theme="dark">
              {@assessment_point.curriculum_item.code}
            </.badge>
            <.badge :if={@assessment_point.is_differentiation} theme="diff">
              {gettext("Curriculum differentiation")}
            </.badge>
            <.badge :for={subject <- @assessment_point.curriculum_item.subjects}>
              {subject.name}
            </.badge>
          </div>
        </div>
        <div
          :if={@prev_patch || @next_patch}
          class="flex items-center justify-between gap-4 mt-10"
        >
          <.button
            type="link"
            theme="ghost"
            size="sm"
            patch={@prev_patch}
            disabled={!@prev_patch}
            icon_name="hero-chevron-left-mini"
            icon_side="left"
          >
            {gettext("Previous")}
          </.button>
          <.button
            type="link"
            theme="ghost"
            size="sm"
            patch={@next_patch}
            disabled={!@next_patch}
            icon_name="hero-chevron-right-mini"
          >
            {gettext("Next")}
          </.button>
        </div>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point(assigns)
      |> assign_entry()
      |> assign_rubric()
      |> assign_scale_display()
      |> assign_composition()
      |> assign_navigation()

    {:ok, socket}
  end

  # Collapses the (uses_composition × scale type × is_hidden) matrix into the
  # single scale visual that should render:
  #
  #   * `:numeric`         — numeric bar (simple or composed, hidden or not)
  #   * `:ordinal_bar`     — segmented ordinal bar with normalized marker
  #     (composed ordinal, visible)
  #   * `:ordinal_columns` — ordinal value columns (simple ordinal, or hidden
  #     composed ordinal)
  #
  # `scale_normalized_badge` is the pre-formatted normalized value shown next to
  # the marked ordinal value box, set only in the `:ordinal_bar` case when there
  # is an entry with both an ordinal value and a normalized value.
  defp assign_scale_display(socket) do
    %{assessment_point: assessment_point, entry: entry} = socket.assigns
    mode = scale_display_mode(assessment_point)

    socket
    |> assign(:scale_display_mode, mode)
    |> assign(:scale_normalized_badge, scale_normalized_badge(mode, entry))
    |> assign(:show_scale_visual, show_scale_visual?(mode, assessment_point.scale))
  end

  defp scale_display_mode(%{scale: %{type: "numeric"}}), do: :numeric
  defp scale_display_mode(%{uses_composition: true, is_hidden: false}), do: :ordinal_bar
  defp scale_display_mode(_assessment_point), do: :ordinal_columns

  # the pre-formatted normalized value shown next to the marked ordinal value box
  # (composed ordinal entries only)
  defp scale_normalized_badge(:ordinal_bar, %{ordinal_value: ov, normalized_value: nv})
       when not is_nil(ov) and is_number(nv),
       do: Lanttern.Utils.format_normalized(nv)

  defp scale_normalized_badge(_mode, _entry), do: nil

  # single-value ordinal scales add no information as columns, so skip the
  # whole (padded) scale visual block in that case
  defp show_scale_visual?(:ordinal_columns, %{ordinal_values: ordinal_values}),
    do: length(ordinal_values) > 1

  defp show_scale_visual?(_mode, _scale), do: true

  defp assign_navigation(socket) do
    %{
      assessment_point_id: assessment_point_id,
      base_path: base_path,
      displayed_assessment_points_ids: ids
    } = socket.assigns

    index = Enum.find_index(ids, &(&1 == to_string(assessment_point_id)))

    prev_patch =
      if index && index > 0, do: build_ap_patch(base_path, Enum.at(ids, index - 1))

    next_patch =
      if index, do: build_ap_patch(base_path, Enum.at(ids, index + 1))

    component_patch_fn = fn ap_id ->
      if to_string(ap_id) in ids, do: build_ap_patch(base_path, ap_id)
    end

    socket
    |> assign(:prev_patch, prev_patch)
    |> assign(:next_patch, next_patch)
    |> assign(:component_patch_fn, component_patch_fn)
  end

  defp build_ap_patch(_base_path, nil), do: nil
  defp build_ap_patch(base_path, ap_id), do: "#{base_path}/assessment_point/#{ap_id}"

  defp assign_assessment_point(socket, assigns) do
    assessment_point =
      Assessments.get_assessment_point(assigns.assessment_point_id,
        preloads: [
          scale: :ordinal_values,
          curriculum_item: [
            :curriculum_component,
            :subjects
          ]
        ]
      )

    assign(socket, :assessment_point, assessment_point)
  end

  defp assign_entry(socket) do
    entry =
      Assessments.get_assessment_point_student_entry(
        socket.assigns.assessment_point.id,
        socket.assigns.student_id,
        preloads: [:scale, :ordinal_value, :student_ordinal_value]
      )

    entry =
      if entry do
        evidences = Attachments.list_attachments(assessment_point_entry_id: entry.id)
        %{entry | evidences: evidences}
      else
        entry
      end

    assign(socket, :entry, entry)
  end

  defp assign_rubric(%{assigns: %{entry: %{differentiation_rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    rubric = Rubrics.get_full_rubric!(rubric_id)
    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(%{assigns: %{assessment_point: %{rubric_id: rubric_id}}} = socket)
       when not is_nil(rubric_id) do
    rubric = Rubrics.get_full_rubric!(rubric_id)
    assign(socket, :rubric, rubric)
  end

  defp assign_rubric(socket), do: assign(socket, :rubric, nil)

  defp assign_composition(
         %{assigns: %{assessment_point: %{uses_composition: true} = assessment_point}} = socket
       ) do
    breakdown =
      AssessmentComposition.get_composition_breakdown(
        socket.assigns.current_scope,
        assessment_point.id,
        socket.assigns.student_id
      )

    help_text =
      case breakdown.scale_type do
        "numeric" ->
          gettext("This grade is calculated by the sum of the assessment points listed below.")

        _ ->
          gettext(
            "This grade is calculated by the average of the assessment points listed below."
          )
      end

    socket
    |> assign(:composition_breakdown, breakdown)
    |> assign(:composition_help_text, help_text)
  end

  defp assign_composition(socket) do
    socket
    |> assign(:composition_breakdown, nil)
    |> assign(:composition_help_text, nil)
  end
end
