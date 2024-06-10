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
  alias Lanttern.Assessments.AssessmentPointEntry
  use LantternWeb, :live_component

  alias Lanttern.Assessments
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
            style={if(!@has_changes, do: @ov_style)}
            ov_name={@ov_name}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
      </.form>
      <.icon_button
        type="button"
        name="hero-pencil-square-mini"
        theme={@note_button_theme}
        rounded
        sr_text={gettext("Add entry note")}
        size="sm"
        class="ml-2"
        disabled={!@entry_value}
        phx-click="edit_note"
        phx-target={@myself}
      />
      <.modal
        :if={@is_editing_note}
        id={"entry-#{@id}-note-modal"}
        show
        on_cancel={JS.push("cancel_edit_note", target: @myself)}
      >
        <h5 class="mb-10 font-display font-black text-xl">
          <%= gettext("Entry report note") %>
        </h5>
        <.form for={@form} phx-submit="save_note" phx-target={@myself} id={"entry-#{@id}-note-form"}>
          <.input
            field={
              if @assessment_view == "student",
                do: @form[:student_report_note],
                else: @form[:report_note]
            }
            type="textarea"
            label={gettext("Note")}
            class="mb-1"
            phx-debounce="1500"
          />
          <.markdown_supported />
          <div class="flex justify-end mt-10">
            <.button type="submit"><%= gettext("Save note") %></.button>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :style, :string
  attr :class, :any
  attr :ov_name, :string
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
      |> assign(:is_editing_note, false)
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
      |> assign_ov_style_and_name()

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("change", %{"assessment_point_entry" => params}, socket) do
    %{
      entry: %{scale_type: scale_type} = entry,
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

    composite_id = "#{entry_params["student_id"]}_#{entry_params["assessment_point_id"]}"

    # add extra fields from entry
    params =
      params
      |> Enum.into(entry_params)

    param_value =
      case {params, assessment_view} do
        {%{"scale_type" => "ordinal"}, "student"} -> params["student_ordinal_value_id"]
        {%{"scale_type" => "numeric"}, "student"} -> params["student_score"]
        {%{"scale_type" => "ordinal"}, _teacher} -> params["ordinal_value_id"]
        {%{"scale_type" => "numeric"}, _teacher} -> params["score"]
      end

    # when in student view, other value
    # is the teacher value (and vice versa)
    other_entry_value =
      case {scale_type, assessment_view} do
        {"ordinal", "student"} -> entry.ordinal_value_id
        {"numeric", "student"} -> entry.score
        {"ordinal", _teacher} -> entry.student_ordinal_value_id
        {"numeric", _teacher} -> entry.student_score
      end

    # types: new, delete, edit, cancel
    {change_type, has_changes} =
      case {entry.id, "#{entry_value}", other_entry_value, param_value} do
        {_, entry_value, _, param_value} when entry_value == param_value ->
          {:cancel, false}

        {nil, _, _, param_value} when param_value != "" ->
          {:new, true}

        {entry_id, _, nil, ""} when not is_nil(entry_id) ->
          {:delete, true}

        _ ->
          {:edit, true}
      end

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

  @impl true
  def handle_event("edit_note", _, socket) do
    {:noreply, assign(socket, :is_editing_note, true)}
  end

  @impl true
  def handle_event("cancel_edit_note", _, socket) do
    {:noreply, assign(socket, :is_editing_note, false)}
  end

  @impl true
  def handle_event("save_note", %{"assessment_point_entry" => params}, socket) do
    opts = [log_profile_id: socket.assigns.current_user.current_profile_id]

    socket =
      case Assessments.update_assessment_point_entry(socket.assigns.entry, params, opts) do
        {:ok, entry} ->
          form =
            entry
            |> Assessments.change_assessment_point_entry(params)
            |> to_form()

          socket
          |> assign(:entry, entry)
          |> assign(:form, form)
          |> assign(:is_editing_note, false)
          |> assign_entry_note()
      end

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
      |> Enum.map(fn ov -> {:"#{ov.name}", ov.id} end)

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
      entry_value: entry_value,
      assessment_view: assessment_view
    } = socket.assigns

    entry_note =
      case assessment_view do
        "student" -> entry.student_report_note
        _ -> entry.report_note
      end

    note_button_theme =
      cond do
        entry_note && entry_value && assessment_view == "student" -> "student"
        entry_note && entry_value -> "teacher"
        true -> "ghost"
      end

    socket
    |> assign(:entry_note, entry_note)
    |> assign(:note_button_theme, note_button_theme)
  end

  defp assign_ov_style_and_name(socket) do
    %{
      entry_value: entry_value,
      assessment_point: %{scale: %{ordinal_values: ordinal_values, type: scale_type}}
    } = socket.assigns

    {ov_style, ov_name} =
      case {scale_type, entry_value} do
        {"ordinal", ordinal_value_id} when not is_nil(ordinal_value_id) ->
          ov =
            ordinal_values
            |> Enum.find(&(&1.id == ordinal_value_id))

          {get_colors_style(ov), ov.name}

        _ ->
          {nil, nil}
      end

    socket
    |> assign(:ov_style, ov_style)
    |> assign(:ov_name, ov_name)
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
