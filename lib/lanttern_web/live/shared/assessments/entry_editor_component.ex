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

  def render(assigns) do
    ~H"""
    <div class={@wrapper_class}>
      <.form
        for={@form}
        phx-change="save"
        phx-target={@myself}
        class={@class}
        id={"entry-#{@id}-marking-form"}
      >
        <%= for marking_input <- @marking_input do %>
          <.marking_input
            scale={@assessment_point.scale}
            ordinal_value_options={@ordinal_value_options}
            form={@form}
            style={@ov_style}
            ov_name={@ov_name}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
      </.form>
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

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:entry, entry)
     |> assign(:ov_style, ov_style)
     |> assign(:ov_name, ov_name)
     |> assign(:form, form)
     |> assign(:ordinal_value_options, ordinal_value_options)
     |> assign(:wrapper_class, Map.get(assigns, :wrapper_class, ""))
     |> assign(:class, Map.get(assigns, :class, ""))
     |> assign(:marking_input, Map.get(assigns, :marking_input, []))}
  end

  # event handlers

  def handle_event(
        "save",
        %{"assessment_point_entry" => params},
        %{assigns: %{entry: entry}} = socket
      ) do
    entry_params =
      entry
      |> Map.from_struct()
      |> Map.take([:student_id, :assessment_point_id, :scale_id, :scale_type])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    # add extra fields from entry
    params =
      params
      |> Enum.into(entry_params)

    case {
      entry.id,
      entry.scale_type,
      params["ordinal_value_id"],
      params["score"]
    } do
      {nil, "ordinal", ov_id, _} when ov_id != "" -> save(:new, entry, params, socket)
      {nil, "numeric", _, score} when score != "" -> save(:new, entry, params, socket)
      {id, "ordinal", "", _} when not is_nil(id) -> save(:delete, entry, params, socket)
      {id, "numeric", _, ""} when not is_nil(id) -> save(:delete, entry, params, socket)
      {id, _, _, _} when not is_nil(id) -> save(:edit, entry, params, socket)
      _ -> {:noreply, socket}
    end
  end

  defp save(:new, _entry, params, socket) do
    case Assessments.create_assessment_point_entry(params, preloads: :ordinal_value) do
      {:ok, assessment_point_entry} ->
        {:noreply, handle_create_update_success(assessment_point_entry, socket)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save(:edit, entry, params, socket) do
    case Assessments.update_assessment_point_entry(entry, params,
           preloads: :ordinal_value,
           force_preloads: true
         ) do
      {:ok, assessment_point_entry} ->
        {:noreply, handle_create_update_success(assessment_point_entry, socket)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save(:delete, entry, _params, socket) do
    case Assessments.delete_assessment_point_entry(entry) do
      {:ok, _assessment_point_entry} ->
        new_entry =
          new_assessment_point_entry(socket.assigns.assessment_point, socket.assigns.student.id)

        form =
          new_entry
          |> Assessments.change_assessment_point_entry()
          |> to_form()

        {:noreply,
         socket
         |> assign(:ov_style, nil)
         |> assign(:ov_name, nil)
         |> assign(:form, form)
         |> assign(:entry, new_entry)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp handle_create_update_success(assessment_point_entry, socket) do
    {ov_style, ov_name} =
      case assessment_point_entry.ordinal_value do
        %{name: name} = ov ->
          {get_colors_style(ov), name}

        _ ->
          {nil, nil}
      end

    form =
      assessment_point_entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket
    |> assign(:entry, assessment_point_entry)
    |> assign(:ov_style, ov_style)
    |> assign(:ov_name, ov_name)
    |> assign(:form, form)
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
