defmodule LantternWeb.Rubrics.AssessmentPointRubricFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `AssessmentPointRubric` form

  ### Attrs

      attr :assessment_point_rubric_id, :integer, required: true, doc: "use `:new` when creating new rubric"
      attr :assessment_point_id, :integer, doc: "required when creating new rubric"
      attr :is_diff, :boolean, doc: "used when creating new rubric"
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID
  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Rubrics.AssessmentPointRubric
  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over :if={@assessment_point_rubric_id} id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <p class="mb-6">
          <strong class="inline-block mr-2 font-display font-bold">
            <%= @assessment_point.curriculum_item.curriculum_component.name %>
          </strong>
          <%= @assessment_point.curriculum_item.name %>
        </p>
        <p
          :if={@assessment_point_rubric.is_diff}
          class="p-4 rounded mb-6 text-ltrn-diff-dark bg-ltrn-diff-lightest"
        >
          <%= gettext("Differentiation rubric") %>
        </p>
        <.form
          for={@form}
          id={"rubric-form-#{@id}"}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.error_block :if={@form.source.action == :insert} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:criteria]}
            type="text"
            label={gettext("Criteria")}
            phx-debounce="1500"
          />
          <.descriptors_fields scale={@scale} field={@form[:descriptors]} myself={@myself} />
        </.form>
        <:actions_left :if={@rubric.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <%= gettext("Cancel") %>
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form={"rubric-form-#{@id}"}
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  attr :scale, :map, required: true
  attr :field, :map, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  defp descriptors_fields(%{scale: nil} = assigns) do
    ~H"""
    <p class="mt-6 text-ltrn-subtle"><%= gettext("Select a scale to create descriptors") %></p>
    """
  end

  defp descriptors_fields(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <h5 class="mt-10 font-display font-black text-ltrn-subtle"><%= gettext("Descriptors") %></h5>
    <.markdown_supported class="mt-2 mb-6" message={gettext("Markdown supported in descriptors")} />
    <.inputs_for :let={ef} field={@field}>
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
    <h5 class="mt-10 font-display font-black text-ltrn-subtle"><%= gettext("Descriptors") %></h5>
    <.markdown_supported class="mt-2 mb-6" message={gettext("Markdown supported in descriptors")} />
    <.inputs_for :let={ef} field={@field}>
      <div class="flex gap-6">
        <div class="flex-1">
          <.input
            type="number"
            min={@scale.start}
            max={@scale.stop}
            field={ef[:score]}
            label={gettext("Score")}
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
      <input type="checkbox" name="rubric[add_descriptor]" class="hidden" /> <%= gettext(
        "Add descriptor"
      ) %>
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
    <.badge color_map={@ordinal_value}>
      <%= @ordinal_value.name %>
    </.badge>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:scale, nil)
      |> assign(:link_to_assessment_point_id, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{assessment_point_rubric_id: id} = assigns, socket) when not is_nil(id) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point_rubric()
      |> assign_scale()
      |> assign_rubric_form()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  defp assign_assessment_point_rubric(%{assigns: %{assessment_point_rubric_id: :new}} = socket) do
    assessment_point =
      Assessments.get_assessment_point(
        socket.assigns.assessment_point_id,
        preloads: [curriculum_item: :curriculum_component]
      )

    assessment_point_rubric =
      %AssessmentPointRubric{
        is_diff: Map.get(socket.assigns, :is_diff) == true
      }

    socket
    |> assign(:assessment_point_rubric, assessment_point_rubric)
    |> assign(:assessment_point, assessment_point)
    |> assign(:rubric, %Rubric{scale_id: assessment_point.scale_id})
  end

  defp assign_assessment_point_rubric(%{assigns: %{assessment_point_rubric_id: id}} = socket)
       when not is_nil(id) do
    %{assessment_point: assessment_point} =
      assessment_point_rubric =
      Rubrics.get_assessment_point_rubric!(
        id,
        preloads: [assessment_point: [curriculum_item: :curriculum_component]]
      )

    # after "extracting" the assessment point, unload it to save memory
    assessment_point_rubric =
      Map.put(assessment_point_rubric, :assessment_point, %Ecto.Association.NotLoaded{})

    rubric = Rubrics.get_full_rubric!(assessment_point_rubric.rubric_id)

    socket
    |> assign(:assessment_point_rubric, assessment_point_rubric)
    |> assign(:assessment_point, assessment_point)
    |> assign(:rubric, rubric)
  end

  defp assign_assessment_point_rubric(socket), do: socket

  defp assign_scale(socket) do
    scale =
      case socket.assigns.assessment_point.scale_id do
        nil -> nil
        scale_id -> Grading.get_scale!(scale_id, preloads: :ordinal_values)
      end

    assign(socket, :scale, scale)
  end

  defp assign_rubric_form(socket) do
    %{rubric: rubric, scale: scale} = socket.assigns

    changeset =
      case {rubric.id, scale} do
        {nil, scale} ->
          # if scale is selected and rubric is new, generate empty descriptors
          Rubrics.change_rubric(
            rubric,
            %{"descriptors" => generate_new_descriptors(scale)}
          )

        _ ->
          Rubrics.change_rubric(rubric)
      end

    assign(socket, :form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("delete", _, socket) do
    case Rubrics.delete_rubric(socket.assigns.rubric, unlink_assessment_points: true) do
      {:ok, rubric} ->
        notify(__MODULE__, {:deleted, rubric}, socket.assigns)
        {:noreply, socket}

      # {:error, %Ecto.Changeset{errors: [diff_for_rubric_id: {msg, _}]}} ->
      #   socket =
      #     socket
      #     |> put_flash(:error, msg)
      #     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

      #   {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"rubric" => %{"add_descriptor" => "on"} = rubric_params}, socket) do
    blank_descriptor = blank_numeric_descriptor()

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

    {:noreply, assign(socket, :form, to_form(changeset))}
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

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("validate", %{"rubric" => rubric_params}, socket) do
    rubric_params = inject_extra_params(socket, rubric_params)

    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(rubric_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"rubric" => rubric_params}, socket) do
    rubric_params = inject_extra_params(socket, rubric_params)
    save_rubric(socket, socket.assigns.rubric.id, rubric_params)
  end

  defp generate_new_descriptors(scale) do
    case scale.type do
      "ordinal" ->
        scale.ordinal_values
        |> Enum.map(
          &%{
            ordinal_value_id: &1.id,
            descriptor: "—"
          }
        )

      "numeric" ->
        %{
          "0" =>
            blank_numeric_descriptor()
            |> Map.put("score", scale.start),
          "1" =>
            blank_numeric_descriptor()
            |> Map.put("score", scale.stop)
        }
    end
  end

  defp blank_numeric_descriptor() do
    %{
      "score" => "",
      "descriptor" => ""
    }
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("scale_id", socket.assigns.scale.id)
    # force "descriptors" be present in params for removing descriptors on cast_assoc
    |> Map.put_new("descriptors", %{})
    |> Map.update("descriptors", %{}, fn descriptors ->
      descriptors
      |> Enum.map(fn {k, v} ->
        v =
          v
          |> Map.put("scale_id", socket.assigns.scale.id)
          |> Map.put("scale_type", socket.assigns.scale.type)

        {k, v}
      end)
      |> Enum.into(%{})
    end)
  end

  defp save_rubric(socket, nil, rubric_params) do
    Rubrics.create_rubric_and_link_to_assessment_point(
      socket.assigns.assessment_point.id,
      rubric_params,
      is_diff: socket.assigns.assessment_point_rubric.is_diff
    )
    |> case do
      {:ok, rubric} ->
        notify(__MODULE__, {:created, rubric}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, _msg} ->
        # to do: do something with error msg
        {:noreply, socket}
    end
  end

  defp save_rubric(socket, _rubric_id, rubric_params) do
    case Rubrics.update_rubric(socket.assigns.rubric, rubric_params, preloads: :scale) do
      {:ok, rubric} ->
        notify(__MODULE__, {:updated, rubric}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
