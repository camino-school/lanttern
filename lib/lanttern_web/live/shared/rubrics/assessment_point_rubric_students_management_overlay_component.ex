defmodule LantternWeb.Rubrics.AssessmentPointRubricStudentsManagementOverlayComponent do
  @moduledoc """
  Renders an overlay with controls to manage the diff `AssessmentPointRubric` students.

  Only differentiation `AssessmentPointRubric`s are supported.

  ### Attrs

      attr :assessment_point_rubric_id, :integer, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.modal>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID
  """
  alias Lanttern.Rubrics.AssessmentPointRubric
  use LantternWeb, :live_component

  # alias Lanttern.Assessments
  alias Lanttern.Rubrics
  # alias Lanttern.Rubrics.Rubric
  # alias Lanttern.Grading

  # shared
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal :if={@assessment_point_rubric} id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Students linked to assessment point rubric") %></:title>
        <p class="mb-6">
          <%= gettext("Select the students that will be assessed using the differentiation rubric") %>
        </p>
        <%!-- StudentSearchComponent requires a wrapper form --%>
        <form>
          <.live_component
            module={StudentSearchComponent}
            id={"#{@id}-student-search"}
            notify_component={@myself}
            refocus_on_select="true"
            school_id={@current_profile.school_id}
          />
        </form>
        <div :if={@selected_students != []} class="flex flex-wrap gap-2 mt-2">
          <.person_badge
            :for={student <- @selected_students}
            person={student}
            theme="diff"
            on_remove={JS.push("remove_student", value: %{"id" => student.id}, target: @myself)}
            id={"#{@id}-student-#{student.id}"}
          />
        </div>
        <div class="flex justify-end gap-4 mt-10">
          <.action type="button" theme="subtle" size="md" phx-click={@on_cancel}>
            <%= gettext("Cancel") %>
          </.action>
          <.action
            type="button"
            theme="primary"
            size="md"
            icon_name="hero-check"
            phx-click={@on_cancel}
          >
            <%= gettext("Save") %>
          </.action>
        </div>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:assessment_point_rubric, nil)
      |> assign(:selected_students, [])

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
    selected_students =
      (socket.assigns.selected_students ++ [student])
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    socket =
      socket
      |> assign(:selected_students, selected_students)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point_rubric()

    {:ok, socket}
  end

  defp assign_assessment_point_rubric(%{assigns: %{assessment_point_rubric_id: id}} = socket)
       when not is_nil(id) do
    with %AssessmentPointRubric{is_diff: true} = assessment_point_rubric <-
           Rubrics.get_assessment_point_rubric!(id, preloads: :students) do
      # "initialize"  selected students
      selected_students = assessment_point_rubric.students

      # after "extract", unload students from the assessment point rubric to save memory
      assessment_point_rubric =
        Map.put(assessment_point_rubric, :students, %Ecto.Association.NotLoaded{})

      socket
      |> assign(:assessment_point_rubric, assessment_point_rubric)
      |> assign(:selected_students, selected_students)
    else
      _ ->
        socket
        |> assign(:assessment_point_rubric, nil)
        |> assign(:selected_students, [])
    end
  end

  defp assign_assessment_point_rubric(socket),
    do: assign(socket, :assessment_point_rubric, nil)

  # event handlers

  @impl true
  def handle_event("remove_student", %{"id" => id}, socket) do
    selected_students =
      socket.assigns.selected_students
      |> Enum.filter(&(&1.id != id))

    socket =
      socket
      |> assign(:selected_students, selected_students)

    {:noreply, socket}
  end
end
