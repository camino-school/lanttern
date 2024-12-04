defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3]

  # shared components
  import LantternWeb.RubricsComponents
  alias LantternWeb.Rubrics.RubricFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container>
        <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Goal rubrics") %></h3>
        <div
          :for={goal <- @goals}
          id={"strand-assessment-point-#{goal.id}"}
          class="p-6 rounded mt-6 shadow-lg bg-white"
        >
          <div class="flex items-center gap-4">
            <p class="flex-1 text-sm">
              <.badge :if={goal.is_differentiation} theme="diff" class="mr-2">
                <%= gettext("Diff") %>
              </.badge>
              <strong class="inline-block mr-2 font-display font-bold">
                <%= goal.curriculum_item.curriculum_component.name %>
              </strong>
              <%= goal.curriculum_item.name %>
            </p>
            <%= if goal.rubric do %>
              <.toggle_expand_button
                id={"strand-assessment-point-#{goal.id}-toggle-button"}
                target_selector={"#goal-rubric-#{goal.rubric_id}"}
              />
            <% else %>
              <.button
                type="link"
                theme="ghost"
                patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
              >
                <%= gettext("Add rubric") %>
              </.button>
            <% end %>
          </div>
          <.rubric
            :if={goal.rubric}
            class="pt-6 border-t border-ltrn-lighter mt-6"
            id={"goal-rubric-#{goal.rubric_id}"}
            goal_id={goal.id}
            rubric={goal.rubric}
            criteria_text={gettext("Rubric criteria")}
            on_edit={
              JS.push("edit_rubric",
                value: %{goal_id: goal.id},
                target: @myself
              )
            }
          />
        </div>
        <section
          :if={@selected_classes_ids != []}
          id="differentiation-rubrics-section"
          class="pb-10 mt-10"
        >
          <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">
            <%= gettext("Differentiation") %>
          </h4>
          <div role="tablist" class="flex flex-wrap items-center gap-2 mt-6">
            <.person_tab
              :for={student <- @students}
              aria-controls={"student-#{student.id}-diff-panel"}
              person={student}
              container_selector="#differentiation-rubrics-section"
              on_click={JS.push("load_diff_rubrics", value: %{student_id: student.id})}
              phx-target={@myself}
              theme={if student.has_diff_rubric, do: "diff", else: "default"}
            />
          </div>
          <div
            :for={student <- @students}
            id={"student-#{student.id}-diff-panel"}
            role="tabpanel"
            class="hidden"
          >
            <div
              :for={goal <- @goals_with_rubrics}
              id={"strand-assessment-point-#{student.id}-#{goal.id}"}
              class={[
                "p-6 rounded mt-6 bg-white shadow-lg",
                if(@students_diff_rubrics_map[student.id][goal.id],
                  do: "border border-ltrn-diff-accent"
                )
              ]}
            >
              <div class="flex items-center gap-4">
                <p class="flex-1 text-sm">
                  <.badge :if={goal.is_differentiation} theme="diff" class="mr-2">
                    <%= gettext("Diff") %>
                  </.badge>
                  <strong class="inline-block mr-2 font-display font-bold">
                    <%= goal.curriculum_item.curriculum_component.name %>
                  </strong>
                  <%= goal.curriculum_item.name %>
                </p>
                <%= if @students_diff_rubrics_map[student.id][goal.id] do %>
                  <.toggle_expand_button
                    id={"strand-assessment-point-#{student.id}-#{goal.id}-toggle-button"}
                    target_selector={"#goal-rubric-#{@students_diff_rubrics_map[student.id][goal.id].id}"}
                  />
                <% else %>
                  <.button
                    theme="ghost"
                    patch={
                      ~p"/strands/#{@strand}/rubrics?new_diff_rubric_for_goal=#{goal.id}&student=#{student.id}"
                    }
                  >
                    <%= gettext("Add diff") %>
                  </.button>
                <% end %>
              </div>
              <.rubric
                :if={@students_diff_rubrics_map[student.id][goal.id]}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"goal-rubric-#{@students_diff_rubrics_map[student.id][goal.id].id}"}
                goal_id={goal.id}
                rubric={@students_diff_rubrics_map[student.id][goal.id]}
                criteria_text={gettext("Differentiation rubric criteria")}
                on_edit={
                  JS.push("edit_diff_rubric",
                    value: %{
                      goal_id: goal.id,
                      student_id: student.id
                    },
                    target: @myself
                  )
                }
              />
            </div>
          </div>
        </section>
      </.responsive_container>
      <.slide_over
        :if={@goal}
        id="rubric-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}/rubrics")}
      >
        <:title><%= gettext("Rubric") %></:title>
        <p>
          <strong class="inline-block mr-2 font-display font-bold">
            <%= @goal.curriculum_item.curriculum_component.name %>
          </strong>
          <%= @goal.curriculum_item.name %>
        </p>
        <p :if={@student} class="mt-6 font-display font-bold">
          <%= gettext("Differentiation for %{name}", name: @student.name) %>
        </p>
        <.live_component
          module={RubricFormComponent}
          id={@rubric.id || :new}
          rubric={@rubric}
          link_to_assessment_point_id={@goal && @goal.id}
          diff_for_student_id={@student && @student.id}
          hide_diff_and_scale
          navigate={~p"/strands/#{@strand}/rubrics"}
          class="mt-6"
        />
        <:actions_left :if={@rubric.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_rubric"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#rubric-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button
            type="submit"
            form={"rubric-form-#{@rubric.id || :new}"}
            phx-disable-with="Saving..."
          >
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  attr :goal_id, :integer, required: true
  attr :criteria_text, :string, required: true
  attr :class, :any, default: nil
  attr :id, :string, required: true
  attr :rubric, :any, required: true
  attr :on_edit, JS, required: true

  def rubric(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <p class="mb-6 font-display font-black">
        <%= @criteria_text %>: <%= @rubric.criteria %>
        <button class="ml-2 underline text-ltrn-subtle hover:text-ltrn-dark" phx-click={@on_edit}>
          <%= gettext("Edit") %>
        </button>
      </p>
      <div class="overflow-x-auto">
        <.rubric_descriptors rubric={@rubric} />
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:rubric, nil)
      |> assign(:curriculum_item, nil)
      |> assign(:students_diff_rubrics_map, %{})
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_goal_rubric_and_student()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:classes], strand_id: socket.assigns.strand.id)
    |> assign_goals()
    |> assign_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_goals(socket) do
    goals =
      Assessments.list_assessment_points(
        strand_id: socket.assigns.strand.id,
        preload_full_rubrics: true,
        preloads: [curriculum_item: :curriculum_component]
      )

    goals_with_rubrics =
      goals
      |> Enum.filter(& &1.rubric)

    socket
    |> assign(:goals, goals)
    |> assign(:goals_with_rubrics, goals_with_rubrics)
    |> assign(:goals_ids, Enum.map(goals, & &1.id))
  end

  defp assign_students(socket) do
    students =
      case socket.assigns.selected_classes_ids do
        classes_ids when is_list(classes_ids) and classes_ids != [] ->
          Schools.list_students(
            classes_ids: classes_ids,
            check_diff_rubrics_for_strand_id: socket.assigns.strand.id
          )

        _ ->
          []
      end

    assign(socket, :students, students)
  end

  defp assign_goal_rubric_and_student(
         %{assigns: %{params: %{"new_rubric_for_goal" => binary_id}}} = socket
       ) do
    with {id, _} <- Integer.parse(binary_id), true <- id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(id)
      rubric = %Rubric{scale_id: goal.scale_id}

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, nil)
    else
      _ ->
        socket
        |> assign(:goal, nil)
        |> assign(:rubric, nil)
        |> assign(:student, nil)
    end
  end

  defp assign_goal_rubric_and_student(
         %{
           assigns: %{
             params: %{
               "new_diff_rubric_for_goal" => goal_binary_id,
               "student" => student_binary_id
             }
           }
         } = socket
       ) do
    with {goal_id, _} <- Integer.parse(goal_binary_id),
         true <- goal_id in socket.assigns.goals_ids,
         {student_id, _} <- Integer.parse(student_binary_id),
         true <- student_id in socket.assigns.students_ids do
      goal = Assessments.get_assessment_point(goal_id)

      rubric =
        %Rubric{
          scale_id: goal.scale_id,
          diff_for_rubric_id: goal.rubric_id
        }

      student =
        Schools.get_student(student_id)

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, student)
    else
      _ ->
        socket
        |> assign(:goal, nil)
        |> assign(:rubric, nil)
        |> assign(:student, nil)
    end
  end

  defp assign_goal_rubric_and_student(socket) do
    socket
    |> assign(:goal, nil)
    |> assign(:rubric, nil)
    |> assign(:student, nil)
  end

  # event handlers

  @impl true
  # def handle_event("new_rubric", params, socket) do
  #   assessment_point =
  #     socket.assigns.assessment_points
  #     |> Enum.find(&(&1.id == params["assessment_point_id"]))

  #   socket =
  #     socket
  #     |> assign(:assessment_point, assessment_point)
  #     |> assign(:student, nil)
  #     |> assign(:rubric, %Rubric{scale_id: assessment_point.scale_id})
  #     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

  #   {:noreply, socket}
  # end

  # def handle_event("new_diff_rubric", params, socket) do
  #   assessment_point =
  #     socket.assigns.assessment_points
  #     |> Enum.find(&(&1.id == params["assessment_point_id"]))

  #   student =
  #     socket.assigns.students
  #     |> Enum.find(&(&1.id == params["student_id"]))

  #   rubric =
  #     %Rubric{
  #       scale_id: assessment_point.scale_id,
  #       diff_for_rubric_id: assessment_point.rubric_id
  #     }

  #   socket =
  #     socket
  #     |> assign(:assessment_point, assessment_point)
  #     |> assign(:student, student)
  #     |> assign(:rubric, rubric)
  #     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

  #   {:noreply, socket}
  # end

  def handle_event("edit_rubric", params, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == params["assessment_point_id"]))

    socket =
      socket
      |> assign(:assessment_point, assessment_point)
      |> assign(:student, nil)
      |> assign(:rubric, assessment_point.rubric)
      |> clear_flash()
      # todo: fix (it was |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage"))
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

    {:noreply, socket}
  end

  def handle_event("edit_diff_rubric", params, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == params["assessment_point_id"]))

    student =
      socket.assigns.students
      |> Enum.find(&(&1.id == params["student_id"]))

    rubric =
      socket.assigns.students_diff_rubrics_map[student.id][assessment_point.id]

    socket =
      socket
      |> assign(:assessment_point, assessment_point)
      |> assign(:student, student)
      |> assign(:rubric, rubric)
      |> clear_flash()
      # todo: fix (it was |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage"))
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

    {:noreply, socket}
  end

  def handle_event("delete_rubric", _, socket) do
    case Rubrics.delete_rubric(socket.assigns.rubric) do
      {:ok, _rubric} ->
        {:noreply, push_navigate(socket, to: ~p"/strands/#{socket.assigns.strand}/rubrics")}

      {:error, %Ecto.Changeset{errors: [diff_for_rubric_id: {msg, _}]}} ->
        socket =
          socket
          |> put_flash(:error, msg)
          # todo: fix (it was |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage"))
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("errors", "Something went wrong"))
          # todo: fix (it was |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage"))
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

        {:noreply, socket}
    end
  end

  def handle_event("load_diff_rubrics", params, socket) do
    %{"student_id" => student_id} = params

    case socket.assigns.students_diff_rubrics_map[student_id] do
      nil ->
        parent_rubrics_ids =
          socket.assigns.assessment_points_with_rubrics
          |> Enum.map(& &1.rubric_id)

        # key = parent rubric id
        diff_rubrics_map =
          Rubrics.list_full_rubrics(
            parent_rubrics_ids: parent_rubrics_ids,
            students_ids: [student_id]
          )
          |> Enum.map(&{&1.diff_for_rubric_id, &1})
          |> Enum.into(%{})

        # key = assessment point id, value = diff rubric or nil
        # we'll use it like `students_diff_rubrics_map[student_id][assessment_point_id]`
        student_diff_rubrics_map =
          socket.assigns.assessment_points_with_rubrics
          |> Enum.map(&{&1.id, diff_rubrics_map[&1.rubric_id]})
          |> Enum.into(%{})

        students_diff_rubrics_map =
          socket.assigns.students_diff_rubrics_map
          |> Map.put(student_id, student_diff_rubrics_map)

        {:noreply, assign(socket, :students_diff_rubrics_map, students_diff_rubrics_map)}

      _ ->
        # if students_diff_rubrics_map[student_id] already exists, just skip
        {:noreply, socket}
    end
  end
end
