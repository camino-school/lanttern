defmodule LantternWeb.AssessmentPointUpdateOverlayComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id}>
        <:title>Update assessment point</:title>
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
          <p class="mb-6 text-sm text-ltrn-subtle">
            <a
              href="https://www.markdownguide.org/basic-syntax/"
              target="_blank"
              class="hover:text-ltrn-primary"
            >
              Markdown supported <.icon name="hero-information-circle" />
            </a>
          </p>

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
          <.live_component
            module={LantternWeb.CurriculumItemSearchInputComponent}
            id="update-assessment-point-form-curriculum-item"
            field={@form[:curriculum_item_id]}
            class="mb-6"
          />
          <%!-- <.input
            field={@form[:scale_id]}
            type="select"
            label="Scale"
            options={@scale_options}
            prompt="Select a scale"
            class="mb-6"
          /> --%>
        </.form>
        <:actions>
          <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
            Cancel
          </.button>
          <.button type="submit" form="update-assessment-point-form" phx-disable-with="Saving...">
            Save
          </.button>
        </:actions>
      </.slide_over>
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
        selected_students: selected_students
      })

    {:ok, socket}
  end

  def update(%{assessment_point: assessment_point} = assigns, socket) do
    changeset =
      assessment_point
      |> Assessments.change_assessment_point()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      Enum.reduce(
        assigns,
        socket,
        fn {key, value}, socket ->
          assign(socket, key, value)
        end
      )

    {:ok, socket}
  end

  def handle_event("validate", %{"assessment_point" => params}, socket) do
    form =
      %AssessmentPoint{}
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"assessment_point" => params}, socket) do
    cur_assessment_point = Assessments.get_assessment_point!(params["id"])

    case Assessments.update_assessment_point(cur_assessment_point, params) do
      {:ok, assessment_point} ->
        send(self(), {:assessment_point_updated, assessment_point})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
