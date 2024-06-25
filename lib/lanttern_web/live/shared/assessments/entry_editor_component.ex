defmodule LantternWeb.Assessments.EntryEditorComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :entry, Lanttern.Assessments.AssessmentPointEntry, required: true
  attr :wrapper_class, :any, doc: "use it to style the wrapping div"
  attr :class, :any, doc: "use it to style the form element"

  slot :marking_input do
    attr :class, :any
  end
  ```

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex items-center", @wrapper_class]}>
      <.form
        for={@form}
        phx-change="change"
        phx-target={@myself}
        class={[@class, if(@has_changes, do: "outline outline-4 outline-offset-1 outline-ltrn-dark")]}
        id={"entry-#{@id}-marking-form"}
      >
        <%= for marking_input <- @marking_input do %>
          <.marking_input
            scale={@assessment_point.scale}
            ordinal_value_options={@ordinal_value_options}
            form={@form}
            assessment_view={@assessment_view}
            style={if(@has_changes, do: "background-color: white", else: @ov_style)}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
      </.form>
      <button
        type="button"
        class={[
          "flex items-center gap-1 p-1 ml-2 rounded-full text-ltrn-light bg-white shadow hover:bg-ltrn-lightest",
          "disabled:bg-ltrn-lighter disabled:shadow-none"
        ]}
        disabled={!@entry.id}
        phx-click="view_details"
        phx-target={@myself}
      >
        <.icon name="hero-chat-bubble-oval-left-mini" class={@note_icon_class} />
        <.icon name="hero-paper-clip-mini" />
      </button>
    </div>
    """
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :style, :string
  attr :class, :any
  attr :form, :map, required: true
  attr :assessment_view, :string, required: true

  def marking_input(%{scale: %{type: "ordinal"}} = assigns) do
    field =
      case assigns.assessment_view do
        "student" -> assigns.form[:student_ordinal_value_id]
        _ -> assigns.form[:ordinal_value_id]
      end

    assigns = assign(assigns, :field, field)

    ~H"""
    <div class={@class}>
      <.select
        name={@field.name}
        prompt="—"
        options={@ordinal_value_options}
        value={@field.value}
        class={[
          "w-full h-full rounded-sm font-mono text-sm text-center truncate",
          @field.value in [nil, ""] && "bg-ltrn-lighter"
        ]}
        style={@style}
      />
    </div>
    """
  end

  def marking_input(%{scale: %{type: "numeric"}} = assigns) do
    field =
      case assigns.assessment_view do
        "student" -> assigns.form[:student_score]
        _ -> assigns.form[:score]
      end

    assigns = assign(assigns, :field, field)

    ~H"""
    <div class={@class}>
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
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:wrapper_class, nil)
      |> assign(:has_changes, false)
      |> assign(:assessment_view, "teacher")
      |> assign(:marking_input, [])

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{
      student: student,
      assessment_point: assessment_point,
      entry: entry
    } = assigns

    entry = entry || new_assessment_point_entry(assessment_point, student.id)

    form =
      entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:entry, entry)
      |> assign(:form, form)
      |> assign_ordinal_value_options()
      |> assign_entry_value()
      |> assign_entry_note()
      |> assign_ov_style()

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("change", %{"assessment_point_entry" => params}, socket) do
    %{
      entry: entry,
      assessment_view: assessment_view,
      entry_value: entry_value
    } = socket.assigns

    form =
      entry
      |> Assessments.change_assessment_point_entry(params)
      |> to_form()

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
    param_value = get_param_value(params, assessment_view)

    # when in student view, other value = teacher value (and vice-versa)
    other_entry_value = get_other_entry_value(entry, assessment_view)

    {has_changes, change_type} =
      check_for_changes(entry.id, "#{entry_value}", other_entry_value, param_value)

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

  defp new_assessment_point_entry(assessment_point, student_id) do
    %AssessmentPointEntry{
      student_id: student_id,
      assessment_point_id: assessment_point.id,
      scale_id: assessment_point.scale.id,
      scale_type: assessment_point.scale.type
    }
  end

  defp assign_ordinal_value_options(
         %{assigns: %{assessment_point: %{scale: %{type: "ordinal"}}}} = socket
       ) do
    ordinal_value_options =
      socket.assigns.assessment_point.scale.ordinal_values
      |> Enum.map(fn ov -> {ov.name, ov.id} end)

    assign(socket, :ordinal_value_options, ordinal_value_options)
  end

  defp assign_ordinal_value_options(socket),
    do: assign(socket, :ordinal_value_options, [])

  defp assign_entry_value(socket) do
    %{
      entry: entry,
      assessment_view: assessment_view,
      assessment_point: %{scale: %{type: scale_type}}
    } = socket.assigns

    entry_value =
      case {scale_type, assessment_view} do
        {"ordinal", "student"} -> entry.student_ordinal_value_id
        {"numeric", "student"} -> entry.student_score
        {"ordinal", _teacher} -> entry.ordinal_value_id
        {"numeric", _teacher} -> entry.score
      end

    assign(socket, :entry_value, entry_value)
  end

  defp assign_entry_note(socket) do
    %{
      entry: entry,
      assessment_view: assessment_view
    } = socket.assigns

    entry_note =
      case assessment_view do
        "student" -> entry.student_report_note
        _ -> entry.report_note
      end

    note_icon_class =
      cond do
        entry_note && assessment_view == "student" -> "text-ltrn-student-accent"
        entry_note -> "text-ltrn-teacher-accent"
        true -> ""
      end

    socket
    |> assign(:entry_note, entry_note)
    |> assign(:note_icon_class, note_icon_class)
  end

  defp assign_ov_style(socket) do
    %{
      entry_value: entry_value,
      assessment_point: %{scale: %{ordinal_values: ordinal_values, type: scale_type}}
    } = socket.assigns

    ov_style =
      case {scale_type, entry_value} do
        {"ordinal", ordinal_value_id} when not is_nil(ordinal_value_id) ->
          ordinal_values
          |> Enum.find(&(&1.id == ordinal_value_id))
          |> get_colors_style()

        _ ->
          nil
      end

    socket
    |> assign(:ov_style, ov_style)
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""

  @spec get_param_value(params :: map(), view :: String.t()) :: String.t()
  defp get_param_value(%{"scale_type" => "ordinal"} = params, "student"),
    do: params["student_ordinal_value_id"]

  defp get_param_value(%{"scale_type" => "numeric"} = params, "student"),
    do: params["student_score"]

  defp get_param_value(%{"scale_type" => "ordinal"} = params, _teacher),
    do: params["ordinal_value_id"]

  defp get_param_value(%{"scale_type" => "numeric"} = params, _teacher),
    do: params["score"]

  @spec get_other_entry_value(entry :: AssessmentPointEntry.t(), view :: String.t()) ::
          float() | pos_integer() | nil
  defp get_other_entry_value(%{scale_type: "ordinal"} = entry, "student"),
    do: entry.ordinal_value_id

  defp get_other_entry_value(%{scale_type: "numeric"} = entry, "student"),
    do: entry.score

  defp get_other_entry_value(%{scale_type: "ordinal"} = entry, _teacher),
    do: entry.student_ordinal_value_id

  defp get_other_entry_value(%{scale_type: "numeric"} = entry, _teacher),
    do: entry.student_score

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
