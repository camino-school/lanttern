defmodule LantternWeb.AssessmentPointEntryEditorComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :entry, Lanttern.Assessments.AssessmentPointEntry, required: true
  attr :wrapper_class, :any, doc: "use it to style the wrapping div"
  attr :class, :any, doc: "use it to style the form element"

  slot :marking_input do
    attr :class, :any
  end

  slot :observation_input do
    attr :class, :any
  end
  ```

  """
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
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <%= for marking_input <- @marking_input do %>
          <.marking_input
            scale={@scale}
            ordinal_value_options={@ordinal_value_options}
            form={@form}
            style={@ov_style}
            ov_name={@ov_name}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
        <%= for observation_input <- @observation_input do %>
          <div class={Map.get(observation_input, :class, "")}>
            <.textarea
              name={@form[:observation].name}
              value={@form[:observation].value}
              class={@form[:observation].value == nil && "bg-ltrn-hairline"}
              phx-debounce="1000"
            />
          </div>
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
    <div class={["relative", @class]}>
      <div
        class={[
          "flex items-center justify-center w-full h-full rounded-sm font-mono text-sm pointer-events-none truncate",
          @form[:ordinal_value_id].value == nil && "bg-ltrn-hairline"
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
    <div class={@class}>
      <.base_input
        name={@form[:score].name}
        type="number"
        phx-debounce="1000"
        value={@form[:score].value}
        errors={@form[:score].errors}
        class={[
          "h-full font-mono text-center",
          @form[:score].value == nil && "bg-ltrn-hairline"
        ]}
        min={@scale.start}
        max={@scale.stop}
      />
    </div>
    """
  end

  # lifecycle

  def preload(list_of_assigns) do
    assessment_points_ids =
      list_of_assigns
      |> Enum.map(fn assigns -> assigns.entry.assessment_point_id end)
      |> Enum.uniq()

    assessment_points =
      Assessments.list_assessment_points(
        preloads: [scale: :ordinal_values],
        assessment_points_ids: assessment_points_ids
      )
      |> Enum.map(fn assessment_point -> {assessment_point.id, assessment_point} end)
      |> Map.new()

    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :assessment_point, assessment_points[assigns.entry.assessment_point_id])
    end)
  end

  def update(%{entry: entry, id: id, assessment_point: assessment_point} = assigns, socket) do
    %{scale: scale} = assessment_point
    %{ordinal_values: ordinal_values} = scale
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
      |> assign(:wrapper_class, Map.get(assigns, :wrapper_class, ""))
      |> assign(:class, Map.get(assigns, :class, ""))
      |> assign(:marking_input, Map.get(assigns, :marking_input, []))
      |> assign(:observation_input, Map.get(assigns, :observation_input, []))

    {:ok, socket}
  end

  # event handlers

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
        send(self(), {:assessment_point_entry_save_error, changeset})
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
