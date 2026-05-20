defmodule LantternWeb.MarkingLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Curricula
  alias Lanttern.Filters
  alias Lanttern.LearningContext

  # shared components
  import LantternWeb.AssessmentsComponents

  import LantternWeb.FiltersHelpers,
    only: [assign_strand_classes_filter: 1, assign_user_filters: 2]

  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Assessments.AssessmentsGridComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)
      |> assign_strand_classes_filter()
      |> assign_user_filters([:assessment_view])
      |> assign_assessment_points_ids()
      |> assign_strand_curriculum_items()

    {:ok, socket}
  end

  defp assign_strand(socket, %{"id" => id}) do
    LearningContext.get_strand(id,
      show_starred_for_profile_id: socket.assigns.current_user.current_profile_id,
      preloads: [:subjects, :years]
    )
    |> case do
      strand when is_nil(strand) ->
        socket
        |> put_flash(:error, gettext("Couldn't find strand"))
        |> redirect(to: ~p"/strands")

      strand ->
        socket
        |> assign(:strand, strand)
        |> assign(:page_title, strand.name)
    end
  end

  defp assign_strand_curriculum_items(socket) do
    items =
      Curricula.list_strand_curriculum_items(
        socket.assigns.strand.id,
        preloads: :curriculum_component
      )

    assign(socket, :strand_curriculum_items, items)
  end

  defp assign_assessment_points_ids(socket) do
    assessment_points_ids =
      Assessments.list_strand_assessment_point_ids(socket.assigns.strand.id)
      |> Enum.map(&"#{&1}")

    assign(socket, :assessment_points_ids, assessment_points_ids)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_goal()

    {:noreply, socket}
  end

  defp assign_goal(%{assigns: %{params: %{"edit_assessment_point" => id}}} = socket) do
    if id in socket.assigns.assessment_points_ids do
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
        "change_view",
        %{"view" => view},
        %{assigns: %{current_assessment_view: view}} = socket
      ),
      do: {:noreply, socket}

  def handle_event("change_view", %{"view" => view}, socket) do
    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_view, view)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment/marking")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # info handlers

  @impl true
  def handle_info(
        {AssessmentPointFormOverlayComponent, {action, _assessment_point}},
        socket
      )
      when action in [:created, :updated, :deleted, :deleted_with_entries] do
    flash_msg =
      case action do
        :created -> gettext("Assessment point created successfully")
        :updated -> gettext("Assessment point updated successfully")
        :deleted -> gettext("Assessment point deleted successfully")
        :deleted_with_entries -> gettext("Assessment point and entries deleted successfully")
      end

    socket =
      socket
      |> put_flash(:info, flash_msg)
      |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment/marking")

    {:noreply, socket}
  end
end
