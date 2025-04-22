defmodule LantternWeb.Rubrics.RubricFormOverlayComponent do
  @moduledoc """
  Renders a `Rubric` form overlay.

  It handles the loading of curriculum item and scale based on give `%Rubric{}`.

  Manages the assessment point/rubrics relationships, fetching all assessment points
  with the same curriculum item from linked strand.

  ### Required attrs

  - `:rubric` - `Rubric`. When creating a new rubric, use `%Rubric{}` with `nil` id
  - `:on_cancel` - `<.slide_over>` `on_cancel` attr
  - `:title` - string

  ### Optional attrs

  tbd
  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Grading
  alias Lanttern.Grading.Scale
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.Grading.OrdinalValueBadgeComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <p class="mb-2 text-xs"><%= gettext("Rubric for curriculum item") %></p>
        <div class="mb-10">
          <p>
            <strong class="inline-block mr-2 font-display font-bold">
              <%= @curriculum_item.curriculum_component.name %>
            </strong>
            <%= @curriculum_item.name %>
          </p>
          <div
            :if={@rubric.is_differentiation}
            class="p-4 rounded mt-4 font-bold text-ltrn-diff-dark bg-ltrn-diff-lightest"
          >
            <%= gettext("Differentiation rubric") %>
          </div>
        </div>
        <%!-- <p :if={@student} class="mt-6 font-display font-bold">
            <%= gettext("Differentiation for %{name}", name: @student.name) %>
          </p> --%>
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
            label={gettext("Rubric criteria")}
            phx-debounce="1500"
            class="mb-6"
          />
          <.descriptors_fields scale={@scale} field={@form[:descriptors]} myself={@myself} />
          <div class="mt-10 mb-6">
            <p class="font-bold"><%= gettext("Link rubric to assessment points") %></p>
            <.empty_state_simple :if={@assessment_points == []} class="mt-6">
              <%= gettext("No assessment point matching curriculum, scale, and differentiation flag") %>
            </.empty_state_simple>
            <.assessment_point_option
              :for={assessment_point <- @assessment_points}
              assessment_point={assessment_point}
              curriculum_item={@curriculum_item}
              checked={assessment_point.id in @selected_assessment_points_ids}
              on_click={
                if assessment_point.id in @selected_assessment_points_ids,
                  do:
                    JS.push("unlink_assessment_point",
                      value: %{"id" => assessment_point.id},
                      target: @myself
                    ),
                  else:
                    JS.push("link_assessment_point",
                      value: %{"id" => assessment_point.id},
                      target: @myself
                    )
              }
            />
            <div class="p-6 rounded border border-ltrn-light my-6 bg-ltrn-lightest">
              <p class="flex items-center gap-2 font-bold">
                <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
                <%= gettext("About rubrics and assessment points relationships") %>
              </p>
              <p class="mt-4">
                <%= gettext(
                  "Rubrics can be linked to assessment points with matching curriculum item, scale, and differentiation type."
                ) %>
              </p>
              <p class="mt-4 text-ltrn-diff-dark">
                <%= gettext(
                  "In case of differentiation rubrics, we can also link them directly to a student via assessment point entry."
                ) %>
              </p>
            </div>
          </div>
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

  attr :scale, Scale, required: true
  attr :field, :map, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  defp descriptors_fields(%{scale: %{type: "ordinal"}} = assigns) do
    ~H"""
    <h5 class="font-display font-black text-ltrn-subtle"><%= gettext("Descriptors") %></h5>
    <.markdown_supported class="mt-2" message={gettext("Markdown supported in descriptors")} />
    <.inputs_for :let={ef} field={@field}>
      <.input type="hidden" field={ef[:scale_id]} />
      <.input type="hidden" field={ef[:scale_type]} />
      <.input type="hidden" field={ef[:ordinal_value_id]} />
      <.input type="textarea" field={ef[:descriptor]} class="mt-6" phx-debounce="1500">
        <:custom_label>
          <.live_component
            module={OrdinalValueBadgeComponent}
            id={"ordinal-value-#{ef[:ordinal_value_id].id}"}
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
    <.markdown_supported class="mt-2" message={gettext("Markdown supported in descriptors")} />
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
            label={gettext("Score")}
            class="mt-6"
            phx-debounce="1500"
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

  attr :assessment_point, AssessmentPoint, required: true
  attr :curriculum_item, CurriculumItem, required: true
  attr :checked, :boolean, required: true
  attr :on_click, :any, required: true, doc: "the function to trigger on check click"

  defp assessment_point_option(assigns) do
    {assessment_point_name, badge_text, badge_theme} =
      case assigns.assessment_point do
        %{moment: %Moment{} = moment} ->
          {
            assigns.assessment_point.name,
            gettext("Moment %{moment}", moment: moment.name),
            "default"
          }

        _ ->
          {
            gettext("%{curriculum} final assessment", curriculum: assigns.curriculum_item.name),
            gettext("Goal assessment"),
            "dark"
          }
      end

    assigns =
      assigns
      |> assign(:assessment_point_name, assessment_point_name)
      |> assign(:badge_text, badge_text)
      |> assign(:badge_theme, badge_theme)

    ~H"""
    <.card_base
      class={[
        "flex items-center gap-6 p-6 mt-6",
        if(@checked, do: "outline outline-ltrn-mesh-primary")
      ]}
      id={"assessment-point-#{@assessment_point.id}-card"}
      bg_class={if @checked, do: "bg-ltrn-mesh-cyan"}
    >
      <button
        type="button"
        class="shrink-0 flex items-center justify-center w-6 h-6 rounded border border-ltrn-light bg-ltrn-lightest"
        phx-click={@on_click}
      >
        <.icon :if={@checked} name="hero-check-mini" />
      </button>
      <div>
        <div class="flex gap-2">
          <.badge theme={@badge_theme}><%= @badge_text %></.badge>
          <.badge :if={@assessment_point.is_differentiation} theme="diff">
            <%= gettext("Differentiation") %>
          </.badge>
        </div>
        <p class="mt-2"><%= @assessment_point_name %></p>
      </div>
    </.card_base>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> load_descriptors()
    |> assign_curriculum_item()
    |> assign_scale()
    |> assign_assessment_points()
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp load_descriptors(%{assigns: %{rubric: %Rubric{id: id}}} = socket) when not is_nil(id) do
    rubric =
      socket.assigns.rubric
      |> Rubrics.load_rubric_descriptors()

    assign(socket, :rubric, rubric)
  end

  defp load_descriptors(socket), do: socket

  defp assign_curriculum_item(socket) do
    curriculum_item =
      Curricula.get_curriculum_item(
        socket.assigns.rubric.curriculum_item_id,
        preloads: :curriculum_component
      )

    socket
    |> assign(:curriculum_item, curriculum_item)
  end

  defp assign_scale(socket) do
    scale =
      Grading.get_scale!(
        socket.assigns.rubric.scale_id,
        preloads: :ordinal_values
      )

    socket
    |> assign(:scale, scale)
  end

  defp assign_assessment_points(socket) do
    assessment_points_and_selected_status =
      Rubrics.list_rubric_assessment_points_options(socket.assigns.rubric)

    assessment_points =
      assessment_points_and_selected_status
      |> Enum.map(fn {assessment_point, _} -> assessment_point end)

    linked_assessment_points_ids =
      if is_nil(socket.assigns.rubric.id) do
        []
      else
        assessment_points_and_selected_status
        |> Enum.filter(fn {_, selected} -> selected end)
        |> Enum.map(fn {assessment_point, _} -> assessment_point.id end)
      end

    socket
    |> assign(:assessment_points, assessment_points)
    |> assign(:linked_assessment_points_ids, linked_assessment_points_ids)
    # we'll use selected_assessment_points_ids to track UI interactions
    # before submit, we'll diff selected and linked to determine what to add/remove
    |> assign(:selected_assessment_points_ids, linked_assessment_points_ids)
  end

  def assign_form(socket) do
    rubric = socket.assigns.rubric

    changeset =
      if is_nil(rubric.id) do
        # if rubric is new, generate empty descriptors
        Rubrics.change_rubric(
          rubric,
          %{"descriptors" => generate_new_descriptors(socket.assigns.scale)}
        )
      else
        Rubrics.change_rubric(rubric)
      end

    assign(socket, :form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("link_assessment_point", %{"id" => assessment_point_id}, socket) do
    selected_assessment_points_ids =
      [assessment_point_id | socket.assigns.selected_assessment_points_ids]
      |> Enum.uniq()

    {:noreply, assign(socket, :selected_assessment_points_ids, selected_assessment_points_ids)}
  end

  def handle_event("unlink_assessment_point", %{"id" => assessment_point_id}, socket) do
    selected_assessment_points_ids =
      socket.assigns.selected_assessment_points_ids
      |> Enum.filter(&(&1 != assessment_point_id))

    {:noreply, assign(socket, :selected_assessment_points_ids, selected_assessment_points_ids)}
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
    changeset =
      socket.assigns.rubric
      |> Rubrics.change_rubric(rubric_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("delete", _, socket) do
    Rubrics.delete_rubric(socket.assigns.rubric)
    |> case do
      {:ok, rubric} ->
        notify(__MODULE__, {:deleted, rubric}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("save", %{"rubric" => rubric_params}, socket) do
    # force "descriptors" be present in params for removing descriptors on cast_assoc
    rubric_params =
      rubric_params
      |> Map.put_new("descriptors", %{})

    save_rubric(socket, socket.assigns.rubric.id, rubric_params)
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

  defp save_rubric(socket, nil, rubric_params) do
    rubric_params = inject_create_params(rubric_params, socket)

    case socket.assigns do
      %{link_to_assessment_point_id: assessment_point_id} when not is_nil(assessment_point_id) ->
        Assessments.create_assessment_point_rubric(assessment_point_id, rubric_params)

      _ ->
        Rubrics.create_rubric(rubric_params, preloads: :scale)
    end
    |> case do
      {:ok, rubric} ->
        notify(__MODULE__, {:created, rubric}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}

      {:error, msg} ->
        {:noreply,
         socket
         |> put_flash(:error, msg)}
    end
  end

  defp save_rubric(socket, _id, rubric_params) do
    rubric_params = inject_update_params(rubric_params, socket)

    case Rubrics.update_rubric(socket.assigns.rubric, rubric_params) do
      {:ok, rubric} ->
        notify(__MODULE__, {:updated, rubric}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp inject_create_params(params, socket) do
    # part of the required rubric fields are in the
    # rubric assign. inject them into the params before saving

    %{
      strand_id: strand_id,
      scale_id: scale_id,
      curriculum_item_id: curriculum_item_id,
      is_differentiation: is_differentiation
    } = socket.assigns.rubric

    params
    |> Map.put("link_to_assessment_points_ids", socket.assigns.selected_assessment_points_ids)
    |> Map.put("strand_id", strand_id)
    |> Map.put("scale_id", scale_id)
    |> Map.put("curriculum_item_id", curriculum_item_id)
    |> Map.put("is_differentiation", is_differentiation)
  end

  defp inject_update_params(params, socket) do
    current_ids = socket.assigns.linked_assessment_points_ids

    link_to_assessment_points_ids =
      socket.assigns.selected_assessment_points_ids
      |> Enum.reject(&(&1 in current_ids))

    unlink_from_assessment_points_ids =
      current_ids
      |> Enum.reject(&(&1 in socket.assigns.selected_assessment_points_ids))

    params
    |> Map.put("link_to_assessment_points_ids", link_to_assessment_points_ids)
    |> Map.put("unlink_from_assessment_points_ids", unlink_from_assessment_points_ids)
  end
end
