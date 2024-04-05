defmodule LantternWeb.Assessments.AsyncEntryEditorComponent do
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
            style={if(!@has_changes, do: @ov_style)}
            ov_name={@ov_name}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
      </.form>
      <.icon_button
        type="button"
        name="hero-pencil-square-mini"
        theme={if @entry.report_note, do: "diff_light", else: "ghost"}
        rounded
        sr_text={gettext("Add entry note")}
        size="sm"
        class="ml-2"
        disabled={!@entry.id || @has_changes}
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
            field={@form[:report_note]}
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

  def marking_input(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div class={@class}>
      <.select
        name={@form[:ordinal_value_id].name}
        prompt="—"
        options={@ordinal_value_options}
        value={@form[:ordinal_value_id].value}
        class={[
          "w-full h-full rounded-sm font-mono text-sm text-center truncate",
          @form[:ordinal_value_id].value == nil && "bg-ltrn-lighter"
        ]}
        style={@style}
      />
    </div>
    """
  end

  def marking_input(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div class={@class}>
      <.base_input
        name={@form[:score].name}
        type="number"
        phx-debounce="1000"
        value={@form[:score].value}
        errors={@form[:score].errors}
        class={[
          "h-full font-mono text-center",
          @form[:score].value == nil && "bg-ltrn-lighter"
        ]}
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  # lifecycle

  def update(
        %{
          student: student,
          assessment_point: assessment_point,
          entry: entry
        } = assigns,
        socket
      ) do
    %{scale: %{ordinal_values: ordinal_values}} = assessment_point
    ordinal_value_options = Enum.map(ordinal_values, fn ov -> {:"#{ov.name}", ov.id} end)
    entry = entry || new_assessment_point_entry(assessment_point, student.id)

    {ov_style, ov_name} =
      case entry do
        %{ordinal_value_id: nil} ->
          {nil, nil}

        %{ordinal_value_id: ordinal_value_id} ->
          ov =
            ordinal_values
            |> Enum.find(&(&1.id == ordinal_value_id))

          {get_colors_style(ov), ov.name}
      end

    form =
      entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:entry, entry)
      |> assign(:ov_style, ov_style)
      |> assign(:ov_name, ov_name)
      |> assign(:form, form)
      |> assign(:ordinal_value_options, ordinal_value_options)
      |> assign(:wrapper_class, Map.get(assigns, :wrapper_class, ""))
      |> assign(:class, Map.get(assigns, :class, ""))
      |> assign(:marking_input, Map.get(assigns, :marking_input, []))
      |> assign(:has_changes, false)
      |> assign(:is_editing_note, false)

    {:ok, socket}
  end

  # event handlers

  def handle_event("change", %{"assessment_point_entry" => params}, socket) do
    entry = socket.assigns.entry

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

    # types: new, delete, edit, cancel
    {change_type, has_changes} =
      case {entry, params} do
        {
          %{id: nil, scale_type: "ordinal"},
          %{"ordinal_value_id" => ov_id}
        }
        when ov_id != "" ->
          {:new, true}

        {
          %{id: nil, scale_type: "numeric"},
          %{"score" => score}
        }
        when score != "" ->
          {:new, true}

        {%{id: nil}, _} ->
          {:cancel, false}

        {
          %{id: id, scale_type: "ordinal"},
          %{"ordinal_value_id" => ""}
        }
        when not is_nil(id) ->
          {:delete, true}

        {
          %{id: id, scale_type: "numeric"},
          %{"score" => ""}
        }
        when not is_nil(id) ->
          {:delete, true}

        {
          %{id: id, scale_type: "ordinal", ordinal_value_id: entry_ov_id},
          %{"ordinal_value_id" => ov_id}
        }
        when not is_nil(id) ->
          if "#{entry_ov_id}" == ov_id,
            do: {:cancel, false},
            else: {:edit, true}

        {
          %{id: id, scale_type: "numeric", score: entry_score},
          %{"score" => score}
        }
        when not is_nil(id) ->
          if "#{entry_score}" == score,
            do: {:cancel, false},
            else: {:edit, true}
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

  def handle_event("edit_note", _, socket) do
    {:noreply, assign(socket, :is_editing_note, true)}
  end

  def handle_event("cancel_edit_note", _, socket) do
    {:noreply, assign(socket, :is_editing_note, false)}
  end

  def handle_event("save_note", %{"assessment_point_entry" => params}, socket) do
    socket =
      case Assessments.update_assessment_point_entry(socket.assigns.entry, params) do
        {:ok, entry} ->
          form =
            entry
            |> Assessments.change_assessment_point_entry(params)
            |> to_form()

          socket
          |> assign(:entry, entry)
          |> assign(:form, form)
          |> assign(:is_editing_note, false)
      end

    {:noreply, socket}
  end

  # helpers

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""

  defp new_assessment_point_entry(assessment_point, student_id) do
    %AssessmentPointEntry{
      student_id: student_id,
      assessment_point_id: assessment_point.id,
      scale_id: assessment_point.scale.id,
      scale_type: assessment_point.scale.type
    }
  end
end
