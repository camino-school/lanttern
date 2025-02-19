defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # shared components
  import LantternWeb.RubricsComponents
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
        <div id="strand-rubrics-list" phx-update="stream">
          <.card_base
            :for={
              {dom_id, {goal, assessment_points_rubrics}} <- @streams.strand_assessment_points_rubrics
            }
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
              <%= if assessment_points_rubrics != [] do %>
                <.toggle_expand_button
                  id={"strand-assessment-point-#{goal.id}-toggle-button"}
                  target_selector={"#goal-#{goal.id}-rubrics"}
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
            <div
              :if={assessment_points_rubrics != []}
              id={"goal-#{goal.id}-assessment-points-rubrics"}
            >
              <.rubric
                :for={apr <- assessment_points_rubrics}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"assessment-point-rubric-#{apr.id}"}
                goal_id={goal.id}
                rubric={apr.rubric}
                is_diff={apr.is_diff}
                criteria_text={gettext("Rubric criteria")}
                patch={~p"/strands/#{@strand}/rubrics?edit_assessment_point_rubric=#{apr.id}"}
              />
              <div class="flex justify-center pt-6 border-t border-ltrn-lighter mt-6">
                <.action
                  type="link"
                  icon_name="hero-plus-circle-mini"
                  patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
                  class="mx-auto"
                >
                  <%= gettext("Add another rubric to this curriculum item") %>
                </.action>
              </div>
            </div>
          </.card_base>
        </div>
        <section id="differentiation-rubrics-section" class="pb-10 mt-10">
          <h4 class="font-display font-black text-xl text-ltrn-diff-dark">
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
          <div id="strand-diff-rubrics-list" phx-update="stream">
            <.card_base
              :for={
                {dom_id, {goal, assessment_points_rubrics}} <-
                  @streams.strand_diff_assessment_points_rubrics
              }
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
                <%= if assessment_points_rubrics != [] do %>
                  <.toggle_expand_button
                    id={"strand-assessment-point-#{goal.id}-toggle-button"}
                    target_selector={"#goal-#{goal.id}-assessment-points-rubrics-diff"}
                  />
                <% else %>
                  <.action
                    type="link"
                    icon_name="hero-plus-circle-mini"
                    patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
                    theme="diff"
                  >
                    <%= gettext("Add diff rubric") %>
                  </.action>
                <% end %>
              </div>
              <div
                :if={assessment_points_rubrics != []}
                id={"goal-#{goal.id}-assessment-points-rubrics-diff"}
              >
                <.rubric
                  :for={apr <- assessment_points_rubrics}
                  class="pt-6 border-t border-ltrn-lighter mt-6"
                  id={"assessment-point-rubric-#{apr.id}"}
                  goal_id={goal.id}
                  rubric={apr.rubric}
                  is_diff={apr.is_diff}
                  criteria_text={gettext("Rubric criteria")}
                  patch={~p"/strands/#{@strand}/rubrics?edit_assessment_point_rubric=#{apr.id}"}
                />
                <div class="flex justify-center pt-6 border-t border-ltrn-lighter mt-6">
                  <.action
                    type="link"
                    icon_name="hero-plus-circle-mini"
                    patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
                    class="mx-auto"
                    theme="diff"
                  >
                    <%= gettext("Add another differentiation rubric to this curriculum item") %>
                  </.action>
                </div>
              </div>
            </.card_base>
          </div>
          <%!-- <div role="tablist" class="flex flex-wrap items-center gap-2 mt-6">
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
          </div> --%>
        </section>
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

  attr :goal_id, :integer, required: true
  attr :criteria_text, :string, required: true
  attr :class, :any, default: nil
  attr :id, :string, required: true
  attr :rubric, :any, required: true
  attr :is_diff, :boolean, required: true
  attr :patch, :string, required: true

  def rubric(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div class="flex items-start gap-4 mb-6">
        <div class="flex-1">
          <.badge :if={@is_diff} theme="diff" class="mb-2">
            <%= gettext("Rubric differentiation") %>
          </.badge>
          <p class="font-display font-black">
            <%= @criteria_text %>: <%= @rubric.criteria %>
          </p>
        </div>
        <.action type="link" patch={@patch} icon_name="hero-pencil-mini">
          <%= gettext("Edit") %>
        </.action>
      </div>
      <div :if={is_list(@rubric.students) && @rubric.students != []} class="mb-6 flex flex-wrap gap-2">
        <.person_badge :for={student <- @rubric.students} person={student} theme="diff" />
      </div>
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
      |> assign(:current_student_diff_rubrics_map, %{})
      |> stream_configure(
        :strand_assessment_points_rubrics,
        dom_id: fn {ap, _rubrics} -> "assessment-point-#{ap.id}" end
      )
      |> stream_configure(
        :strand_diff_assessment_points_rubrics,
        dom_id: fn {ap, _rubrics} -> "assessment-point-#{ap.id}-diff" end
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
    |> assign_strand_classes_filter()
    |> stream_strand_assessment_points_rubrics()
    |> stream_strand_diff_assessment_points_rubrics()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_strand_assessment_points_rubrics(socket) do
    strand_assessment_points_rubrics =
      Rubrics.list_strand_assessment_points_rubrics(socket.assigns.strand.id)

    assessment_points_rubrics_ids =
      strand_assessment_points_rubrics
      |> Enum.flat_map(fn {_, aprs} -> Enum.map(aprs, &"#{&1.id}") end)
      |> Enum.uniq()

    socket
    |> stream(:strand_assessment_points_rubrics, strand_assessment_points_rubrics)
    |> assign(:assessment_points_rubrics_ids, assessment_points_rubrics_ids)
  end

  defp stream_strand_diff_assessment_points_rubrics(socket) do
    strand_diff_assessment_points_rubrics =
      Rubrics.list_strand_diff_assessment_points_rubrics(
        socket.assigns.strand.id,
        classes_ids: socket.assigns.selected_classes_ids
      )

    assessment_points_rubrics_ids =
      strand_diff_assessment_points_rubrics
      |> Enum.flat_map(fn {_, aprs} -> Enum.map(aprs, &"#{&1.id}") end)
      |> Enum.concat(socket.assigns.assessment_points_rubrics_ids)
      |> Enum.uniq()

    # create goals_ids assign here, as diff rubrics list all goals
    goals_ids =
      strand_diff_assessment_points_rubrics
      |> Enum.map(fn {goal, _} -> "#{goal.id}" end)
      |> Enum.uniq()

    socket
    |> stream(:strand_diff_assessment_points_rubrics, strand_diff_assessment_points_rubrics)
    |> assign(:assessment_points_rubrics_ids, assessment_points_rubrics_ids)
    |> assign(:goals_ids, goals_ids)
  end

  defp assign_goal_rubric_and_student(
         %{assigns: %{params: %{"new_rubric_for_goal" => id}}} = socket
       ) do
    if id in socket.assigns.goals_ids do
      goal =
        Assessments.get_assessment_point(id, preloads: [curriculum_item: :curriculum_component])

      rubric = %Rubric{scale_id: goal.scale_id}

      socket
      |> assign(:goal, goal)
      |> assign(:rubric, rubric)
      |> assign(:student, nil)
    else
      assign_empty_goal_rubric_and_student(socket)
    end
  end

  defp assign_goal_rubric_and_student(
         %{assigns: %{params: %{"edit_assessment_point_rubric" => id}}} = socket
       ) do
    if id in socket.assigns.assessment_points_rubrics_ids do
      assessment_point_rubric =
        Rubrics.get_assessment_point_rubric!(id,
          preloads: [assessment_point: [curriculum_item: :curriculum_component]]
        )

      rubric =
        Rubrics.get_full_rubric!(assessment_point_rubric.rubric_id)

      socket
      |> assign(:goal, assessment_point_rubric.assessment_point)
      |> assign(:rubric, rubric)
      |> assign(:student, nil)
    else
      assign_empty_goal_rubric_and_student(socket)
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
    case Rubrics.delete_rubric(socket.assigns.rubric, unlink_assessment_points: true) do
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
