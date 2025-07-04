defmodule LantternWeb.Assessments.AssessmentPointFormOverlayComponent do
  @moduledoc """
  Renders an `AssessmentPoint` form overlay.

  ### Required attrs

  - `:assessment_point` - `AssessmentPoint`. When creating a new assessment point, use `%AssessmentPoint{}` with `nil` id
  - `:on_cancel` - `<.slide_over>` `on_cancel` attr
  - `:title` - string

  ### Optional attrs

  - `:notify_component`
  - `:notify_parent`
  - `:curriculum_from_strand_id` - id of the curriculum item from the strand context. If set, the form will use a select input for the curriculum item
  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Curricula
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.GradingHelpers

  # components
  alias LantternWeb.Curricula.CurriculumItemSearchComponent
  alias LantternWeb.Rubrics.RubricDescriptorsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.delete_error
          error_message={@delete_error}
          on_delete={JS.push("delete_assessment_point_and_entries", target: @myself)}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
          class="mb-6"
        />
        <.form
          id={"#{@id}-form"}
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action == :insert} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            :if={!@assessment_point.strand_id}
            field={@form[:name]}
            label={gettext("Assessment point name")}
            phx-debounce="1500"
            class="mb-6"
          />
          <%= if @curriculum_from_strand_id do %>
            <.input
              field={@form[:curriculum_item_id]}
              type="select"
              options={@curriculum_item_options}
              prompt={gettext("Select curriculum item")}
              label={gettext("Curriculum item")}
              class="mb-6"
            />
          <% else %>
            <.live_component
              module={CurriculumItemSearchComponent}
              id="curriculum-item-search"
              notify_component={@myself}
              label={gettext("Curriculum")}
            />
            <div class="mt-2 mb-6">
              <div
                :if={@selected_curriculum_item}
                class="flex items-center gap-4 p-4 rounded-sm bg-ltrn-lightest"
              >
                <div class="flex-1">
                  <.badge theme="dark">
                    <%= @selected_curriculum_item.curriculum_component.name %>
                  </.badge>
                  <p class="mt-2"><%= @selected_curriculum_item.name %></p>
                </div>
                <button
                  type="button"
                  phx-click={JS.push("remove_curriculum_item", target: @myself)}
                  class="shrink-0 text-ltrn-subtle hover:text-ltrn-dark"
                >
                  <.icon name="hero-x-mark" class="w-6 h-6" />
                </button>
              </div>
            </div>
            <.input field={@form[:curriculum_item_id]} type="hidden" class="mb-6" />
          <% end %>
          <.input
            field={@form[:scale_id]}
            type="select"
            label={gettext("Scale")}
            options={@scale_options}
            prompt={gettext("Select a scale")}
            class="mb-6"
          />
          <.input
            field={@form[:report_info]}
            type="markdown"
            label={gettext("Report information")}
            class="mb-6"
            phx-debounce="1500"
          />
          <div class="p-4 rounded-sm mb-6 bg-ltrn-diff-lightest">
            <.input
              field={@form[:is_differentiation]}
              type="toggle"
              theme="diff"
              label={gettext("Differentiation")}
            />
            <p class="mt-4 text-sm">
              <%= gettext(
                "Use the differentiation flag above when creating assessment points related to a curriculum level differentiation."
              ) %>
            </p>
          </div>
          <.rubric_area id={@id} field={@form[:rubric_id]} rubric={@rubric} options={@rubric_options} />
        </.form>
        <.delete_error
          error_message={@delete_error}
          on_delete={JS.push("delete_assessment_point_and_entries", target: @myself)}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        />
        <:actions_left :if={@assessment_point.id}>
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
            form={"#{@id}-form"}
            phx-disable-with={gettext("Saving...")}
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :error_message, :string, required: true
  attr :on_delete, JS, required: true
  attr :on_dismiss, JS, required: true

  defp delete_error(assigns) do
    ~H"""
    <div
      :if={@error_message}
      class={["flex items-start gap-4 p-4 rounded-xs text-sm text-rose-600 bg-rose-100", @class]}
    >
      <div>
        <p><%= @error_message %></p>
        <button
          type="button"
          phx-click={@on_delete}
          data-confirm={gettext("Are you sure?")}
          class="mt-4 font-display font-bold underline"
        >
          <%= gettext("Understood. Delete anyway") %>
        </button>
      </div>
      <button type="button" phx-click={@on_dismiss} class="shrink-0">
        <span class="sr-only"><%= gettext("dismiss") %></span>
        <.icon name="hero-x-mark" />
      </button>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rubric, :any, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true

  def rubric_area(assigns) do
    ~H"""
    <div class="p-4 rounded-sm mt-10 mb-6 bg-ltrn-lightest">
      <div class="flex items-center gap-2 mb-4 font-bold text-sm">
        <.icon name="hero-view-columns" class="w-6 h-6 text-ltrn-subtle" />
        <span><%= gettext("Assessment rubric") %></span>
      </div>
      <%= if @options != [] do %>
        <.input type="select" field={@field} prompt={gettext("No rubric")} options={@options} />
        <div :if={@rubric} class="mt-2">
          <.live_component
            module={RubricDescriptorsComponent}
            id={"#{@id}-rubric-descriptors"}
            rubric={@rubric}
            class="overflow-x-auto"
          />
        </div>
      <% else %>
        <.empty_state_simple class="mt-4">
          <%= gettext("No rubric matching curriculum item and scale") %>
        </.empty_state_simple>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:selected_curriculum_item, nil)
      |> assign(:curriculum_from_strand_id, nil)
      |> assign(:rubric, nil)
      |> assign(:delete_error, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", "#{curriculum_item.id}")

    form =
      socket.assigns.assessment_point
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> assign(:selected_curriculum_item, curriculum_item)
      |> assign(:form, form)
      # always reassign rubric options and remove rubric on curriculum item change
      |> assign(:rubric_options_curriculum_item_id, curriculum_item.id)
      |> reassign_rubric_options()
      |> maybe_reassign_rubric(%{"rubric_id" => ""})

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_scale_options()
    |> assign_curriculum_item_and_options()
    |> assign_rubric()
    |> assign_rubric_options()
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_scale_options(socket) do
    scale_options = GradingHelpers.generate_scale_options()
    assign(socket, :scale_options, scale_options)
  end

  defp assign_curriculum_item_and_options(socket) do
    curriculum_item =
      case socket.assigns.assessment_point.curriculum_item_id do
        nil -> nil
        id -> Curricula.get_curriculum_item!(id, preloads: :curriculum_component)
      end

    curriculum_item_options =
      case socket.assigns do
        %{curriculum_from_strand_id: strand_id} when not is_nil(strand_id) ->
          Curricula.list_strand_curriculum_items(strand_id, preloads: :curriculum_component)
          |> Enum.map(&{"(#{&1.curriculum_component.name}) #{&1.name}", &1.id})

        _ ->
          []
      end
      |> maybe_add_extra_curriculum_item_option(curriculum_item, socket.assigns)

    socket
    |> assign(:selected_curriculum_item, curriculum_item)
    |> assign(:curriculum_item_options, curriculum_item_options)
  end

  defp maybe_add_extra_curriculum_item_option(curriculum_item_options, curriculum_item, assigns) do
    # for cases when we have existing assessment points using curriculum items
    # that were removed from strand, we add one extra curriculum item option
    # using the current assessment point curriculum item

    curriculum_item_id =
      case curriculum_item do
        nil -> nil
        curriculum_item -> curriculum_item.id
      end

    curriculum_item_options_ids =
      Enum.map(curriculum_item_options, fn {_name, id} -> id end)

    case {assigns, curriculum_item_id in curriculum_item_options_ids, curriculum_item_id} do
      {%{curriculum_from_strand_id: _}, false, ci_id} when not is_nil(ci_id) ->
        (curriculum_item_options ++
           [
             {"#{gettext("Not linked to strand")} - (#{curriculum_item.curriculum_component.name}) #{curriculum_item.name}",
              curriculum_item.id}
           ])
        |> Enum.uniq()

      _ ->
        curriculum_item_options
    end
  end

  def assign_form(socket) do
    changeset = Assessments.change_assessment_point(socket.assigns.assessment_point)
    assign(socket, :form, to_form(changeset))
  end

  defp assign_rubric(socket) do
    %{rubric: rubric} =
      socket.assigns.assessment_point
      |> Lanttern.Repo.preload([:rubric])

    assign(socket, :rubric, rubric)
  end

  defp assign_rubric_options(socket) do
    %{
      curriculum_item_id: curriculum_item_id,
      scale_id: scale_id,
      is_differentiation: is_differentiation
    } = socket.assigns.assessment_point

    # we only fetch rubric opts if we have the minimum required data
    rubric_options =
      if curriculum_item_id && scale_id do
        opts =
          if is_differentiation,
            do: [only_diff: true],
            else: [exclude_diff: true]

        Rubrics.list_assessment_point_rubrics(socket.assigns.assessment_point, opts)
        |> Enum.map(fn rubric -> {"#{gettext("Criteria")}: #{rubric.criteria}", rubric.id} end)
      else
        []
      end

    # sometimes the assessment point `is_differentiation` flag is changed after the rubric is linked
    # resulting in the current rubric not being part of the options. In this case, we add it to the options
    rubric_options =
      if socket.assigns.rubric &&
           !Enum.any?(rubric_options, fn {_, id} -> id == socket.assigns.rubric.id end) do
        [
          {"#{gettext("Criteria")}: #{socket.assigns.rubric.criteria}", socket.assigns.rubric.id}
          | rubric_options
        ]
      else
        rubric_options
      end

    socket
    |> assign(:rubric_options, rubric_options)
    |> assign(:rubric_options_curriculum_item_id, curriculum_item_id)
    |> assign(:rubric_options_scale_id, scale_id)
    |> assign(:rubric_options_is_differentiation, is_differentiation)
  end

  # event handlers

  @impl true
  def handle_event("remove_curriculum_item", _params, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", "")

    form =
      socket.assigns.form.data
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> assign(:selected_curriculum_item, nil)
      |> assign(:form, form)
      # always reassign rubric options and remove rubric on curriculum item change
      |> assign(:rubric_options_curriculum_item_id, nil)
      |> reassign_rubric_options()
      |> maybe_reassign_rubric(%{"rubric_id" => ""})

    {:noreply, socket}
  end

  def handle_event("validate", %{"assessment_point" => params}, socket) do
    {socket, params} = handle_rubric_assigns_on_validate(socket, params)

    form =
      socket.assigns.assessment_point
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> maybe_reassign_rubric(params)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("delete", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, assessment_point} ->
        notify(__MODULE__, {:deleted, assessment_point}, socket.assigns)
        {:noreply, socket}

      {:error, _changeset} ->
        # we may have more error types, but for now we are handling only this one
        message =
          gettext(
            "This assessment point already have some entries. Deleting it will cause data loss."
          )

        {:noreply, assign(socket, :delete_error, message)}
    end
  end

  def handle_event("delete_assessment_point_and_entries", _, socket) do
    case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
      {:ok, assessment_point} ->
        notify(__MODULE__, {:deleted_with_entries, assessment_point}, socket.assigns)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_delete_error", _, socket),
    do: {:noreply, assign(socket, :delete_error, nil)}

  def handle_event("save", %{"assessment_point" => params}, socket) do
    # inject strand and moment id in params
    assessment_point = socket.assigns.assessment_point

    params =
      params
      |> Map.put("strand_id", assessment_point.strand_id)
      |> Map.put("moment_id", assessment_point.moment_id)

    # we also need to force rubric id because if there's no rubric options,
    # the rubric_id input is not rendered, so we use the rubric in assigns
    params =
      if socket.assigns.rubric do
        Map.put(params, "rubric_id", socket.assigns.rubric.id)
      else
        Map.put(params, "rubric_id", "")
      end

    save(socket, assessment_point.id, params)
  end

  defp save(socket, nil, params) do
    case Assessments.create_assessment_point(params) do
      {:ok, assessment_point} ->
        notify(__MODULE__, {:created, assessment_point}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save(socket, _assessment_point_id, params) do
    case Assessments.update_assessment_point(socket.assigns.assessment_point, params) do
      {:ok, assessment_point} ->
        notify(__MODULE__, {:updated, assessment_point}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_rubric_assigns_on_validate(socket, params) do
    # if curriculum item, scale or differentiation flag changes,
    # we need to update rubric options and set rubric to nil

    curriculum_item_id =
      case Integer.parse(params["curriculum_item_id"]) do
        {id, ""} -> id
        _ -> nil
      end

    scale_id =
      case Integer.parse(params["scale_id"]) do
        {id, ""} -> id
        _ -> nil
      end

    is_differentiation =
      params["is_differentiation"] == "true"

    has_changes =
      socket.assigns.rubric_options_curriculum_item_id != curriculum_item_id ||
        socket.assigns.rubric_options_scale_id != scale_id ||
        socket.assigns.rubric_options_is_differentiation != is_differentiation

    if has_changes do
      params = Map.put(params, "rubric_id", "")

      socket =
        socket
        |> assign(:rubric_options_curriculum_item_id, curriculum_item_id)
        |> assign(:rubric_options_scale_id, scale_id)
        |> assign(:rubric_options_is_differentiation, is_differentiation)
        |> reassign_rubric_options()

      {socket, params}
    else
      {socket, params}
    end
  end

  defp reassign_rubric_options(socket) do
    with true <- not is_nil(socket.assigns.rubric_options_curriculum_item_id),
         true <- not is_nil(socket.assigns.rubric_options_scale_id) do
      opts =
        if socket.assigns.rubric_options_is_differentiation,
          do: [only_diff: true],
          else: [exclude_diff: true]

      assessment_point =
        %{
          socket.assigns.assessment_point
          | curriculum_item_id: socket.assigns.rubric_options_curriculum_item_id,
            scale_id: socket.assigns.rubric_options_scale_id,
            is_differentiation: socket.assigns.rubric_options_is_differentiation
        }

      rubric_options =
        Rubrics.list_assessment_point_rubrics(assessment_point, opts)
        |> Enum.map(fn rubric -> {"#{gettext("Criteria")}: #{rubric.criteria}", rubric.id} end)

      assign(socket, :rubric_options, rubric_options)
    else
      _ ->
        assign(socket, :rubric_options, [])
    end
  end

  defp maybe_reassign_rubric(%{assigns: %{rubric: nil}} = socket, %{"rubric_id" => ""}),
    do: socket

  defp maybe_reassign_rubric(%{assigns: %{rubric: nil}} = socket, %{"rubric_id" => id}),
    do: assign(socket, :rubric, Rubrics.get_rubric!(id))

  defp maybe_reassign_rubric(%{assigns: %{rubric: %Rubric{}}} = socket, %{
         "rubric_id" => ""
       }),
       do: assign(socket, :rubric, nil)

  defp maybe_reassign_rubric(%{assigns: %{rubric: %Rubric{id: assign_id}}} = socket, %{
         "rubric_id" => id
       }) do
    if id != "#{assign_id}" do
      assign(socket, :rubric, Rubrics.get_rubric!(id))
    else
      socket
    end
  end

  defp maybe_reassign_rubric(socket, _params), do: socket
end
