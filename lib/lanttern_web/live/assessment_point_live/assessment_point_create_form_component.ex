defmodule LantternWeb.AssessmentPointLive.AssessmentPointCreateFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools
  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  alias LantternWeb.CurriculumLive.CurriculumItemSearchComponent

  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="create-assessment-point-form"
        for={@form}
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
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
            id="create-assessment-point-form-curriculum-item-search"
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
        <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select a scale"
          class="mb-6"
        />
        <div class="mb-6">
          <.input
            field={@form[:class_id]}
            type="select"
            label="Classes"
            options={@class_options}
            prompt="Select classes"
            phx-change="class_selected"
            phx-target={@myself}
            show_optional
          />
          <div class="flex flex-wrap gap-1 mt-2">
            <.badge :if={length(@selected_classes) == 0}>
              No classes selected yet
            </.badge>
            <.badge
              :for={{name, id} <- @selected_classes}
              id={"class-badge-#{id}"}
              theme="cyan"
              show_remove
              phx-click="class_removed"
              phx-value-id={id}
              phx-target={@myself}
            >
              <%= name %>
            </.badge>
          </div>
        </div>
        <.input
          field={@form[:student_id]}
          type="select"
          label="Students"
          options={@student_options}
          prompt="Select students"
          phx-change="student_selected"
          phx-target={@myself}
          show_optional
        />
        <div class="flex flex-wrap gap-1 mt-2">
          <.badge :if={length(@selected_students) == 0}>
            No students selected yet
          </.badge>
          <.badge
            :for={{name, id} <- @selected_students}
            id={"student-badge-#{id}"}
            theme="cyan"
            show_remove
            phx-click="student_removed"
            phx-value-id={id}
            phx-target={@myself}
          >
            <%= name %>
          </.badge>
        </div>
      </.form>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    changeset = Assessments.new_assessment_point_changeset()

    scale_options = GradingHelpers.generate_scale_options()
    class_options = SchoolsHelpers.generate_class_options()
    selected_classes = []
    student_options = SchoolsHelpers.generate_student_options()
    selected_students = []

    socket =
      socket
      |> assign(%{
        form: to_form(changeset),
        scale_options: scale_options,
        class_options: class_options,
        selected_classes: selected_classes,
        student_options: student_options,
        selected_students: selected_students,
        selected_curriculum_item: nil
      })

    {:ok, socket}
  end

  def update(%{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}}, socket) do
    # basically a manual "validate" event to update curriculum_item id
    params =
      socket.assigns.form.params
      |> Map.put("curriculum_item_id", curriculum_item.id)

    form =
      %AssessmentPoint{}
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
      %AssessmentPoint{}
      |> Assessments.change_assessment_point(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:selected_curriculum_item, nil)
     |> assign(:form, form)}
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
      |> update(:selected_classes, &merge_with_selected(&1, selected_class))
      |> update(:selected_students, &merge_with_selected(&1, class_students))

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
      |> update(:selected_students, &merge_with_selected(&1, selected_student))

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
        notify_parent({:created, assessment_point})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp extract_from_options(options, id) do
    Enum.find(
      options,
      fn {_key, value} -> value == id end
    )
  end

  defp merge_with_selected(selected, new) do
    new = if is_list(new), do: new, else: [new]
    selected ++ new
  end

  defp remove_from_selected(selected, id) do
    Enum.filter(
      selected,
      fn {_key, value} -> value != id end
    )
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
