defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools

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
          :for={assessment_point <- @assessment_points}
          id={"strand-assessment-point-#{assessment_point.id}"}
          class="p-6 rounded mt-6 shadow-lg bg-white"
        >
          <div class="flex items-center gap-4">
            <p class="flex-1 text-sm">
              <.badge :if={assessment_point.is_differentiation} theme="diff" class="mr-2">
                <%= gettext("Diff") %>
              </.badge>
              <strong class="inline-block mr-2 font-display font-bold">
                <%= assessment_point.curriculum_item.curriculum_component.name %>
              </strong>
              <%= assessment_point.curriculum_item.name %>
            </p>
            <%= if assessment_point.rubric do %>
              <.toggle_expand_button
                id={"strand-assessment-point-#{assessment_point.id}-toggle-button"}
                target_selector={"#goal-rubric-#{assessment_point.rubric_id}"}
              />
            <% else %>
              <.button
                theme="ghost"
                phx-click={
                  JS.push("new_rubric",
                    value: %{assessment_point_id: assessment_point.id}
                  )
                }
                phx-target={@myself}
              >
                <%= gettext("Add rubric") %>
              </.button>
            <% end %>
          </div>
          <.rubric
            :if={assessment_point.rubric}
            class="pt-6 border-t border-ltrn-lighter mt-6"
            id={"goal-rubric-#{assessment_point.rubric_id}"}
            assessment_point_id={assessment_point.id}
            rubric={assessment_point.rubric}
            criteria_text={gettext("Rubric criteria")}
            on_edit={
              JS.push("edit_rubric",
                value: %{assessment_point_id: assessment_point.id},
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
              :for={assessment_point <- @assessment_points_with_rubrics}
              id={"strand-assessment-point-#{student.id}-#{assessment_point.id}"}
              class={[
                "p-6 rounded mt-6 bg-white shadow-lg",
                if(@students_diff_rubrics_map[student.id][assessment_point.id],
                  do: "border border-ltrn-diff-accent"
                )
              ]}
            >
              <div class="flex items-center gap-4">
                <p class="flex-1 text-sm">
                  <.badge :if={assessment_point.is_differentiation} theme="diff" class="mr-2">
                    <%= gettext("Diff") %>
                  </.badge>
                  <strong class="inline-block mr-2 font-display font-bold">
                    <%= assessment_point.curriculum_item.curriculum_component.name %>
                  </strong>
                  <%= assessment_point.curriculum_item.name %>
                </p>
                <%= if @students_diff_rubrics_map[student.id][assessment_point.id] do %>
                  <.toggle_expand_button
                    id={"strand-assessment-point-#{student.id}-#{assessment_point.id}-toggle-button"}
                    target_selector={"#goal-rubric-#{@students_diff_rubrics_map[student.id][assessment_point.id].id}"}
                  />
                <% else %>
                  <.button
                    theme="ghost"
                    phx-click={
                      JS.push("new_diff_rubric",
                        value: %{
                          assessment_point_id: assessment_point.id,
                          student_id: student.id
                        }
                      )
                    }
                    phx-target={@myself}
                  >
                    <%= gettext("Add diff") %>
                  </.button>
                <% end %>
              </div>
              <.rubric
                :if={@students_diff_rubrics_map[student.id][assessment_point.id]}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"goal-rubric-#{@students_diff_rubrics_map[student.id][assessment_point.id].id}"}
                assessment_point_id={assessment_point.id}
                rubric={@students_diff_rubrics_map[student.id][assessment_point.id]}
                criteria_text={gettext("Differentiation rubric criteria")}
                on_edit={
                  JS.push("edit_diff_rubric",
                    value: %{
                      assessment_point_id: assessment_point.id,
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
        :if={@live_action == :manage_rubric}
        id="rubric-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}?tab=assessment")}
      >
        <:title><%= gettext("Rubric") %></:title>
        <p>
          <strong class="inline-block mr-2 font-display font-bold">
            <%= @assessment_point.curriculum_item.curriculum_component.name %>
          </strong>
          <%= @assessment_point.curriculum_item.name %>
        </p>
        <p :if={@student} class="mt-6 font-display font-bold">
          <%= gettext("Differentiation for %{name}", name: @student.name) %>
        </p>
        <.live_component
          module={RubricFormComponent}
          id={@rubric.id || :new}
          rubric={@rubric}
          link_to_assessment_point_id={@assessment_point && @assessment_point.id}
          diff_for_student_id={@student && @student.id}
          hide_diff_and_scale
          navigate={~p"/strands/#{@strand}?tab=assessment"}
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

  attr :assessment_point_id, :integer, required: true
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

    {:ok, socket}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:assessment_points, fn ->
        Assessments.list_assessment_points(
          strand_id: strand.id,
          preload_full_rubrics: true,
          preloads: [curriculum_item: :curriculum_component]
        )
      end)
      |> assign_new(:students, fn ->
        case assigns.selected_classes_ids do
          classes_ids when is_list(classes_ids) and classes_ids != [] ->
            Schools.list_students(
              classes_ids: classes_ids,
              check_diff_rubrics_for_strand_id: strand.id
            )

          _ ->
            []
        end
      end)

    # diff rubrics
    socket =
      socket
      |> assign_new(:assessment_points_with_rubrics, fn ->
        socket.assigns.assessment_points
        |> Enum.filter(& &1.rubric)
      end)
      |> assign_new(:students_diff_rubrics_map, fn -> %{} end)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

  # event handlers

  @impl true
  def handle_event("new_rubric", params, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == params["assessment_point_id"]))

    socket =
      socket
      |> assign(:assessment_point, assessment_point)
      |> assign(:student, nil)
      |> assign(:rubric, %Rubric{scale_id: assessment_point.scale_id})
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

    {:noreply, socket}
  end

  def handle_event("new_diff_rubric", params, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == params["assessment_point_id"]))

    student =
      socket.assigns.students
      |> Enum.find(&(&1.id == params["student_id"]))

    rubric =
      %Rubric{
        scale_id: assessment_point.scale_id,
        diff_for_rubric_id: assessment_point.rubric_id
      }

    socket =
      socket
      |> assign(:assessment_point, assessment_point)
      |> assign(:student, student)
      |> assign(:rubric, rubric)
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

    {:noreply, socket}
  end

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
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

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
      |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

    {:noreply, socket}
  end

  def handle_event("delete_rubric", _, socket) do
    case Rubrics.delete_rubric(socket.assigns.rubric) do
      {:ok, _rubric} ->
        {:noreply,
         push_navigate(socket, to: ~p"/strands/#{socket.assigns.strand}?tab=assessment")}

      {:error, %Ecto.Changeset{errors: [diff_for_rubric_id: {msg, _}]}} ->
        socket =
          socket
          |> put_flash(:error, msg)
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("errors", "Something went wrong"))
          |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/rubric/manage")

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
