defmodule LantternWeb.Rubrics.RubricFormComponent do
  @doc """
  Rubrics form component.

  This form is used inside a `<.slide_over>` component,
  where the "submit" button is rendered.
  """
  use LantternWeb, :live_component

  alias Lanttern.Rubrics
  alias Lanttern.Assessments
  alias Lanttern.Grading
  import LantternWeb.GradingHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id={"rubric-form-#{@id}"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <.input field={@form[:id]} type="hidden" />
        <.input field={@form[:diff_for_rubric_id]} type="hidden" />
        <.input field={@form[:criteria]} type="text" label="Criteria" phx-debounce="1500" />
        <.input
          field={@form[:is_differentiation]}
          type="toggle"
          label="Is differentiation"
          class={["mt-6", if(@hide_diff_and_scale, do: "hidden")]}
        />
        <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select scale"
          phx-target={@myself}
          phx-change="scale_selected"
          class={["mt-6", if(@hide_diff_and_scale, do: "hidden")]}
        />
        <.descriptors_fields scale={@scale} field={@form[:descriptors]} myself={@myself} />
        <div :if={@show_buttons} class="flex justify-end gap-2 mt-6">
          <.button type="button" theme="ghost" phx-click={@on_cancel}>Cancel</.button>
          <.button type="submit">Save</.button>
        </div>
      </.form>
    </div>
    """
  end

  attr :scale, :map, required: true
  attr :field, :map, required: true
  attr :myself, :any, required: true

  defp descriptors_fields(%{scale: nil} = assigns) do
    ~H"""
    <p class="mt-6 text-ltrn-subtle">Select a scale to create descriptors</p>
    """
  end

  defp descriptors_fields(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <h5 class="mt-10 font-display font-black text-ltrn-subtle">Descriptors</h5>
    <.markdown_supported class="mt-2 mb-6" message="Markdown supported in descriptors" />
    <.inputs_for :let={ef} field={@field}>
      <.input type="hidden" field={ef[:scale_id]} />
      <.input type="hidden" field={ef[:scale_type]} />
      <.input type="hidden" field={ef[:ordinal_value_id]} />
      <.input type="textarea" field={ef[:descriptor]} class="mt-6">
        <:custom_label>
          <.ordinal_value_label
            ordinal_values={@scale.ordinal_values}
            ordinal_value_id={ef[:ordinal_value_id].value}
          />
        </:custom_label>
      </.input>
    </.inputs_for>
    """
  end

  defp descriptors_fields(%{scale: %{type: "numeric"}} = assigns) do
    ~H"""
    <h5 class="mt-10 font-display font-black text-ltrn-subtle">Descriptors</h5>
    <.markdown_supported class="mt-2 mb-6" message="Markdown supported in descriptors" />
    <.inputs_for :let={ef} field={@field}>
      <div class="flex gap-6">
        <div class="flex-1">
          <.input type="hidden" field={ef[:scale_id]} />
          <.input type="hidden" field={ef[:scale_type]} />
          <.input
            type="number"
            min={@scale.start}
            max={@scale.stop}
            field={ef[:score]}
            label="Score"
            class="mt-6"
          />
          <.input type="textarea" field={ef[:descriptor]} />
        </div>
        <label class="shrink-0 mt-14">
          <input type="checkbox" name="rubric[remove_descriptor]" value={ef.index} class="hidden" />
          <.icon name="hero-minus-circle" class="shrink-0 w-6 h-6 text-ltrn-subtle" />
        </label>
      </div>
    </.inputs_for>

    <label class={[get_button_styles("ghost"), "mt-6"]}>
      <input type="checkbox" name="rubric[add_descriptor]" class="hidden" /> Add descriptor
    </label>
    """
  end

  attr :ordinal_values, :list, required: true
  attr :ordinal_value_id, :integer, required: true

  defp ordinal_value_label(
         %{
           ordinal_values: ordinal_values,
           ordinal_value_id: ordinal_value_id
         } = assigns
       ) do
    assigns =
      assigns
      |> assign(
        :ordinal_value,
        ordinal_values
        |> Enum.find(&(ordinal_value_id in [&1.id, "#{&1.id}"]))
      )

    ~H"""
    <.badge style_from_ordinal_value={@ordinal_value}>
      <%= @ordinal_value.name %>
    </.badge>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    scale_options = generate_scale_options()

    socket =
      socket
      |> assign(:scale_options, scale_options)
      |> assign(:scale, nil)
      |> assign(:hide_diff_and_scale, false)
      |> assign(:class, nil)
      |> assign(:show_buttons, false)
      |> assign(:notify_parent, true)
      |> assign(:link_to_assessment_point_id, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{rubric: rubric} = assigns, socket) do
    scale =
      case rubric.scale_id do
        nil -> nil
        scale_id -> Grading.get_scale!(scale_id, preloads: :ordinal_values)
      end

    changeset =
      case {rubric.id, scale} do
        {nil, nil} ->
          Rubrics.change_rubric(rubric)

        {nil, scale} ->
          # if scale is selected and rubric is new, generate empty descriptors
          Rubrics.change_rubric(
            rubric,
            %{"descriptors" => generate_new_descriptors(scale)}
          )

        _ ->
          Rubrics.change_rubric(rubric)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:scale, scale)
     |> assign_form(changeset)}
  end

  # event handlers

  @impl true
  def handle_event("scale_selected", %{"rubric" => %{"scale_id" => ""}}, socket) do
    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(
        socket.assigns.form.params
        |> Map.put("descriptors", %{})
        # at this point, socket form params represents the last change,
        # not the scale id change. so we add it manually
        |> Map.put("scale_id", "")
      )

    socket =
      socket
      |> assign(:scale, nil)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("scale_selected", %{"rubric" => %{"scale_id" => scale_id}}, socket) do
    scale = Grading.get_scale!(scale_id, preloads: :ordinal_values)
    descriptors = generate_new_descriptors(scale)

    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(
        socket.assigns.form.params
        |> Map.put("descriptors", descriptors)
        # at this point, socket form params represents the last change,
        # not the scale id change. so we add it manually
        |> Map.put("scale_id", scale_id)
      )

    socket =
      socket
      |> assign(:scale, scale)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("validate", %{"rubric" => %{"add_descriptor" => "on"} = rubric_params}, socket) do
    %{scale: scale} = socket.assigns

    blank_descriptor = blank_numeric_descriptor(scale)

    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(
        rubric_params
        |> Map.delete("add_descriptor")
        |> Map.update("descriptors", %{"0" => blank_descriptor}, fn descriptors ->
          i = length(Map.keys(descriptors))
          Map.put(descriptors, "#{i}", blank_descriptor)
        end)
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event(
        "validate",
        %{"rubric" => %{"remove_descriptor" => index} = rubric_params},
        socket
      ) do
    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(
        rubric_params
        |> Map.update("descriptors", %{}, &Map.delete(&1, index))
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("validate", %{"rubric" => rubric_params}, socket) do
    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(rubric_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"rubric" => rubric_params}, socket) do
    # force "descriptors" be present in params for removing descriptors on cast_assoc
    rubric_params =
      rubric_params
      |> Map.put_new("descriptors", %{})

    action =
      case rubric_params["id"] do
        "" -> :new
        _id -> :edit
      end

    save_rubric(socket, action, rubric_params)
  end

  defp generate_new_descriptors(scale) do
    case scale.type do
      "ordinal" ->
        scale.ordinal_values
        |> Enum.map(
          &%{
            scale_id: &1.scale_id,
            scale_type: scale.type,
            ordinal_value_id: &1.id,
            descriptor: "—"
          }
        )

      "numeric" ->
        %{
          "0" =>
            blank_numeric_descriptor(scale)
            |> Map.put("score", scale.start),
          "1" =>
            blank_numeric_descriptor(scale)
            |> Map.put("score", scale.stop)
        }
    end
  end

  defp blank_numeric_descriptor(scale) do
    %{
      "scale_id" => scale.id,
      "scale_type" => scale.type,
      "score" => "",
      "descriptor" => ""
    }
  end

  defp save_rubric(socket, :edit, rubric_params) do
    case Rubrics.update_rubric(socket.assigns.rubric, rubric_params, preloads: :scale) do
      {:ok, rubric} ->
        notify(socket.assigns, {:updated, rubric})

        {:noreply,
         socket
         |> put_flash(:info, "Rubric updated successfully")
         |> handle_navigation()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_rubric(socket, :new, rubric_params) do
    case socket.assigns do
      %{diff_for_student_id: student_id} when not is_nil(student_id) ->
        Rubrics.create_diff_rubric_for_student(student_id, rubric_params)

      %{link_to_assessment_point_id: assessment_point_id} when not is_nil(assessment_point_id) ->
        Assessments.create_assessment_point_rubric(assessment_point_id, rubric_params)

      _ ->
        Rubrics.create_rubric(rubric_params, preloads: :scale)
    end
    |> case do
      {:ok, rubric} ->
        notify(socket.assigns, {:created, rubric})

        {:noreply,
         socket
         |> put_flash(:info, "Rubric created successfully")
         |> handle_navigation()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}

      {:error, msg} ->
        {:noreply,
         socket
         |> put_flash(:error, msg)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify(assigns, msg) do
    maybe_notify_parent(assigns, msg)
    maybe_notify_component(assigns, msg)
  end

  defp maybe_notify_parent(%{notify_parent: true}, msg), do: send(self(), {__MODULE__, msg})

  defp maybe_notify_parent(_assigns, _msg), do: nil

  defp maybe_notify_component(%{notify_component: %Phoenix.LiveComponent.CID{} = cid}, msg) do
    send_update(cid, action: {__MODULE__, msg})
  end

  defp maybe_notify_component(_assigns, _msg), do: nil
end
