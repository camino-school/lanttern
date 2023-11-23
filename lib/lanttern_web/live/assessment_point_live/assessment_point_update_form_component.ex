defmodule LantternWeb.AssessmentPointLive.AssessmentPointUpdateFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  alias LantternWeb.CurriculumLive.CurriculumItemSearchComponent

  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="update-assessment-point-form"
        for={@form}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.error_block :if={@form.source.action == :update} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <.input type="hidden" field={@form[:id]} />
        <.input field={@form[:name]} label="Assessment point name" phx-debounce="1500" class="mb-6" />
        <.input
          type="textarea"
          field={@form[:description]}
          label="Decription"
          show_optional
          class="mb-1"
        />
        <.markdown_supported class="mb-6" />

        <div class="flex gap-2 mb-6">
          <.input type="date" field={@form[:date]} label="Date" phx-debounce="1500" />
          <div class="flex gap-1">
            <.input
              type="number"
              min="0"
              max="23"
              step="1"
              field={@form[:hour]}
              label="Hour"
              phx-debounce="1500"
              class="w-20"
            />
            <span class="mt-9">:</span>
            <.input
              type="number"
              min="0"
              max="59"
              step="1"
              field={@form[:minute]}
              label="Minute"
              phx-debounce="1500"
              class="w-20"
            />
          </div>
        </div>
        <.input field={@form[:curriculum_item_id]} type="hidden" label="Curriculum item" />
        <div class="mt-1 mb-6">
          <.live_component
            module={CurriculumItemSearchComponent}
            id="update-assessment-point-form-curriculum-item-search"
            notify_component={@myself}
          />
          <.badge
            :if={@selected_curriculum_item}
            class="mt-2"
            theme="cyan"
            show_remove
            phx-click="remove_curriculum_item"
            phx-target={@myself}
          >
            <div>
              #<%= @selected_curriculum_item.id %>
              <span :if={@selected_curriculum_item.code}>
                (<%= @selected_curriculum_item.code %>)
              </span>
              <%= @selected_curriculum_item.name %>
            </div>
          </.badge>
        </div>
        <%!-- <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select a scale"
          class="mb-6"
        /> --%>
      </.form>
    </div>
    """
  end

  def mount(socket) do
    scale_options = GradingHelpers.generate_scale_options()
    class_options = SchoolsHelpers.generate_class_options()
    selected_classes = []
    student_options = SchoolsHelpers.generate_student_options()
    selected_students = []

    socket =
      socket
      |> assign(%{
        form: nil,
        scale_options: scale_options,
        class_options: class_options,
        selected_classes: selected_classes,
        student_options: student_options,
        selected_students: selected_students,
        selected_curriculum_item: nil
      })

    {:ok, socket}
  end

  def update(%{assessment_point: assessment_point} = assigns, socket) do
    changeset =
      assessment_point
      |> Assessments.change_assessment_point()

    selected_curriculum_item =
      case assessment_point.curriculum_item_id do
        id when is_integer(id) -> Lanttern.Curricula.get_curriculum_item!(id)
        _ -> nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:selected_curriculum_item, selected_curriculum_item)}
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

    {:ok,
     socket
     |> assign(:selected_curriculum_item, curriculum_item)
     |> assign(:form, form)}
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  # event handlers

  def handle_event("remove_curriculum_item", _params, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", nil)

    form =
      socket.assigns.assessment_point
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
    cur_assessment_point = Assessments.get_assessment_point!(params["id"])

    case Assessments.update_assessment_point(cur_assessment_point, params) do
      {:ok, assessment_point} ->
        notify_parent({:updated, assessment_point})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
