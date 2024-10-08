defmodule LantternWeb.Assessments.AssessmentPointFormComponent do
  @moduledoc """
  Renders a `AssessmentPoint` form
  """

  alias Lanttern.Curricula
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias LantternWeb.GradingHelpers

  # components
  alias LantternWeb.Curricula.CurriculumItemSearchComponent

  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="assessment-point-form"
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
            type="radio"
            options={@curriculum_item_options}
            prompt={gettext("Select curriculum item")}
            class="mb-6"
          />
        <% else %>
          <.live_component
            module={CurriculumItemSearchComponent}
            id="curriculum-item-search"
            notify_component={@myself}
            label={gettext("Curriculum")}
          />
          <div class="flex flex-wrap gap-1 mt-2 mb-6">
            <%= if @selected_curriculum_item do %>
              <.badge theme="cyan" on_remove={JS.push("remove_curriculum_item", target: @myself)}>
                <%= @selected_curriculum_item.name %>
              </.badge>
            <% else %>
              <.badge>
                <%= gettext("No curriculum item selected") %>
              </.badge>
            <% end %>
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
          type="textarea"
          label={gettext("Report information")}
          class="mb-1"
          phx-debounce="1500"
        />
        <.markdown_supported class="mb-6" />
        <div class="p-4 rounded mb-6 bg-ltrn-diff-lightest">
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
      </.form>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    scale_options = GradingHelpers.generate_scale_options()

    socket =
      socket
      |> assign(%{
        scale_options: scale_options,
        selected_curriculum_item: nil,
        curriculum_from_strand_id: nil
      })

    {:ok, socket}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", curriculum_item.id)

    form =
      socket.assigns.assessment_point
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket =
      socket
      |> assign(:selected_curriculum_item, curriculum_item)
      |> assign(:form, form)

    {:ok, socket}
  end

  def update(assigns, socket) do
    %{assessment_point: assessment_point} = assigns

    curriculum_item =
      case assessment_point.curriculum_item_id do
        nil -> nil
        id -> Curricula.get_curriculum_item!(id, preloads: :curriculum_component)
      end

    curriculum_item_options =
      case assigns do
        %{curriculum_from_strand_id: strand_id} ->
          Curricula.list_strand_curriculum_items(strand_id, preloads: :curriculum_component)
          |> Enum.map(&{"(#{&1.curriculum_component.name}) #{&1.name}", &1.id})

        _ ->
          nil
      end
      |> maybe_add_extra_curriculum_item_option(curriculum_item, assigns)

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(Assessments.change_assessment_point(assessment_point)))
      |> assign(:selected_curriculum_item, curriculum_item)
      |> assign(:curriculum_item_options, curriculum_item_options)

    {:ok, socket}
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
      case curriculum_item_options do
        nil -> []
        curriculum_item_options -> Enum.map(curriculum_item_options, fn {_name, id} -> id end)
      end

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

  # event handlers

  def handle_event("remove_curriculum_item", _params, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", nil)

    form =
      socket.assigns.form.data
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:selected_curriculum_item, nil)
     |> assign(:form, form)}
  end

  def handle_event("validate", %{"assessment_point" => params}, socket) do
    form =
      socket.assigns.assessment_point
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"assessment_point" => params}, socket) do
    # inject strand and moment id in params
    assessment_point = socket.assigns.assessment_point

    params =
      params
      |> Map.put("strand_id", assessment_point.strand_id)
      |> Map.put("moment_id", assessment_point.moment_id)

    save(socket, assessment_point.id, params)
  end

  defp save(socket, nil, params) do
    case Assessments.create_assessment_point(params) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> handle_navigation()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save(socket, _assessment_point_id, params) do
    case Assessments.update_assessment_point(socket.assigns.assessment_point, params) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> handle_navigation()}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
