defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2]

  alias Lanttern.Assessments
  alias Lanttern.Curricula
  alias Lanttern.Filters

  # shared components
  import LantternWeb.AssessmentsComponents
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Assessments.AssessmentsGridComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center gap-4">
        <.assessment_group_by_dropdow
          current_assessment_group_by={@current_assessment_group_by}
          on_change={
            fn group_by ->
              JS.push("change_group_by", value: %{"group_by" => group_by}, target: @myself)
            end
          }
        />
        <.assessment_view_dropdow
          current_assessment_view={@current_assessment_view}
          on_change={fn view -> JS.push("change_view", value: %{"view" => view}, target: @myself) end}
        />
      </.action_bar>
      <.responsive_container :if={@selected_classes_ids == []} class="py-10">
        <p class="flex items-center gap-2">
          <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
          {gettext("Select a class above to view full assessments grid")}
        </p>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:strand_assessment_grid}
        current_user={@current_user}
        current_assessment_group_by={@current_assessment_group_by}
        current_assessment_view={@current_assessment_view}
        strand_id={@strand.id}
        classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/assessment"}
      />
      <.live_component
        :if={@goal}
        module={AssessmentPointFormOverlayComponent}
        id={"strand-#{@strand.id}-goal-form-overlay"}
        notify_component={@myself}
        assessment_point={@goal}
        title={gettext("Strand goal")}
        on_cancel={JS.patch(~p"/strands/#{@strand}/assessment")}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {AssessmentPointFormOverlayComponent, {action, _assessment_point}}},
        socket
      )
      when action in [:created, :updated, :deleted, :deleted_with_entries] do
    flash_message =
      case action do
        :created ->
          {:info, gettext("Assessment point created successfully")}

        :updated ->
          {:info, gettext("Assessment point updated successfully")}

        :deleted ->
          {:info, gettext("Assessment point deleted successfully")}

        :deleted_with_entries ->
          {:info, gettext("Assessment point and entries deleted successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: ~p"/strands/#{socket.assigns.strand}/assessment"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_goal()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:assessment_view, :assessment_group_by])
    |> assign_goals_ids()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_goals_ids(socket) do
    goals_ids =
      Curricula.list_strand_curriculum_items(socket.assigns.strand.id)
      |> Enum.map(&"#{&1.assessment_point_id}")

    socket
    |> assign(:goals_ids, goals_ids)
  end

  defp assign_goal(%{assigns: %{params: %{"edit_assessment_point" => id}}} = socket) do
    if id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(id)
      assign(socket, :goal, goal)
    else
      assign(socket, :goal, nil)
    end
  end

  defp assign_goal(socket), do: assign(socket, :goal, nil)

  # event handlers

  @impl true
  def handle_event(
        "change_group_by",
        %{"group_by" => group_by},
        %{assigns: %{current_assessment_group_by: current_assessment_group_by}} = socket
      )
      when group_by == current_assessment_group_by,
      do: {:noreply, socket}

  def handle_event("change_group_by", %{"group_by" => group_by}, socket) do
    # TODO
    # before applying the group_by change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_group_by: group_by}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_group_by, group_by)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

  def handle_event(
        "change_view",
        %{"view" => view},
        %{assigns: %{current_assessment_view: current_assessment_view}} = socket
      )
      when view == current_assessment_view,
      do: {:noreply, socket}

  def handle_event("change_view", %{"view" => view}, socket) do
    # TODO
    # before applying the view change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_view, view)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end
end
