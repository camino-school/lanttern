defmodule LantternWeb.Assessments.EntryCellComponent do
  @moduledoc """
  This component renders the assessment point entry info, based on the view type.

  As this component is used in assessment grid views,
  rendering multiple components at the same time, it also handles the
  scales "preload" through `update_many/1`.

  #### Suported views

  - `:edit_teacher` - displays the teacher assessment (editable)
  - `:edit_student` - displays the student assessment (editable)
  - `:view_teacher` - displays the teacher assessment (view only)
  - `:view_student` - displays the student assessment (view only)
  - `:compare` - displays the teacher and student assessments side by side (view only)

  #### Expected external assigns

      attr :entry, AssessmentPointEntry
      attr :current_scope, Scope
      attr :allow_edit, :boolean
      attr :view, :string, default: "teacher", doc: "teacher | student | compare. When compare, disallow edit"
      attr :class, :any

  """
  alias Lanttern.Grading
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.ColorUtils
  # alias Lanttern.Grading.OrdinalValue
  # alias Lanttern.Grading.Scale

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"cell-#{@id}"}
      class={[
        "relative w-full h-full",
        @form && "focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-ltrn-dark",
        @grid_class,
        @class
      ]}
      tabindex={if @form, do: "0"}
      phx-hook={if @form, do: "EntryCell"}
      data-scale-type={if @form, do: @entry.scale_type}
    >
      <%= if @form do %>
        <div class="flex items-center gap-2 w-full h-full">
          <.form
            for={@form}
            phx-change="change"
            phx-target={@myself}
            class={[
              "relative flex-1 w-full h-full",
              if(@has_changes, do: "outline outline-4 outline-offset-1 outline-ltrn-dark")
            ]}
            id={"entry-#{@id}-marking-form"}
          >
            <.marking_input
              scale_type={@entry.scale_type}
              ov_options={@ov_options}
              field={@field}
              style={if(@has_changes, do: "background-color: white", else: @field_style)}
            />
            <.missing_indicator entry={@entry} />
          </.form>
          <button
            type="button"
            tabindex="-1"
            class={[
              "flex flex-col shrink-0 rounded-full text-ltrn-light hover:bg-ltrn-lightest",
              "disabled:bg-ltrn-lighter disabled:shadow-none"
            ]}
            phx-click="view_details"
            phx-target={@myself}
          >
            <.icon name="hero-chat-bubble-oval-left-micro" class={["size-3", @note_icon_class]} />
            <.icon name="hero-paper-clip-micro" class={["size-3", @evidences_icon_class]} />
            <.icon name="hero-view-columns-micro" class={["size-3", @diff_rubric_icon_class]} />
            <.tooltip
              :if={@entry_note || @entry.has_evidences || @entry.differentiation_rubric_id}
              id={"cell-#{@id}-details-tooltip"}
            >
              <p :if={@entry_note}>{gettext("Has teacher comment")}</p>
              <p :if={@entry.has_evidences}>{gettext("Has attachment")}</p>
              <p :if={@entry.differentiation_rubric_id}>{gettext("Has differentiation rubric")}</p>
            </.tooltip>
          </button>
        </div>
      <% else %>
        <.entry_view
          :if={@view in ["compare", "teacher"]}
          entry={@entry}
          teacher_ov_name={@teacher_ov_name}
          teacher_ov_style={@teacher_ov_style}
          view="teacher"
        />
        <.entry_view
          :if={@view in ["compare", "student"]}
          entry={@entry}
          student_ov_name={@student_ov_name}
          student_ov_style={@student_ov_style}
          view="student"
        />
      <% end %>
    </div>
    """
  end

  attr :scale_type, :string, required: true
  attr :field, :map, required: true
  attr :ov_options, :list
  attr :style, :string

  def marking_input(%{scale_type: "ordinal"} = assigns) do
    current_label =
      Enum.find_value(assigns.ov_options, fn {label, val} ->
        to_string(val) == to_string(assigns.field.value) && label
      end)

    assigns = assign(assigns, :current_label, current_label)

    ~H"""
    <div class="relative w-full h-full">
      <input type="hidden" id={@field.id} name={@field.name} value={@field.value || ""} />
      <div
        class={[
          "flex items-center justify-center w-full h-full rounded-xs font-mono text-sm truncate px-1",
          is_nil(@current_label) && "bg-ltrn-lighter"
        ]}
        style={if @current_label, do: @style}
      >
        <span class={[is_nil(@current_label) && "text-ltrn-subtle"]}>
          {@current_label || "—"}
        </span>
      </div>
      <ul
        class="hidden absolute z-30 left-0 top-full mt-0.5 min-w-max rounded-sm shadow-md bg-white ring-1 ring-ltrn-lighter overflow-y-auto max-h-48"
        role="listbox"
        data-ordinal-list
      >
        <li
          class="px-3 py-1.5 font-mono text-sm cursor-pointer text-ltrn-subtle hover:bg-ltrn-lightest data-[active=true]:bg-ltrn-lightest"
          role="option"
          data-ordinal-item
          data-value=""
        >
          {gettext("None")}
        </li>
        <li
          :for={{label, value} <- @ov_options}
          class="px-3 py-1.5 font-mono text-sm cursor-pointer hover:bg-ltrn-lightest data-[active=true]:bg-ltrn-lightest"
          role="option"
          data-ordinal-item
          data-value={value}
        >
          {label}
        </li>
      </ul>
    </div>
    """
  end

  def marking_input(%{scale_type: "numeric"} = assigns) do
    ~H"""
    <.base_input
      name={@field.name}
      type="number"
      phx-debounce="1000"
      value={@field.value}
      errors={@field.errors}
      style={@style}
      class={[
        "h-full font-mono text-center",
        @field.value == nil && "bg-ltrn-lighter"
      ]}
    />
    """
  end

  attr :entry, :any, required: true
  attr :teacher_ov_name, :string
  attr :teacher_ov_style, :string
  attr :student_ov_name, :string
  attr :student_ov_style, :string
  attr :view, :string, required: true, doc: "teacher | student"

  def entry_view(%{entry: %{scale_type: "ordinal"}} = assigns) do
    {value, style} =
      case assigns.view do
        "teacher" -> {assigns.teacher_ov_name, assigns.teacher_ov_style}
        "student" -> {assigns.student_ov_name, assigns.student_ov_style}
      end

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:style, style)

    ~H"""
    <%= if @value do %>
      <div
        class="flex items-center justify-center h-full px-1 py-2 rounded-xs font-mono text-xs bg-white"
        style={@style}
      >
        <span class="truncate text-clip">
          {@value}
        </span>
      </div>
    <% else %>
      <.empty entry={@entry} />
    <% end %>
    """
  end

  def entry_view(%{entry: %{scale_type: "numeric"}} = assigns) do
    {value, style} =
      case assigns.view do
        "teacher" -> {assigns.entry.score, assigns.teacher_ov_style}
        "student" -> {assigns.entry.student_score, assigns.student_ov_style}
      end

    assigns = assigns |> assign(:value, value) |> assign(:style, style)

    ~H"""
    <%= if @value do %>
      <div
        class="flex items-center justify-center h-full p-2 rounded-xs font-mono text-sm bg-white shadow-lg"
        style={@style}
      >
        {@value}
      </div>
    <% else %>
      <.empty entry={@entry} />
    <% end %>
    """
  end

  attr :entry, :map, required: true

  def empty(assigns) do
    ~H"""
    <div class="relative flex items-center justify-center h-full p-2 rounded-xs font-mono text-sm text-ltrn-subtle bg-ltrn-lighter">
      — <.missing_indicator entry={@entry} />
    </div>
    """
  end

  attr :entry, :map, required: true

  def missing_indicator(assigns) do
    ~H"""
    <div
      :if={@entry.is_missing}
      class="absolute -top-1 -left-1 size-3 rounded-full bg-ltrn-alert-accent shadow-sm"
    />
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:grid_class, nil)
      |> assign(:view, "teacher")
      |> assign(:allow_edit, false)
      |> assign(:has_changes, false)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    scales_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        case assigns.entry do
          %AssessmentPointEntry{} = entry -> entry.scale_id
          _ -> nil
        end
      end)
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.uniq()

    [{%{current_scope: scope} = _assigns, _socket} | _rest] = assigns_sockets

    # map format
    # %{
    #   scale_id: %{
    #     ov_map: %{ov_id: ov, ...},
    #     ov_style_map: %{ov_id: style, ...},
    #     scale: %Scale{} | nil,
    #   },
    #   ...
    # }
    ordinal_scale_maps =
      Grading.list_scales(
        scope,
        type: "ordinal",
        ids: scales_ids,
        preloads: :ordinal_values
      )
      |> Enum.map(
        &{
          &1.id,
          %{
            ov_map: build_ov_map(&1.ordinal_values),
            ov_style_map: build_ov_style_map(&1.ordinal_values),
            ov_options: build_ov_options(&1.ordinal_values),
            scale: nil
          }
        }
      )
      |> Enum.into(%{})

    numeric_scale_maps =
      Grading.list_scales(scope, type: "numeric", ids: scales_ids)
      |> Enum.map(&{&1.id, %{ov_map: %{}, ov_style_map: %{}, ov_options: [], scale: &1}})
      |> Enum.into(%{})

    scale_maps = Map.merge(ordinal_scale_maps, numeric_scale_maps)

    assigns_sockets
    |> Enum.map(&update_single(&1, scale_maps))
  end

  defp build_ov_map(ordinal_values) do
    ordinal_values
    |> Enum.map(&{&1.id, &1})
    |> Enum.into(%{})
  end

  defp build_ov_style_map(ordinal_values) do
    ordinal_values
    |> Enum.map(&{&1.id, "background-color: #{&1.bg_color}; color: #{&1.text_color}"})
    |> Enum.into(%{})
  end

  defp build_ov_options(ordinal_values) do
    ordinal_values
    |> Enum.map(&{&1.name, &1.id})
  end

  defp update_single({assigns, socket}, scale_maps) do
    default_maps = %{ov_map: %{}, ov_style_map: %{}, ov_options: [], scale: nil}

    %{ov_map: ov_map, ov_style_map: ov_style_map, ov_options: ov_options, scale: scale} =
      Map.get(scale_maps, assigns.entry.scale_id, default_maps)

    socket
    |> assign(assigns)
    |> assign_ov_values_and_styles(ov_map, ov_style_map, scale)
    |> assign_form_and_related_assigns(ov_options)
    |> assign_grid_class()
  end

  defp assign_ov_values_and_styles(socket, ov_map, ov_style_map, scale) do
    entry = socket.assigns.entry

    {teacher_ov_name, teacher_ov_style, student_ov_name, student_ov_style} =
      case entry.scale_type do
        "ordinal" ->
          teacher_ov = Map.get(ov_map, entry.ordinal_value_id)
          student_ov = Map.get(ov_map, entry.student_ordinal_value_id)

          {
            teacher_ov && teacher_ov.name,
            Map.get(ov_style_map, entry.ordinal_value_id),
            student_ov && student_ov.name,
            Map.get(ov_style_map, entry.student_ordinal_value_id)
          }

        "numeric" ->
          {nil, numeric_style(scale, entry.score), nil, numeric_style(scale, entry.student_score)}
      end

    socket
    |> assign(:teacher_ov_name, teacher_ov_name)
    |> assign(:teacher_ov_style, teacher_ov_style)
    |> assign(:student_ov_name, student_ov_name)
    |> assign(:student_ov_style, student_ov_style)
  end

  defp numeric_style(nil, _score), do: nil
  defp numeric_style(_scale, nil), do: nil

  defp numeric_style(scale, score) do
    case ColorUtils.interpolate_numeric_scale_colors(scale, score) do
      {bg, text} ->
        bg_part = if bg, do: "background-color: #{bg};", else: ""
        text_part = if text, do: " color: #{text};", else: ""
        bg_part <> text_part

      nil ->
        nil
    end
  end

  defp assign_grid_class(socket) do
    grid_class =
      case socket.assigns.view do
        "compare" -> "grid grid-cols-2 gap-1"
        _ -> nil
      end

    assign(socket, :grid_class, grid_class)
  end

  defp assign_form_and_related_assigns(
         %{assigns: %{allow_edit: true, view: view}} = socket,
         ov_options
       )
       when view != "compare" do
    %{entry: entry, view: view} = socket.assigns

    form =
      entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    field = get_field_for_form(form, entry.scale_type, view)

    field_style =
      if view == "student",
        do: socket.assigns.student_ov_style,
        else: socket.assigns.teacher_ov_style

    {entry_value, other_value} = get_entry_value_and_other_value(entry, view)

    entry_note =
      if view == "student",
        do: entry.student_report_note,
        else: entry.report_note

    note_icon_class =
      cond do
        entry_note && view == "student" -> "text-ltrn-student-accent"
        entry_note -> "text-ltrn-staff-accent"
        true -> ""
      end

    evidences_icon_class = if entry.has_evidences, do: "text-ltrn-primary", else: ""

    diff_rubric_icon_class =
      if entry.differentiation_rubric_id, do: "text-ltrn-diff-accent", else: ""

    socket
    |> assign(:form, form)
    |> assign(:field, field)
    |> assign(:field_style, field_style)
    |> assign(:ov_options, ov_options)
    |> assign(:entry_value, entry_value)
    |> assign(:other_value, other_value)
    |> assign(:entry_note, entry_note)
    |> assign(:note_icon_class, note_icon_class)
    |> assign(:evidences_icon_class, evidences_icon_class)
    |> assign(:diff_rubric_icon_class, diff_rubric_icon_class)
  end

  defp assign_form_and_related_assigns(socket, _ov_options), do: assign(socket, :form, nil)

  defp get_field_for_form(form, "ordinal", "student"), do: form[:student_ordinal_value_id]
  defp get_field_for_form(form, "ordinal", _teacher), do: form[:ordinal_value_id]
  defp get_field_for_form(form, "numeric", "student"), do: form[:student_score]
  defp get_field_for_form(form, "numeric", _teacher), do: form[:score]

  # when in student view, other value = teacher value (and vice-versa)
  defp get_entry_value_and_other_value(entry, view) do
    case {entry.scale_type, view} do
      {"ordinal", "student"} -> {entry.student_ordinal_value_id, entry.ordinal_value_id}
      {"ordinal", _teacher} -> {entry.ordinal_value_id, entry.student_ordinal_value_id}
      {"numeric", "student"} -> {entry.student_score, entry.score}
      {"numeric", _teacher} -> {entry.score, entry.student_score}
    end
  end

  # event handlers

  @impl true
  def handle_event("change", %{"assessment_point_entry" => params}, socket) do
    %{
      entry: entry,
      view: view,
      entry_value: entry_value
    } = socket.assigns

    form =
      entry
      |> Assessments.change_assessment_point_entry(params)
      |> to_form()

    field = get_field_for_form(form, entry.scale_type, view)

    entry_params =
      entry
      |> Map.from_struct()
      |> Map.take([:student_id, :assessment_point_id, :scale_id, :scale_type])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    # add extra fields from entry
    params =
      params
      |> Enum.into(entry_params)

    # get the right ordinal value or score based on view
    param_value = get_param_value(params, view)
    has_changes = "#{entry_value}" != param_value
    change_type = if has_changes, do: :edit, else: :cancel
    composite_id = "#{entry_params["student_id"]}_#{entry_params["assessment_point_id"]}"

    notify(
      __MODULE__,
      {:change, change_type, composite_id, entry.id, params},
      socket.assigns
    )

    socket =
      socket
      |> assign(:has_changes, has_changes)
      |> assign(:form, form)
      |> assign(:field, field)

    {:noreply, socket}
  end

  def handle_event("view_details", _, socket) do
    notify(
      __MODULE__,
      {:view_details, socket.assigns.entry},
      socket.assigns
    )

    {:noreply, socket}
  end

  # helpers

  @spec get_param_value(params :: map(), view :: String.t()) :: String.t()
  defp get_param_value(%{"scale_type" => "ordinal"} = params, "student"),
    do: params["student_ordinal_value_id"]

  defp get_param_value(%{"scale_type" => "numeric"} = params, "student"),
    do: params["student_score"]

  defp get_param_value(%{"scale_type" => "ordinal"} = params, _teacher),
    do: params["ordinal_value_id"]

  defp get_param_value(%{"scale_type" => "numeric"} = params, _teacher),
    do: params["score"]
end
