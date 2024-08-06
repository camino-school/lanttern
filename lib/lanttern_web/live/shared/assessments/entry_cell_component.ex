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
      attr :allow_edit, :boolean
      attr :view, :string, default: "teacher", doc: "teacher | student | compare. When compare, disallow edit"
      attr :class, :any

  """
  alias Lanttern.Grading
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  # alias Lanttern.Grading.OrdinalValue
  # alias Lanttern.Grading.Scale

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["w-full h-full", @grid_class, @class]}>
      <%= if @form do %>
        <div class="flex items-center gap-2 w-full h-full">
          <.form
            for={@form}
            phx-change="change"
            phx-target={@myself}
            class={[
              "flex-1 w-full h-full",
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
          </.form>
          <button
            type="button"
            class={[
              "flex items-center gap-1 shrink-0 p-1 rounded-full text-ltrn-light bg-white shadow hover:bg-ltrn-lightest",
              "disabled:bg-ltrn-lighter disabled:shadow-none"
            ]}
            disabled={!@entry.id}
            phx-click="view_details"
            phx-target={@myself}
          >
            <.icon name="hero-chat-bubble-oval-left-mini" class={@note_icon_class} />
            <.icon name="hero-paper-clip-mini" class={@evidences_icon_class} />
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
    ~H"""
    <.select
      name={@field.name}
      prompt="—"
      options={@ov_options}
      value={@field.value}
      class={[
        "w-full h-full rounded-sm font-mono text-sm text-center truncate text-clip",
        @field.value in [nil, ""] && "bg-ltrn-lighter"
      ]}
      style={@style}
    />
    """
  end

  def marking_input(%{scale_type: "numeric"} = assigns) do
    # TODO: add min max based on scale

    ~H"""
    <.base_input
      name={@field.name}
      type="number"
      phx-debounce="1000"
      value={@field.value}
      errors={@field.errors}
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
        class="flex items-center justify-center h-full px-1 py-2 rounded-sm font-mono text-sm bg-white"
        style={@style}
      >
        <span class="truncate text-clip">
          <%= @value %>
        </span>
      </div>
    <% else %>
      <.empty />
    <% end %>
    """
  end

  def entry_view(%{entry: %{scale_type: "numeric"}} = assigns) do
    key =
      case assigns.view do
        "teacher" -> :score
        "student" -> :student_score
      end

    value = Map.get(assigns.entry, key)

    assigns = assign(assigns, :value, value)

    ~H"""
    <%= if @value do %>
      <div class="flex items-center justify-center h-full p-2 rounded-sm font-mono text-sm bg-white shadow-lg">
        <%= @value %>
      </div>
    <% else %>
      <.empty />
    <% end %>
    """
  end

  def empty(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-full p-2 rounded-sm font-mono text-sm text-ltrn-subtle bg-ltrn-lighter">
      —
    </div>
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

    # map format
    # %{
    #   scale_id: %{
    #     ov_map: %{ov_id: ov, ...},
    #     ov_style_map: %{ov_id: style, ...},
    #   },
    #   ...
    # }
    scale_ov_maps =
      Grading.list_scales(
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
            ov_options: build_ov_options(&1.ordinal_values)
          }
        }
      )
      |> Enum.into(%{})

    assigns_sockets
    |> Enum.map(&update_single(&1, scale_ov_maps))
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

  defp update_single({assigns, socket}, scale_ov_maps) do
    default_maps = %{ov_map: %{}, ov_style_map: %{}, ov_options: []}

    %{ov_map: ov_map, ov_style_map: ov_style_map, ov_options: ov_options} =
      Map.get(scale_ov_maps, assigns.entry.scale_id, default_maps)

    socket
    |> assign(assigns)
    |> assign_ov_values_and_styles(ov_map, ov_style_map)
    |> assign_form_and_related_assigns(ov_options)
    |> assign_grid_class()
  end

  defp assign_ov_values_and_styles(socket, ov_map, ov_style_map) do
    entry = socket.assigns.entry

    teacher_ov = Map.get(ov_map, entry.ordinal_value_id)
    teacher_ov_name = teacher_ov && teacher_ov.name
    teacher_ov_style = Map.get(ov_style_map, entry.ordinal_value_id)

    student_ov = Map.get(ov_map, entry.student_ordinal_value_id)
    student_ov_name = student_ov && student_ov.name
    student_ov_style = Map.get(ov_style_map, entry.student_ordinal_value_id)

    socket
    |> assign(:teacher_ov_name, teacher_ov_name)
    |> assign(:teacher_ov_style, teacher_ov_style)
    |> assign(:student_ov_name, student_ov_name)
    |> assign(:student_ov_style, student_ov_style)
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
      case view do
        "student" -> socket.assigns.student_ov_style
        "teacher" -> socket.assigns.teacher_ov_style
      end

    # when in student view, other value = teacher value (and vice-versa)
    {entry_value, other_value} =
      case {entry.scale_type, view} do
        {"ordinal", "student"} -> {entry.student_ordinal_value_id, entry.ordinal_value_id}
        {"ordinal", _teacher} -> {entry.ordinal_value_id, entry.student_ordinal_value_id}
        {"numeric", "student"} -> {entry.student_score, entry.score}
        {"numeric", _teacher} -> {entry.score, entry.student_score}
      end

    entry_note =
      case view do
        "student" -> entry.student_report_note
        _ -> entry.report_note
      end

    note_icon_class =
      cond do
        entry_note && view == "student" -> "text-ltrn-student-accent"
        entry_note -> "text-ltrn-teacher-accent"
        true -> ""
      end

    evidences_icon_class = if entry.has_evidences, do: "text-ltrn-primary", else: ""

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
  end

  defp assign_form_and_related_assigns(socket, _ov_options), do: assign(socket, :form, nil)

  defp get_field_for_form(form, "ordinal", "student"), do: form[:student_ordinal_value_id]
  defp get_field_for_form(form, "ordinal", _teacher), do: form[:ordinal_value_id]
  defp get_field_for_form(form, "numeric", "student"), do: form[:student_score]
  defp get_field_for_form(form, "numeric", _teacher), do: form[:score]

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

    {has_changes, change_type} =
      check_for_changes(entry.id, "#{entry_value}", socket.assigns.other_value, param_value)

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

  @spec check_for_changes(
          entry_id :: pos_integer(),
          entry_value :: String.t(),
          other_entry_value :: any(),
          param_value :: String.t()
        ) :: {boolean(), :cancel | :new | :delete | :edit}

  defp check_for_changes(_, entry_value, _, param_value) when entry_value == param_value,
    do: {false, :cancel}

  defp check_for_changes(nil, _, _, param_value) when param_value != "",
    do: {true, :new}

  defp check_for_changes(entry_id, _, nil, "") when not is_nil(entry_id),
    do: {true, :delete}

  defp check_for_changes(_, _, _, _), do: {true, :edit}
end
