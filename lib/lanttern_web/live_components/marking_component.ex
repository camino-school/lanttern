defmodule LantternWeb.MarkingComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :entry, Lanttern.Assessments.AssessmentPointEntry, required: true
  ```

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <.form
        for={@form}
        phx-change="save"
        phx-target={@myself}
        class="w-full h-full"
        id={"entry-#{@id}-marking-form"}
      >
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <.marking_input
          scale={@scale}
          ordinal_value_options={@ordinal_value_options}
          form={@form}
          style={@ov_style}
          ov_name={@ov_name}
        />
      </.form>
    </div>
    """
  end

  def update(%{entry: entry, id: id}, socket) do
    # , scale: scale, ordinal_value_options: ordinal_value_options
    assessment_point = Assessments.get_assessment_point!(entry.assessment_point_id)
    scale = Grading.get_scale!(assessment_point.scale_id)
    ordinal_values = Grading.list_ordinal_values_from_scale(scale.id)
    ordinal_value_options = Enum.map(ordinal_values, fn ov -> {:"#{ov.name}", ov.id} end)

    {ov_style, ov_name} =
      case entry.ordinal_value_id do
        nil ->
          {nil, nil}

        ordinal_value_id ->
          ov =
            ordinal_values
            |> Enum.find(&(&1.id == ordinal_value_id))

          {get_colors_style(ov), ov.name}
      end

    form =
      entry
      |> Assessments.change_assessment_point_entry(%{})
      |> to_form()

    socket =
      socket
      |> assign(:ov_style, ov_style)
      |> assign(:ov_name, ov_name)
      |> assign(:form, form)
      |> assign(:scale, scale)
      |> assign(:ordinal_value_options, ordinal_value_options)
      |> assign(:id, id)

    {:ok, socket}
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :style, :string
  attr :ov_name, :string
  attr :form, :map, required: true

  def marking_input(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div class="relative w-full h-full">
      <div
        class={[
          "flex items-center justify-center w-full h-full rounded-sm font-mono text-sm pointer-events-none",
          @form[:ordinal_value_id].value == nil && "bg-slate-200"
        ]}
        style={@style}
      >
        <%= @ov_name || "—" %>
      </div>
      <.select
        name={@form[:ordinal_value_id].name}
        prompt="—"
        options={@ordinal_value_options}
        value={@form[:ordinal_value_id].value}
        class="absolute inset-0 text-center text-transparent"
        style="background-color: transparent"
      />
    </div>
    """
  end

  def marking_input(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div class="w-full h-full">
      <.base_input
        name={@form[:score].name}
        type="number"
        phx-debounce="1000"
        value={@form[:score].value}
        errors={@form[:score].errors}
        class={[
          "h-full font-mono text-center",
          @form[:score].value == nil && "bg-slate-200"
        ]}
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  def handle_event("save", %{"assessment_point_entry" => params}, socket) do
    cur_entry = Assessments.get_assessment_point_entry!(params["id"])

    case Assessments.update_assessment_point_entry(cur_entry, params,
           preloads: [:student, :ordinal_value],
           force_preloads: true
         ) do
      {:ok, assessment_point_entry} ->
        {ov_style, ov_name} =
          case assessment_point_entry.ordinal_value do
            %{name: name} = ov ->
              {get_colors_style(ov), name}

            _ ->
              {nil, nil}
          end

        form =
          assessment_point_entry
          |> Assessments.change_assessment_point_entry(%{})
          |> to_form()

        socket =
          socket
          |> assign(:ov_style, ov_style)
          |> assign(:ov_name, ov_name)
          |> assign(:form, form)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        send(self(), {:marking_save_error, changeset})
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
