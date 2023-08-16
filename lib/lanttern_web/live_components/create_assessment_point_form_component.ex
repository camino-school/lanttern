defmodule LantternWeb.CreateAssessmentPointFormComponent do
  use LantternWeb, :live_component

  import LantternWeb.OverlayComponents

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools
  alias LantternWeb.CurriculaHelpers
  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over :if={@show} id="create-form">
        <:title>Create assessment point</:title>
        <.form
          id="create-assessment-point-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error :if={@form.source.action == :insert}>
            Oops, something went wrong! Please check the errors below.
          </.error>
          <.input field={@form[:name]} label="Assessment point name" phx-debounce="1500" />
          <.input type="textarea" field={@form[:description]} label="Decription (optional)" />
          <div class="flex">
            <.input type="date" field={@form[:date]} label="Date" phx-debounce="1500" />
            <.input type="number" min="0" max="23" field={@form[:hour]} label="h" phx-debounce="1500" />
            <.input
              type="number"
              min="0"
              max="59"
              field={@form[:minute]}
              label="m"
              phx-debounce="1500"
            />
          </div>
          <.input
            field={@form[:curriculum_item_id]}
            type="select"
            label="Curriculum item"
            options={@curriculum_item_options}
            prompt="Select a curriculum item"
          />
          <.input
            field={@form[:scale_id]}
            type="select"
            label="Scale"
            options={@scale_options}
            prompt="Select a scale"
          />
          <.input
            field={@form[:class_id]}
            type="select"
            label="Classes"
            options={@class_options}
            prompt="Select classes"
            phx-change="class_selected"
            phx-target={@myself}
          />
          <.badge
            :for={{name, id} <- @selected_classes}
            id={"class-badge-#{id}"}
            phx-click="class_removed"
            phx-value-id={id}
            phx-target={@myself}
          >
            <%= name %>
          </.badge>
          <.input
            field={@form[:student_id]}
            type="select"
            label="Students"
            options={@student_options}
            prompt="Select students"
            phx-change="student_selected"
            phx-target={@myself}
          />
          <.badge
            :for={{name, id} <- @selected_students}
            id={"student-badge-#{id}"}
            phx-click="student_removed"
            phx-value-id={id}
            phx-target={@myself}
          >
            <%= name %>
          </.badge>
        </.form>
        <:actions>
          <button
            type="button"
            class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:ring-gray-400"
            phx-click="hide-create-assessment-point-form"
          >
            Cancel
          </button>
          <button
            type="submit"
            form="create-assessment-point-form"
            class="ml-4 inline-flex justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
            phx-disable-with="Saving..."
          >
            Save
          </button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  def mount(socket) do
    changeset = Assessments.new_assessment_point_changeset()

    curriculum_item_options = CurriculaHelpers.generate_curriculum_item_options()
    scale_options = GradingHelpers.generate_scale_options()
    class_options = SchoolsHelpers.generate_class_options()
    selected_classes = []
    student_options = SchoolsHelpers.generate_student_options()
    selected_students = []

    socket =
      socket
      |> assign(%{
        form: to_form(changeset),
        curriculum_item_options: curriculum_item_options,
        scale_options: scale_options,
        class_options: class_options,
        selected_classes: selected_classes,
        student_options: student_options,
        selected_students: selected_students
      })

    {:ok, socket}
  end

  def handle_event(
        "class_selected",
        %{"assessment_point" => %{"class_id" => class_id}},
        socket
      )
      when class_id != "" do
    class_id = String.to_integer(class_id)

    selected_class =
      extract_from_options(
        socket.assigns.class_options,
        class_id
      )

    class_students =
      Schools.list_students(classes_ids: [class_id])
      |> Enum.map(fn s -> {:"#{s.name}", s.id} end)

    socket =
      socket
      |> update(:selected_classes, &Keyword.merge(&1, selected_class))
      |> update(:selected_students, &Keyword.merge(&1, class_students))

    {:noreply, socket}
  end

  def handle_event("class_selected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("class_removed", %{"id" => class_id}, socket) do
    class_id = String.to_integer(class_id)

    socket =
      socket
      |> update(:selected_classes, &remove_from_selected(&1, class_id))

    {:noreply, socket}
  end

  def handle_event(
        "student_selected",
        %{"assessment_point" => %{"student_id" => student_id}},
        socket
      )
      when student_id != "" do
    student_id = String.to_integer(student_id)

    selected_student =
      extract_from_options(
        socket.assigns.student_options,
        student_id
      )

    socket =
      socket
      |> update(:selected_students, &Keyword.merge(&1, selected_student))

    {:noreply, socket}
  end

  def handle_event("student_selected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("student_removed", %{"id" => student_id}, socket) do
    student_id = String.to_integer(student_id)

    socket =
      socket
      |> update(:selected_students, &remove_from_selected(&1, student_id))

    {:noreply, socket}
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
    classes_ids =
      socket.assigns.selected_classes
      |> Enum.map(fn {_name, id} -> id end)

    students_ids =
      socket.assigns.selected_students
      |> Enum.map(fn {_name, id} -> id end)

    params =
      params
      |> Map.put("classes_ids", classes_ids)
      |> Map.put("students_ids", students_ids)

    case Assessments.create_assessment_point(params) do
      {:ok, assessment_point} ->
        send(self(), {:assessment_point_created, assessment_point})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  attr :id, :string
  attr :class, :string, default: ""
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span
      id={@id}
      class={[
        "inline-flex items-center gap-x-0.5 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
      <button
        type="button"
        class="group relative -mr-1 h-3.5 w-3.5 rounded-sm hover:bg-gray-500/20"
        {@rest}
      >
        <span class="sr-only">Remove</span>
        <.icon name="hero-x-mark-mini" class="w-3.5 text-gray-700/50 hover:text-gray-700/75" />
        <span class="absolute -inset-1"></span>
      </button>
    </span>
    """
  end

  defp extract_from_options(options, id) do
    Keyword.filter(
      options,
      fn {_key, value} -> value == id end
    )
  end

  defp remove_from_selected(selected, id) do
    Keyword.filter(
      selected,
      fn {_key, value} -> value != id end
    )
  end
end
