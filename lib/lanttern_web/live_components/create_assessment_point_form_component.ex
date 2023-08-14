defmodule LantternWeb.CreateAssessmentPointFormComponent do
  use LantternWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias LantternWeb.CurriculaHelpers
  alias LantternWeb.GradingHelpers

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
                        <.input field={@form[:name]} label="Assessment point name" />
                        <.input
                          type="textarea"
                          field={@form[:description]}
                          label="Decription (optional)"
                        />
                        <.input type="datetime-local" field={@form[:datetime_ui]} label="Datetime" />
                        <.input type="hidden" field={@form[:date]} />
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
                        <pre>
                        </pre>
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
    changeset = Assessments.change_assessment_point(%AssessmentPoint{})
    curriculum_item_options = CurriculaHelpers.generate_curriculum_item_options()
    scale_options = GradingHelpers.generate_scale_options()

    socket =
      socket
      |> assign(%{
        form: to_form(changeset),
        curriculum_item_options: curriculum_item_options,
        scale_options: scale_options
      })

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
    case Assessments.create_assessment_point(params) do
      {:ok, assessment_point} ->
        send(self(), {:assessment_point_created, assessment_point})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
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
