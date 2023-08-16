defmodule LantternWeb.CreateAssessmentPointFormComponent do
  use LantternWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools
  alias LantternWeb.CurriculaHelpers
  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  def render(assigns) do
    ~H"""
    <div>
      <div
        :if={@show}
        id="create-form"
        class="relative z-10"
        aria-labelledby="slide-over-title"
        role="dialog"
        aria-modal="true"
        phx-mounted={show_create_form()}
        phx-remove={hide_create_form()}
      >
        <div
          id="create-form__backdrop"
          class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity hidden"
        >
        </div>

        <div class="fixed inset-0 overflow-hidden">
          <div class="absolute inset-0 overflow-hidden">
            <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
              <div
                id="create-form__panel"
                class="pointer-events-auto w-screen max-w-xl py-6 transition-translate hidden"
              >
                <div class="flex h-full flex-col divide-y divide-gray-200 bg-white shadow-xl rounded-l">
                  <div class="flex min-h-0 flex-1 flex-col overflow-y-scroll py-6">
                    <div class="px-4 sm:px-6">
                      <div class="flex items-start justify-between">
                        <h2 class="font-display font-black text-3xl" id="slide-over-title">
                          Create assessment point
                        </h2>
                      </div>
                    </div>
                    <div class="relative mt-6 flex-1 px-4 sm:px-6">
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
                        <.input
                          field={@form[:name]}
                          label="Assessment point name"
                          phx-debounce="1500"
                        />
                        <.input
                          type="textarea"
                          field={@form[:description]}
                          label="Decription (optional)"
                        />
                        <div class="flex">
                          <.input type="date" field={@form[:date]} label="Date" phx-debounce="1500" />
                          <.input
                            type="number"
                            min="0"
                            max="23"
                            field={@form[:hour]}
                            label="h"
                            phx-debounce="1500"
                          />
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
                        <.class_badge
                          :for={{name, id} <- @selected_classes}
                          class_id={id}
                          class_name={name}
                          myself={@myself}
                        />
                        <.input
                          field={@form[:student_id]}
                          type="select"
                          label="Students"
                          options={@student_options}
                          prompt="Select students"
                          phx-change="student_selected"
                          phx-target={@myself}
                        />
                        <.student_badge
                          :for={{name, id} <- @selected_students}
                          student_id={id}
                          student_name={name}
                          myself={@myself}
                        />
                      </.form>
                    </div>
                  </div>
                  <div class="flex flex-shrink-0 justify-end px-4 py-4">
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
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
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

    added_class =
      Keyword.filter(
        socket.assigns.class_options,
        fn {_key, value} -> value == class_id end
      )

    class_students =
      Schools.list_students(classes_ids: [class_id])
      |> Enum.map(fn s -> {:"#{s.name}", s.id} end)

    socket =
      socket
      |> update(:selected_classes, fn selected_classes ->
        selected_classes |> Keyword.merge(added_class)
      end)
      |> update(:selected_students, fn selected_students ->
        selected_students |> Keyword.merge(class_students)
      end)

    {:noreply, socket}
  end

  def handle_event("class_selected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("class_removed", %{"classid" => class_id}, socket) do
    class_id = String.to_integer(class_id)

    socket =
      socket
      |> update(:selected_classes, fn selected_classes ->
        selected_classes |> Keyword.filter(fn {_key, value} -> value != class_id end)
      end)

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
      Keyword.filter(
        socket.assigns.student_options,
        fn {_key, value} -> value == student_id end
      )

    socket =
      socket
      |> update(:selected_students, fn selected_students ->
        selected_students |> Keyword.merge(selected_student)
      end)

    {:noreply, socket}
  end

  def handle_event("student_selected", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("student_removed", %{"studentid" => student_id}, socket) do
    student_id = String.to_integer(student_id)

    socket =
      socket
      |> update(:selected_students, fn selected_students ->
        selected_students |> Keyword.filter(fn {_key, value} -> value != student_id end)
      end)

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

  attr :class_id, :string, required: true
  attr :class_name, :string, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def class_badge(assigns) do
    ~H"""
    <span
      id={"class-badge-#{@class_id}"}
      class="inline-flex items-center gap-x-0.5 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600"
    >
      <%= @class_name %>
      <button
        type="button"
        class="group relative -mr-1 h-3.5 w-3.5 rounded-sm hover:bg-gray-500/20"
        phx-click="class_removed"
        phx-value-classid={@class_id}
        phx-target={@myself}
      >
        <span class="sr-only">Remove</span>
        <.icon name="hero-x-mark-mini" class="w-3.5 text-gray-700/50 hover:text-gray-700/75" />
        <span class="absolute -inset-1"></span>
      </button>
    </span>
    """
  end

  attr :student_id, :string, required: true
  attr :student_name, :string, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def student_badge(assigns) do
    ~H"""
    <span
      id={"student-badge-#{@student_id}"}
      class="inline-flex items-center gap-x-0.5 rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600"
    >
      <%= @student_name %>
      <button
        type="button"
        class="group relative -mr-1 h-3.5 w-3.5 rounded-sm hover:bg-gray-500/20"
        phx-click="student_removed"
        phx-value-studentid={@student_id}
        phx-target={@myself}
      >
        <span class="sr-only">Remove</span>
        <.icon name="hero-x-mark-mini" class="w-3.5 text-gray-700/50 hover:text-gray-700/75" />
        <span class="absolute -inset-1"></span>
      </button>
    </span>
    """
  end

  def show_create_form() do
    JS.add_class(
      "overflow-hidden",
      to: "body"
    )
    |> JS.show(
      to: "#create-form__backdrop",
      transition: {"ease-in-out duration-500", "opacity-0", "opacity-100"},
      time: 500
    )
    |> JS.show(
      to: "#create-form__panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-full",
        "translate-x-0"
      },
      time: 500
    )
  end

  def hide_create_form() do
    JS.remove_class("overflow-hidden", to: "body")
    |> JS.hide(
      to: "#create-form__backdrop",
      transition: {"ease-in-out duration-500", "opacity-100", "opacity-0"},
      time: 500
    )
    |> JS.hide(
      to: "#create-form__panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-0",
        "translate-x-full"
      },
      time: 500
    )
  end
end
