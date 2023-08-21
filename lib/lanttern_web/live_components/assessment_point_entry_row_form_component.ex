defmodule LantternWeb.AssessmentPointEntryRowFormComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :entry, :map, required: true
  ```

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-change="save" class="flex items-stretch gap-2 mt-4" phx-target={@myself}>
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <div class="self-center shrink-0 w-1/4 flex gap-2 items-center text-sm">
          <.profile_icon profile_name={@student_name} /> <%= @student_name %>
        </div>
        <.marking_column
          scale={@scale}
          ordinal_value_options={@ordinal_value_options}
          form={@form}
          style={@ov_style}
          ov_name={@ov_name}
        />
        <div class="flex-[2_0]">
          <.textarea
            name="assessment_point_entry[observation]"
            phx-debounce="1000"
            value={@form[:observation].value}
            class={@form[:observation].value == nil && "bg-slate-200"}
          />
        </div>
      </.form>
    </div>
    """
  end

  def update(
        %{entry: entry, scale: scale, ordinal_value_options: ordinal_value_options} = _assigns,
        socket
      ) do
    {ov_style, ov_name} =
      case entry.ordinal_value do
        %{name: name} = ov ->
          {get_colors_style(ov), name}

        _ ->
          {nil, nil}
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
      |> assign(:student_name, entry.student.name)
      |> assign(:scale, scale)
      |> assign(:ordinal_value_options, ordinal_value_options)

    {:ok, socket}
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list
  attr :style, :string
  attr :ov_name, :string
  attr :form, :map, required: true

  def marking_column(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <div class="relative flex-[2_0]">
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

  def marking_column(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <div class="flex-[1_0]">
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
        send(self(), {:save_error, changeset})
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
