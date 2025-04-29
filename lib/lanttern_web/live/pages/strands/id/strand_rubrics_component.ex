defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  # alias Lanttern.Schools

  # shared components
  alias LantternWeb.Rubrics.RubricDescriptorsComponent
  alias LantternWeb.Rubrics.RubricDiffInfoOverlayComponent
  alias LantternWeb.Rubrics.RubricFormOverlayComponent

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
            :for={{dom_id, {goal, rubrics}} <- @streams.goals_rubrics}
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
              <%= if rubrics != [] do %>
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
            <div
              :if={rubrics != []}
              phx-hook="Sortable"
              id={"#{dom_id}-strand-rubrics"}
              data-sortable-handle=".sortable-handle"
              data-group-name="goal"
              data-group-id={goal.id}
            >
              <.rubric
                :for={rubric <- rubrics}
                class="pt-6 border-t border-ltrn-lighter mt-6"
                id={"rubric-#{rubric.id}"}
                goal={goal}
                rubric={rubric}
                edit_patch={~p"/strands/#{@strand}/rubrics?edit_rubric=#{rubric.id}"}
              />
              <div class="flex justify-center pt-6 border-t border-ltrn-lighter mt-6">
                <.action
                  type="link"
                  icon_name="hero-plus-circle-mini"
                  patch={~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}"}
                  class="mx-auto"
                >
                  <%= gettext("Add another rubric to assess this goal") %>
                </.action>
              </div>
            </div>
          </.card_base>
        </div>
        <section id="differentiation-rubrics-section" class="pb-10 mt-10">
          <h4 class="font-display font-black text-xl text-ltrn-diff-dark">
            <%= gettext("Differentiation") %>
          </h4>
          <div id="strand-diff-rubrics-list" phx-update="stream">
            <.card_base
              :for={
                {dom_id, {goal, rubrics}} <-
                  @streams.diff_goals_rubrics
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
                <%= if rubrics != [] do %>
                  <.toggle_expand_button
                    id={"#{dom_id}-strand-rubrics-toggle-button"}
                    target_selector={"##{dom_id}-strand-rubrics"}
                  />
                <% else %>
                  <.action
                    type="link"
                    icon_name="hero-plus-circle-mini"
                    patch={~p"/strands/#{@strand}/rubrics?new_diff_rubric_for_goal=#{goal.id}"}
                    theme="diff"
                  >
                    <%= gettext("Add diff rubric") %>
                  </.action>
                <% end %>
              </div>
              <div
                :if={rubrics != []}
                phx-hook="Sortable"
                id={"#{dom_id}-strand-rubrics"}
                data-sortable-handle=".sortable-handle"
                data-group-name="goal-diff"
                data-group-id={goal.id}
              >
                <.rubric
                  :for={rubric <- rubrics}
                  class="pt-6 border-t border-ltrn-lighter mt-6"
                  id={"assessment-point-rubric-#{rubric.id}"}
                  goal={goal}
                  rubric={rubric}
                  edit_patch={~p"/strands/#{@strand}/rubrics?edit_rubric=#{rubric.id}"}
                  diff_students_info_patch={
                    ~p"/strands/#{@strand}/rubrics?diff_info_for_rubric=#{rubric.id}"
                  }
                />
                <div class="flex justify-center pt-6 border-t border-ltrn-lighter mt-6">
                  <.action
                    type="link"
                    icon_name="hero-plus-circle-mini"
                    patch={~p"/strands/#{@strand}/rubrics?new_diff_rubric_for_goal=#{goal.id}"}
                    class="mx-auto"
                    theme="diff"
                  >
                    <%= gettext("Add another differentiation rubric to assess this goal") %>
                  </.action>
                </div>
              </div>
            </.card_base>
          </div>
        </section>
      </.responsive_container>
      <.live_component
        :if={@rubric}
        module={RubricFormOverlayComponent}
        id="strand-rubric-overlay"
        rubric={@rubric}
        title={@rubric_overlay_title}
        on_cancel={JS.patch(~p"/strands/#{@strand}/rubrics")}
        notify_component={@myself}
      />
      <.live_component
        :if={@diff_info_for_rubric}
        module={RubricDiffInfoOverlayComponent}
        id="diff-rubric-students-info"
        rubric={@diff_info_for_rubric}
        current_profile={@current_user.current_profile}
        on_cancel={JS.patch(~p"/strands/#{@strand}/rubrics")}
      />
    </div>
    """
  end

  attr :goal, AssessmentPoint, required: true
  attr :class, :any, default: nil
  attr :id, :string, required: true
  attr :rubric, Rubric, required: true
  attr :edit_patch, :string, required: true

  attr :diff_students_info_patch, :string,
    default: nil,
    doc: "Required only if `has_diff_students` is true"

  def rubric(assigns) do
    has_diff_students =
      is_list(assigns.rubric.diff_students) &&
        assigns.rubric.diff_students != []

    assigns = assign(assigns, :has_diff_students, has_diff_students)

    ~H"""
    <div class={@class} id={@id}>
      <div class="flex items-center gap-2 mb-6">
        <.drag_handle class="sortable-handle" />
        <div class="flex-1 pr-2">
          <.badge :if={@rubric.is_differentiation} theme="diff" class="mb-2">
            <%= gettext("Rubric differentiation") %>
          </.badge>
          <p class="font-display font-black">
            <%= gettext("Rubric criteria") %>: <%= @rubric.criteria %>
          </p>
        </div>
        <.action type="link" patch={@edit_patch} icon_name="hero-pencil-mini">
          <%= gettext("Edit") %>
        </.action>
      </div>
      <div
        :if={@rubric.is_differentiation || @goal.is_differentiation}
        class={[
          "flex items-center gap-2 p-4 rounded-sm mb-6",
          if(@has_diff_students, do: "bg-ltrn-diff-lightest", else: "bg-ltrn-lightest")
        ]}
      >
        <%= if @has_diff_students do %>
          <p class="text-ltrn-diff-dark"><%= gettext("Linked students") %></p>
          <div class="flex-1 flex flex-wrap gap-2">
            <.person_badge
              :for={student <- @rubric.diff_students}
              person={student}
              theme="diff"
              truncate
              navigate={~p"/school/students/#{student}"}
            />
          </div>
          <.action
            type="link"
            patch={@diff_students_info_patch}
            icon_name="hero-information-circle-mini"
            theme="diff"
          >
            <%= gettext("Info") %>
          </.action>
        <% else %>
          <p class="flex-1 text-ltrn-subtle">
            <%= gettext("No linked students for selected classes") %>
          </p>
          <.action
            type="link"
            patch={@diff_students_info_patch}
            icon_name="hero-information-circle-mini"
            theme="diff"
          >
            <%= gettext("Info") %>
          </.action>
        <% end %>
      </div>
      <.live_component
        module={RubricDescriptorsComponent}
        id={"#{@id}-rubric-descriptors"}
        rubric={@rubric}
        class="overflow-x-auto"
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:rubric_overlay_title, nil)
      |> assign(:curriculum_item, nil)
      |> assign(:current_student_diff_rubrics_map, %{})
      |> stream_configure(
        :goals_rubrics,
        dom_id: fn
          {goal, _rubrics} -> "goal-#{goal.id}"
          _ -> ""
        end
      )
      |> stream_configure(
        :diff_goals_rubrics,
        dom_id: fn
          {goal, _rubrics} -> "goal-#{goal.id}-diff"
          _ -> ""
        end
      )
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {RubricFormOverlayComponent, {action, _rubric}}}, socket)
      when action in [:created, :updated, :deleted] do
    flash_message =
      case action do
        :created -> {:info, gettext("Rubric created successfully")}
        :updated -> {:info, gettext("Rubric updated successfully")}
        :deleted -> {:info, gettext("Rubric deleted successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: ~p"/strands/#{socket.assigns.strand}/rubrics"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      # |> assign_goal_rubric_and_student()
      |> assign_rubric()
      |> assign_diff_info_for_rubric()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_goals_rubrics()
    |> stream_diff_goals_rubrics()
    # |> assign_goals()
    # |> assign_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_goals_rubrics(socket) do
    goals_rubrics =
      Rubrics.list_strand_rubrics_grouped_by_goal(socket.assigns.strand.id, exclude_diff: true)

    # keep track of goals ids for edit permission check
    goals_ids =
      goals_rubrics
      |> Enum.map(fn {goal, _rubrics} -> "#{goal.id}" end)

    # keep track of rubrics ids for edit permission check
    rubrics_ids =
      goals_rubrics
      |> Enum.flat_map(fn {_, rubrics} -> Enum.map(rubrics, &"#{&1.id}") end)

    # keep track of rubrics ids order and index for sorting

    # "spec" %{"goal_id" => [rubric_id, ...], ...}
    goals_rubrics_order_map =
      goals_rubrics
      |> Enum.map(fn {goal, strands_rubrics} ->
        rubrics_ids = Enum.map(strands_rubrics, & &1.id)
        {"#{goal.id}", rubrics_ids}
      end)
      |> Enum.into(%{})

    socket
    |> stream(:goals_rubrics, goals_rubrics)
    |> assign(:goals_rubrics_order_map, goals_rubrics_order_map)
    |> assign(:goals_ids, goals_ids)
    |> assign(:rubrics_ids, rubrics_ids)
  end

  defp stream_diff_goals_rubrics(socket) do
    diff_goals_rubrics =
      Rubrics.list_strand_rubrics_grouped_by_goal(
        socket.assigns.strand.id,
        only_diff: true,
        preload_diff_students_from_classes_ids: socket.assigns.selected_classes_ids
      )

    # keep track of goals ids for edit permission check
    goals_ids =
      diff_goals_rubrics
      |> Enum.map(fn {goal, _rubrics} -> "#{goal.id}" end)
      |> Enum.concat(socket.assigns.goals_ids)
      |> Enum.uniq()

    # keep track of rubrics ids for edit permission check
    rubrics_ids =
      diff_goals_rubrics
      |> Enum.flat_map(fn {_, strands_rubrics} -> Enum.map(strands_rubrics, &"#{&1.id}") end)
      |> Enum.concat(socket.assigns.rubrics_ids)

    # keep track of rubrics ids order and index for sorting

    # "spec" %{"goal_id" => [rubric_id, ...], ...}
    diff_goals_rubrics_order_map =
      diff_goals_rubrics
      |> Enum.map(fn {goal, strands_rubrics} ->
        rubrics_ids = Enum.map(strands_rubrics, & &1.id)
        {"#{goal.id}", rubrics_ids}
      end)
      |> Enum.into(%{})

    socket
    |> stream(:diff_goals_rubrics, diff_goals_rubrics)
    |> assign(:diff_goals_rubrics_order_map, diff_goals_rubrics_order_map)
    |> assign(:goals_ids, goals_ids)
    |> assign(:rubrics_ids, rubrics_ids)
  end

  defp assign_rubric(%{assigns: %{params: %{"edit_rubric" => rubric_id}}} = socket) do
    if rubric_id in socket.assigns.rubrics_ids do
      rubric = Rubrics.get_rubric!(rubric_id)

      title =
        if rubric.is_differentiation,
          do: gettext("Edit differentiation rubric"),
          else: gettext("Edit rubric")

      socket
      |> assign(:rubric, rubric)
      |> assign(:rubric_overlay_title, title)
    else
      assign(socket, :rubric, nil)
    end
  end

  defp assign_rubric(%{assigns: %{params: %{"new_rubric_for_goal" => goal_id}}} = socket) do
    if goal_id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(goal_id)

      rubric =
        %Rubric{
          strand_id: socket.assigns.strand.id,
          scale_id: goal.scale_id,
          curriculum_item_id: goal.curriculum_item_id
        }

      socket
      |> assign(:rubric, rubric)
      |> assign(:rubric_overlay_title, gettext("New rubric"))
    else
      assign(socket, :rubric, nil)
    end
  end

  defp assign_rubric(%{assigns: %{params: %{"new_diff_rubric_for_goal" => goal_id}}} = socket) do
    if goal_id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(goal_id)

      rubric =
        %Rubric{
          strand_id: socket.assigns.strand.id,
          scale_id: goal.scale_id,
          curriculum_item_id: goal.curriculum_item_id,
          is_differentiation: true
        }

      socket
      |> assign(:rubric, rubric)
      |> assign(:rubric_overlay_title, gettext("New differentiation rubric"))
    else
      assign(socket, :rubric, nil)
    end
  end

  defp assign_rubric(socket), do: assign(socket, :rubric, nil)

  defp assign_diff_info_for_rubric(
         %{assigns: %{params: %{"diff_info_for_rubric" => rubric_id}}} = socket
       ) do
    if rubric_id in socket.assigns.rubrics_ids do
      rubric = Rubrics.get_rubric!(rubric_id)
      assign(socket, :diff_info_for_rubric, rubric)
    else
      assign(socket, :diff_info_for_rubric, nil)
    end
  end

  defp assign_diff_info_for_rubric(socket), do: assign(socket, :diff_info_for_rubric, nil)

  # event handlers

  @impl true
  # view Sortable hook for payload info
  def handle_event("sortable_update", payload, socket) do
    %{
      "groupName" => group,
      "groupId" => goal_id,
      "oldIndex" => old_index,
      "newIndex" => new_index
    } = payload

    goals_rubrics_order_map =
      case group do
        "goal" -> socket.assigns.goals_rubrics_order_map
        "goal-diff" -> socket.assigns.diff_goals_rubrics_order_map
      end

    strand_rubrics_ids =
      goals_rubrics_order_map
      |> Map.get(goal_id)

    {changed_id, rest} = List.pop_at(strand_rubrics_ids, old_index)
    strand_rubrics_ids = List.insert_at(rest, new_index, changed_id)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    Rubrics.update_rubrics_positions(strand_rubrics_ids)

    goals_rubrics_order_map =
      goals_rubrics_order_map
      |> Map.put(goal_id, strand_rubrics_ids)

    goals_rubrics_order_map_assign =
      case group do
        "goal" -> :goals_rubrics_order_map
        "goal-diff" -> :diff_goals_rubrics_order_map
      end

    {:noreply, assign(socket, goals_rubrics_order_map_assign, goals_rubrics_order_map)}
  end

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
end
