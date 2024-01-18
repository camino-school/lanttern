defmodule LantternWeb.Assessments.AssessmentPointFormComponent do
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
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <.input field={@form[:id]} type="hidden" />
        <.input field={@form[:activity_id]} type="hidden" />
        <.input field={@form[:name]} label="Assessment point name" phx-debounce="1500" class="mb-6" />
        <%= if @curriculum_from_strand_id do %>
          <.input
            field={@form[:curriculum_item_id]}
            type="radio"
            options={@curriculum_item_options}
            prompt="Select curriculum item"
            class="mb-6"
          />
        <% else %>
          <.live_component
            module={CurriculumItemSearchComponent}
            id="curriculum-item-search"
            notify_component={@myself}
            label="Curriculum"
          />
          <div class="flex flex-wrap gap-1 mt-2 mb-6">
            <%= if @selected_curriculum_item do %>
              <.badge
                theme="cyan"
                show_remove
                phx-click={JS.push("remove_curriculum_item")}
                phx-target={@myself}
              >
                <%= @selected_curriculum_item.name %>
              </.badge>
            <% else %>
              <.badge>
                No curriculum item selected
              </.badge>
            <% end %>
          </div>
          <.input field={@form[:curriculum_item_id]} type="hidden" class="mb-6" />
        <% end %>
        <.input field={@form[:strand_id]} type="hidden" class="mb-6" />
        <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select a scale"
          class="mb-6"
        />
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

  def update(%{assessment_point: assessment_point} = assigns, socket) do
    curriculum_item =
      case assessment_point.curriculum_item_id do
        nil -> nil
        id -> Curricula.get_curriculum_item!(id)
      end

    curriculum_item_options =
      case assigns do
        %{curriculum_from_strand_id: strand_id} ->
          Curricula.list_strand_curriculum_items(strand_id)
          |> Enum.map(&{&1.name, &1.id})

        _ ->
          nil
      end

    # for cases when we have existing assessment points using curriculum items
    # that were removed from strand, we add one extra curriculum item option
    # using the current assessment point curriculum item
    curriculum_item_options =
      case {assigns, curriculum_item} do
        {%{curriculum_from_strand_id: _}, ci} when not is_nil(ci) ->
          (curriculum_item_options ++ [{ci.name, ci.id}])
          |> Enum.uniq()

        _ ->
          curriculum_item_options
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(Assessments.change_assessment_point(assessment_point)))
     |> assign(:selected_curriculum_item, curriculum_item)
     |> assign(:curriculum_item_options, curriculum_item_options)}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", curriculum_item.id)

    form =
      socket.assigns.form.data
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:ok,
     socket
     |> assign(:selected_curriculum_item, curriculum_item)
     |> assign(:form, form)}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}

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
      socket.assigns.form.data
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"assessment_point" => params}, socket) do
    case params["id"] do
      "" -> save(:new, params, socket)
      _id -> save(:edit, params, socket)
    end
  end

  defp save(:new, params, socket) do
    case Assessments.create_assessment_point(params) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> handle_navigation()}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save(:edit, params, socket) do
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
