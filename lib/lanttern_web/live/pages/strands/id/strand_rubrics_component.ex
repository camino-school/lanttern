defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # shared components
  alias LantternWeb.Rubrics.RubricDescriptorsComponent
  alias LantternWeb.Rubrics.RubricFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-10">
        <div>
          <blockquote class="text-base italic">
            <%= gettext(
              "\"A rubric is a coherent set of criteria for students' work that includes descriptions of levels of performance quality on the criteria.\""
            ) %>
          </blockquote>
          <p class="mt-2">
            — Susan M. Brookhart,
            <cite class="italic">
              How to create and use rubrics for formative assessment and grading
            </cite>
          </p>
        </div>
        <div id="curriculum-items-strand-rubrics" phx-update="stream">
          <.card_base
            :for={{dom_id, {goal, strand_rubrics}} <- @streams.goals_strand_rubrics}
            id={dom_id}
            class={[
              "p-6 mt-6",
              if(goal.is_differentiation, do: "border border-ltrn-diff-accent")
            ]}
          >
            <div class="flex items-center gap-4">
              <div class="flex-1">
                <.badge :if={goal.is_differentiation} theme="diff" class="mb-2">
                  <%= gettext("Curriculum differentiation") %>
                </.badge>
                <p>
                  <strong class="inline-block mr-2 font-display font-bold">
                    <%= goal.curriculum_item.curriculum_component.name %>
                  </strong>
                  <%= goal.curriculum_item.name %>
                </p>
              </div>
              <%= if strand_rubrics != [] do %>
                <.toggle_expand_button
                  id={"#{dom_id}-strand-rubrics-toggle-button"}
                  target_selector={"##{dom_id}-strand-rubrics"}
                />
              <% else %>
                <.action
                  type="link"
                  icon_name="hero-plus-circle-mini"
                  patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
                >
                  <%= gettext("Add rubric") %>
                </.action>
              <% end %>
            </div>
            <div id={"#{dom_id}-strand-rubrics"}>
              <div
                :for={strand_rubric <- strand_rubrics}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"strand-rubric-#{strand_rubric.id}"}
              >
                <div class="flex items-start gap-4 mb-6">
                  <div class="flex-1">
                    <.badge :if={strand_rubric.is_differentiation} theme="diff" class="mb-2">
                      <%= gettext("Rubric differentiation") %>
                    </.badge>
                    <p class="font-display font-black">
                      <%= gettext("Rubric criteria") %>: <%= strand_rubric.rubric.criteria %>
                    </p>
                  </div>
                  <.action
                    type="link"
                    patch={~p"/strands/#{@strand}/rubrics?edit_rubric=#{strand_rubric.rubric.id}"}
                    icon_name="hero-pencil-mini"
                  >
                    <%= gettext("Edit") %>
                  </.action>
                </div>
                <.live_component
                  module={RubricDescriptorsComponent}
                  id={"#{dom_id}-rubric-#{strand_rubric.rubric.id}-descriptors"}
                  rubric={strand_rubric.rubric}
                  class="overflow-x-auto"
                />
              </div>
            </div>
          </.card_base>
        </div>
        <%!-- <.card_base :for={goal <- @goals} id={"strand-assessment-point-#{goal.id}"} class="p-6 mt-6">
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
            patch={~p"/strands/#{@strand}/rubrics?edit_rubric_for_goal=#{goal.id}"}
          />
        </.card_base>
        <section id="differentiation-rubrics-section" class="pb-10 mt-10">
          <h4 class="font-display font-black text-xl text-ltrn-subtle">
            <%= gettext("Differentiation") %>
          </h4>
          <.action
            type="button"
            phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
            icon_name="hero-chevron-down-mini"
            class="mt-4"
          >
            <%= format_action_items_text(
              @selected_classes,
              gettext("Select a class to view differentiation rubrics")
            ) %>
          </.action>
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
                if(@current_student_diff_rubrics_map[goal.rubric_id],
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
                <%= if @current_student_diff_rubrics_map[goal.rubric_id] do %>
                  <.toggle_expand_button
                    id={"strand-assessment-point-#{student.id}-#{goal.id}-toggle-button"}
                    target_selector={"#goal-student-#{student.id}-rubric-#{@current_student_diff_rubrics_map[goal.rubric_id].id}"}
                  />
                <% else %>
                  <.button
                    type="link"
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
                :if={@current_student_diff_rubrics_map[goal.rubric_id]}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"goal-student-#{student.id}-rubric-#{@current_student_diff_rubrics_map[goal.rubric_id].id}"}
                goal_id={goal.id}
                rubric={@current_student_diff_rubrics_map[goal.rubric_id]}
                criteria_text={gettext("Differentiation rubric criteria")}
                patch={
                  ~p"/strands/#{@strand}/rubrics?edit_diff_rubric_for_goal=#{goal.id}&student=#{student.id}"
                }
              />
            </div>
          </div>
        </section> --%>
      </.responsive_container>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes to view students differentiation rubrics")}
        profile_filter_opts={[strand_id: @strand.id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/rubrics"}
      />
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

  # attr :goal_id, :integer, required: true
  # attr :criteria_text, :string, required: true
  # attr :class, :any, default: nil
  # attr :id, :string, required: true
  # attr :rubric, :any, required: true
  # attr :patch, :string, required: true

  # def rubric(assigns) do
  #   ~H"""
  #   <div class={@class} id={@id}>
  #     <p class="mb-6 font-display font-black">
  #       <%= @criteria_text %>: <%= @rubric.criteria %>
  #       <.link patch={@patch} class="ml-2 underline text-ltrn-subtle hover:text-ltrn-dark">
  #         <%= gettext("Edit") %>
  #       </.link>
  #     </p>
  #     <div class="overflow-x-auto">
  #       <.rubric_descriptors rubric={@rubric} />
  #     </div>
  #   </div>
  #   """
  # end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:rubric, nil)
      |> assign(:curriculum_item, nil)
      |> assign(:current_student_diff_rubrics_map, %{})
      |> stream_configure(
        :goals_strand_rubrics,
        dom_id: fn
          {goal, _strand_rubrics} -> "assessment-point-#{goal.id}"
          _ -> ""
        end
      )
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
    |> stream_goals_strand_rubrics()
    |> assign_strand_classes_filter()
    |> assign_goals()
    |> assign_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_goals_strand_rubrics(socket) do
    goals_strand_rubrics =
      Rubrics.list_strand_rubrics_grouped_by_goal(socket.assigns.strand.id)

    socket
    |> stream(:goals_strand_rubrics, goals_strand_rubrics)
  end

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
    |> assign(:goals_rubrics_ids, Enum.map(goals_with_rubrics, & &1.rubric_id))
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

    socket
    |> assign(:students, students)
    |> assign(:students_ids, Enum.map(students, & &1.id))
  end

  defp assign_goal_rubric_and_student(
         %{assigns: %{params: %{"new_rubric_for_goal" => binary_id}}} = socket
       ) do
    with {id, _} <- Integer.parse(binary_id), true <- id in socket.assigns.goals_ids do
      goal =
        Assessments.get_assessment_point(id, preloads: [curriculum_item: :curriculum_component])

      rubric = %Rubric{scale_id: goal.scale_id}

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, nil)
    else
      _ -> assign_empty_goal_rubric_and_student(socket)
    end
  end

  defp assign_goal_rubric_and_student(
         %{assigns: %{params: %{"edit_rubric_for_goal" => binary_id}}} = socket
       ) do
    with {id, _} <- Integer.parse(binary_id), true <- id in socket.assigns.goals_ids do
      goal =
        Assessments.get_assessment_point(id,
          preload_full_rubrics: true,
          preloads: [curriculum_item: :curriculum_component]
        )

      rubric = goal.rubric

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, nil)
    else
      _ -> assign_empty_goal_rubric_and_student(socket)
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
      goal =
        Assessments.get_assessment_point(goal_id,
          preloads: [curriculum_item: :curriculum_component]
        )

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
      _ -> assign_empty_goal_rubric_and_student(socket)
    end
  end

  defp assign_goal_rubric_and_student(
         %{
           assigns: %{
             params: %{
               "edit_diff_rubric_for_goal" => goal_binary_id,
               "student" => student_binary_id
             }
           }
         } = socket
       ) do
    with {goal_id, _} <- Integer.parse(goal_binary_id),
         true <- goal_id in socket.assigns.goals_ids,
         {student_id, _} <- Integer.parse(student_binary_id),
         true <- student_id in socket.assigns.students_ids do
      goal =
        Assessments.get_assessment_point(goal_id,
          preloads: [curriculum_item: :curriculum_component]
        )

      rubric = socket.assigns.current_student_diff_rubrics_map[goal.rubric_id]

      student =
        Schools.get_student(student_id)

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, student)
    else
      _ -> assign_empty_goal_rubric_and_student(socket)
    end
  end

  defp assign_goal_rubric_and_student(socket),
    do: assign_empty_goal_rubric_and_student(socket)

  defp assign_empty_goal_rubric_and_student(socket) do
    socket
    |> assign(:goal, nil)
    |> assign(:rubric, nil)
    |> assign(:student, nil)
  end

  # event handlers

  @impl true
  def handle_event("delete_rubric", _, socket) do
    case Rubrics.delete_rubric(socket.assigns.rubric) do
      {:ok, _rubric} ->
        socket =
          socket
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/rubrics")
          |> put_flash(:info, gettext("Rubric deleted"))

        {:noreply, socket}

      {:error, %Ecto.Changeset{errors: [diff_for_rubric_id: {msg, _}]}} ->
        socket =
          socket
          |> put_flash(:error, msg)
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("errors", "Something went wrong"))
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubrics")

        {:noreply, socket}
    end
  end

  def handle_event("load_diff_rubrics", %{"student_id" => student_id}, socket) do
    # key = parent rubric id
    current_student_diff_rubrics_map =
      Rubrics.list_full_rubrics(
        parent_rubrics_ids: socket.assigns.goals_rubrics_ids,
        students_ids: [student_id]
      )
      |> Enum.map(&{&1.diff_for_rubric_id, &1})
      |> Enum.into(%{})

    {:noreply,
     assign(socket, :current_student_diff_rubrics_map, current_student_diff_rubrics_map)}
  end
end
