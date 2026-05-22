defmodule LantternWeb.MarkingLive do
  use LantternWeb, :live_view

  alias Lanttern.AssessmentComposition
  alias Lanttern.Assessments
  alias Lanttern.Curricula
  alias Lanttern.LearningContext

  # shared components
  import LantternWeb.AssessmentsComponents

  import LantternWeb.FiltersHelpers,
    only: [
      assign_strand_available_classes: 1,
      assign_strand_class_assignments: 1,
      assign_strand_classes_from_url: 3,
      assign_url_filters: 2,
      url_filter_params: 1
    ]

  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Assessments.AssessmentsGridComponent
  alias LantternWeb.LearningContext.StrandClassAssignmentOverlayComponent

  # params that come from the route pattern, not the query string
  @route_params ["id"]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)
      |> assign_strand_available_classes()
      |> assign_strand_class_assignments()
      |> assign_assessment_points_ids()
      |> assign_strand_curriculum_items()
      |> assign_strand_composition_assessment_points()

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

  defp assign_strand_composition_assessment_points(socket) do
    composition_aps =
      Assessments.list_strand_composition_assessment_points(socket.assigns.strand.id)

    assign(socket, :strand_composition_assessment_points, composition_aps)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign_url_params(params)
      |> assign_class_filter()
      |> assign_composition_filter()
      |> assign_goal()

    {:noreply, socket}
  end

  defp assign_url_params(socket, params) do
    query_params = Map.drop(params, @route_params)

    applied_filters_count =
      [Map.has_key?(query_params, "classes_ids"), Map.has_key?(query_params, "composition_ap_id")]
      |> Enum.count(& &1)

    socket
    |> assign(:params, params)
    |> assign(:query_params, query_params)
    |> assign(:applied_filters_count, applied_filters_count)
    |> assign(:url_filter_params, url_filter_params(query_params))
    |> assign_url_filters(query_params)
  end

  defp assign_class_filter(socket) do
    query_params = socket.assigns.query_params

    socket
    |> assign_strand_classes_from_url(query_params,
      allowed_classes_ids: socket.assigns.assigned_classes_ids
    )
    |> maybe_apply_default_class_filter()
    |> sync_filter_classes_ids()
  end

  defp maybe_apply_default_class_filter(socket) do
    if socket.assigns.selected_classes_ids == [] do
      socket
      |> assign(:selected_classes_ids, socket.assigns.assigned_classes_ids)
      |> assign(:selected_classes, socket.assigns.assigned_classes)
    else
      socket
    end
  end

  defp sync_filter_classes_ids(socket) do
    filter_classes_ids =
      case Map.get(socket.assigns.query_params, "classes_ids") do
        nil -> []
        "" -> []
        ids -> String.split(ids, ",") |> Enum.map(&String.to_integer/1)
      end

    assign(socket, :filter_classes_ids, filter_classes_ids)
  end

  defp assign_composition_filter(socket) do
    case Map.get(socket.assigns.query_params, "composition_ap_id") do
      nil ->
        socket
        |> assign(:selected_composition_ap_id, nil)
        |> assign(:filter_composition_ap_id, nil)
        |> assign(:filter_ap_ids, nil)

      raw_id ->
        case Integer.parse(raw_id) do
          {id, ""} ->
            components =
              AssessmentComposition.list_assessment_point_components(
                socket.assigns.current_scope,
                id
              )

            component_ids = Enum.map(components, & &1.component_id)

            socket
            |> assign(:selected_composition_ap_id, id)
            |> assign(:filter_composition_ap_id, raw_id)
            |> assign(:filter_ap_ids, [id | component_ids])

          _ ->
            socket
            |> assign(:selected_composition_ap_id, nil)
            |> assign(:filter_composition_ap_id, nil)
            |> assign(:filter_ap_ids, nil)
        end
    end
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
  def handle_event("change_view", %{"view" => view}, socket) do
    params = Map.put(socket.assigns.query_params, "assessment_view", view)

    socket =
      push_patch(socket,
        to: ~p"/strands/#{socket.assigns.strand}/assessment/marking?#{params}"
      )

    {:noreply, socket}
  end

  def handle_event("toggle_filter_class", %{"id" => id}, socket) do
    filter_classes_ids =
      if id in socket.assigns.filter_classes_ids do
        List.delete(socket.assigns.filter_classes_ids, id)
      else
        [id | socket.assigns.filter_classes_ids]
      end

    socket = assign(socket, :filter_classes_ids, filter_classes_ids)
    {:noreply, socket}
  end

  def handle_event("select_composition_ap", %{"id" => id}, socket) do
    filter_composition_ap_id =
      if id == socket.assigns.filter_composition_ap_id, do: nil, else: id

    socket = assign(socket, :filter_composition_ap_id, filter_composition_ap_id)
    {:noreply, socket}
  end

  def handle_event("clear_filter_selections", _, socket) do
    socket =
      socket
      |> assign(:filter_classes_ids, [])
      |> assign(:filter_composition_ap_id, nil)

    {:noreply, socket}
  end

  def handle_event("apply_assessment_filters", _, socket) do
    all_assigned? =
      MapSet.equal?(
        MapSet.new(socket.assigns.filter_classes_ids),
        MapSet.new(socket.assigns.assigned_classes_ids)
      )

    params =
      if all_assigned? or socket.assigns.filter_classes_ids == [] do
        Map.delete(socket.assigns.query_params, "classes_ids")
      else
        ids_param = Enum.join(socket.assigns.filter_classes_ids, ",")
        Map.put(socket.assigns.query_params, "classes_ids", ids_param)
      end

    params =
      case socket.assigns.filter_composition_ap_id do
        nil -> Map.delete(params, "composition_ap_id")
        id -> Map.put(params, "composition_ap_id", id)
      end

    socket =
      push_navigate(socket,
        to: ~p"/strands/#{socket.assigns.strand}/assessment/marking?#{params}"
      )

    {:noreply, socket}
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
      |> push_navigate(
        to:
          ~p"/strands/#{socket.assigns.strand}/assessment/marking?#{url_filter_params(socket.assigns.query_params)}"
      )

    {:noreply, socket}
  end
end
