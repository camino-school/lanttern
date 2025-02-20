defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Rubrics
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]

  # shared components
  import LantternWeb.RubricsComponents
  alias LantternWeb.Rubrics.StrandRubricFormOverlayComponent
  alias LantternWeb.Rubrics.AssessmentPointRubricStudentsManagementOverlayComponent

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
                  target_selector={"#goal-#{goal.id}-assessment-points-rubrics"}
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
                edit_patch={~p"/strands/#{@strand}/rubrics?edit_assessment_point_rubric=#{apr.id}"}
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
                    patch={
                      ~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}&is_diff=true"
                    }
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
                  students={apr.students}
                  criteria_text={gettext("Rubric criteria")}
                  edit_patch={~p"/strands/#{@strand}/rubrics?edit_assessment_point_rubric=#{apr.id}"}
                  manage_students_patch={
                    ~p"/strands/#{@strand}/rubrics?manage_students_of_assessment_point_rubric=#{apr.id}"
                  }
                />
                <div class="flex justify-center pt-6 border-t border-ltrn-lighter mt-6">
                  <.action
                    type="link"
                    icon_name="hero-plus-circle-mini"
                    patch={
                      ~p"/strands/#{@strand}/rubrics?new_rubric_for_goal=#{goal.id}&is_diff=true"
                    }
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
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes to view students differentiation rubrics")}
        profile_filter_opts={[strand_id: @strand.id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/rubrics"}
      />
      <.live_component
        module={StrandRubricFormOverlayComponent}
        id="strand-rubric-form-overlay"
        rubric_id={@rubric_id}
        assessment_point_id={@goal_id}
        is_diff={@is_diff}
        notify_component={@myself}
        on_cancel={JS.patch(~p"/strands/#{@strand}/rubrics")}
        title={@overlay_title}
      />
      <.live_component
        module={AssessmentPointRubricStudentsManagementOverlayComponent}
        id="manage-assessment-point-rubric-students-overlay"
        assessment_point_rubric_id={@assessment_point_rubric_id}
        current_profile={@current_user.current_profile}
        notify_component={@myself}
        on_cancel={JS.patch(~p"/strands/#{@strand}/rubrics")}
      />
    </div>
    """
  end

  attr :goal_id, :integer, required: true
  attr :criteria_text, :string, required: true
  attr :class, :any, default: nil
  attr :id, :string, required: true
  attr :rubric, :any, required: true
  attr :is_diff, :boolean, required: true
  attr :students, :list, default: []
  attr :edit_patch, :string, required: true
  attr :manage_students_patch, :string, default: nil

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
        <.action type="link" patch={@edit_patch} icon_name="hero-pencil-mini">
          <%= gettext("Edit") %>
        </.action>
      </div>
      <div :if={@manage_students_patch} class="mb-6 flex flex-wrap gap-2">
        <.person_badge :for={student <- @students} person={student} theme="diff" />
        <.action type="link" patch={@manage_students_patch} icon_name="hero-user-group-mini">
          <%= gettext("Manage diff students") %>
        </.action>
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
      |> assign(:rubric_id, nil)
      |> assign(:goal_id, nil)
      |> assign(:assessment_point_rubric_id, nil)
      |> assign(:is_diff, nil)
      |> assign(:overlay_title, nil)
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
  def update(%{action: {StrandRubricFormOverlayComponent, {action, _rubric}}}, socket)
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
      |> assign_goal_and_rubric_id()
      |> assign_assessment_point_rubric_id()

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

  defp assign_goal_and_rubric_id(%{assigns: %{params: %{"new_rubric_for_goal" => id}}} = socket) do
    if id in socket.assigns.goals_ids do
      goal_id = id
      rubric_id = :new
      overlay_title = gettext("New rubric")

      socket
      |> assign(:goal_id, goal_id)
      |> assign(:is_diff, Map.get(socket.assigns.params, "is_diff") == "true")
      |> assign(:rubric_id, rubric_id)
      |> assign(:overlay_title, overlay_title)
    else
      assign_empty_goal_and_rubric_id(socket)
    end
  end

  defp assign_goal_and_rubric_id(
         %{assigns: %{params: %{"edit_assessment_point_rubric" => id}}} = socket
       ) do
    if id in socket.assigns.assessment_points_rubrics_ids do
      %{
        rubric_id: rubric_id,
        assessment_point_id: goal_id,
        is_diff: is_diff
      } = Rubrics.get_assessment_point_rubric!(id)

      socket
      |> assign(:goal_id, goal_id)
      |> assign(:rubric_id, rubric_id)
      |> assign(:is_diff, is_diff)
      |> assign(:overlay_title, gettext("Edit rubric"))
    else
      assign_empty_goal_and_rubric_id(socket)
    end
  end

  defp assign_goal_and_rubric_id(socket),
    do: assign_empty_goal_and_rubric_id(socket)

  defp assign_empty_goal_and_rubric_id(socket) do
    socket
    |> assign(:goal_id, nil)
    |> assign(:rubric_id, nil)
  end

  defp assign_assessment_point_rubric_id(
         %{assigns: %{params: %{"manage_students_of_assessment_point_rubric" => id}}} = socket
       ) do
    if id in socket.assigns.assessment_points_rubrics_ids do
      assign(socket, :assessment_point_rubric_id, id)
    else
      assign(socket, :assessment_point_rubric_id, nil)
    end
  end

  defp assign_assessment_point_rubric_id(socket),
    do: assign(socket, :assessment_point_rubric_id, nil)
end
