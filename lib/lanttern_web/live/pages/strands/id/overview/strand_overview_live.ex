defmodule LantternWeb.StrandOverviewLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula
  alias Lanttern.LearningContext
  alias Lanttern.Reporting

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [reorder: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.LearningContext.StrandFormComponent
  alias LantternWeb.LearningContext.ToggleStrandStarActionComponent
  import LantternWeb.FiltersHelpers, only: [assign_strand_classes_filter: 1]
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]
  import LantternWeb.ReportingComponents, only: [report_card_card: 1]

  @live_action_select_classes_overlay_title %{
    rubrics: gettext("Select classes to view students differentiation rubrics"),
    assessment: gettext("Select classes to view assessments info"),
    notes: gettext("Select classes to view students notes")
  }

  @live_action_select_classes_overlay_navigate_path %{
    rubrics: "rubrics",
    assessment: "assessment",
    notes: "notes"
  }

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_strand(params)
      |> assign_strand_classes_filter()
      |> stream_curriculum_items()
      |> stream_report_cards()

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
        |> assign(
          :cover_image_url,
          object_url_to_render_url(strand.cover_image_url, width: 1280, height: 640)
        )
    end
  end

  defp stream_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_strand_curriculum_items(
        socket.assigns.strand.id,
        preloads: :curriculum_component
      )

    socket
    |> stream(:curriculum_items, curriculum_items)
    |> assign(:goals_ids, Enum.map(curriculum_items, & &1.assessment_point_id))
  end

  defp stream_report_cards(socket) do
    report_cards =
      Reporting.list_report_cards(
        preloads: :school_cycle,
        strands_ids: [socket.assigns.strand.id],
        school_id: socket.assigns.current_user.current_profile.school_id
      )

    socket
    |> stream(:report_cards, report_cards)
    |> assign(:has_report_cards, report_cards != [])
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_is_editing(params)
      |> assign_goal(params)
      |> assign_select_classes_overlay_title()
      |> assign_select_classes_overlay_navigate()

    {:noreply, socket}
  end

  defp assign_is_editing(socket, %{"is_editing" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  defp assign_goal(socket, %{"goal" => "new"}) do
    goal =
      %AssessmentPoint{
        strand_id: socket.assigns.strand.id,
        datetime: DateTime.utc_now()
      }

    assign(socket, :goal, goal)
  end

  defp assign_goal(socket, %{"goal" => binary_id}) do
    with {id, _} <- Integer.parse(binary_id), true <- id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(id)
      assign(socket, :goal, goal)
    else
      _ -> assign(socket, :goal, nil)
    end
  end

  defp assign_goal(socket, _), do: assign(socket, :goal, nil)

  defp assign_select_classes_overlay_title(socket) do
    title =
      Map.get(
        @live_action_select_classes_overlay_title,
        socket.assigns.live_action
      )

    assign(socket, :select_classes_overlay_title, title)
  end

  defp assign_select_classes_overlay_navigate(socket) do
    path_final =
      Map.get(
        @live_action_select_classes_overlay_navigate_path,
        socket.assigns.live_action
      )

    navigate = "/strands/#{socket.assigns.strand.id}/#{path_final}"

    assign(socket, :select_classes_overlay_navigate, navigate)
  end

  # event handlers

  @impl true
  def handle_event("delete_strand", _params, socket) do
    case LearningContext.delete_strand(socket.assigns.strand) do
      {:ok, _strand} ->
        socket =
          socket
          |> put_flash(:info, gettext("Strand deleted"))
          |> push_navigate(to: ~p"/strands")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(
            :error,
            gettext(
              "Strand has linked moments and/or assessment points (goals). Deleting it would cause some data loss."
            )
          )

        {:noreply, socket}
    end
  end

  # view Sortable hook for payload info
  def handle_event("sortable_update", payload, socket) do
    %{
      "oldIndex" => old_index,
      "newIndex" => new_index
    } = payload

    goals_ids = reorder(socket.assigns.goals_ids, old_index, new_index)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    Assessments.update_assessment_points_positions(goals_ids)

    {:noreply, assign(socket, :goals_ids, goals_ids)}
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, assign(socket, :strand, strand)}
  end

  def handle_info({AssessmentPointFormOverlayComponent, {action, _assessment_point}}, socket)
      when action in [:created, :updated, :deleted, :deleted_with_entries] do
    flash_message =
      case action do
        :created ->
          gettext("Assessment point created successfully")

        :updated ->
          gettext("Assessment point updated successfully")

        :deleted ->
          gettext("Assessment point deleted successfully")

        :deleted_with_entries ->
          gettext("Assessment point and entries deleted successfully")
      end

    socket =
      socket
      |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/overview")
      |> put_flash(:info, flash_message)

    {:noreply, socket}
  end
end
