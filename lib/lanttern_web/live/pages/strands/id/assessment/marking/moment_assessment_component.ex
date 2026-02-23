defmodule LantternWeb.MarkingLive.MomentAssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Filters

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2]

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Assessments.AssessmentsGridComponent
  import LantternWeb.AssessmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-center gap-4 px-4 mb-4">
        <div class="relative">
          <.button
            type="button"
            id="moment-dropdown-button"
            size="sm"
            icon_name="hero-bars-3-micro"
          >
            {@moment.name}
          </.button>
          <.dropdown_menu
            id="moment-dropdown"
            button_id="moment-dropdown-button"
            z_index="30"
          >
            <:item
              :for={moment <- @moments}
              type="link"
              navigate={~p"/strands/#{@strand}/assessment/marking/moment/#{moment}"}
              text={moment.name}
              is_active={moment.id == @moment.id}
            />
            <:item
              type="link"
              navigate={~p"/strands/#{@strand}/assessment/marking"}
              text={gettext("Strand goals")}
            />
          </.dropdown_menu>
        </div>

        <.button
          type="button"
          phx-click={JS.exec("data-show", to: "#strand-classes-filter-modal")}
          icon_name="hero-users-micro"
          size="sm"
        >
          {@selected_classes_text}
        </.button>

        <.assessment_view_dropdow
          current_assessment_view={@current_assessment_view}
          on_change={fn view -> JS.push("change_view", value: %{"view" => view}, target: @myself) end}
        />
      </div>
      <.responsive_container :if={@selected_classes_ids == []} class="py-10">
        <p class="flex items-center gap-2">
          <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
          {gettext("Select a class above to view full assessments grid")}
        </p>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:moment_assessment_grid}
        current_user={@current_user}
        current_assessment_view={@current_assessment_view}
        moment_id={@moment.id}
        classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/assessment/marking/moment/#{@moment}"}
        notify_component={@myself}
      />
      <.live_component
        :if={@assessment_point}
        module={AssessmentPointFormOverlayComponent}
        id={"moment-#{@moment.id}-assessment-point-form-overlay"}
        notify_component={@myself}
        assessment_point={@assessment_point}
        title={gettext("Assessment Point")}
        on_cancel={JS.patch(~p"/strands/#{@strand}/assessment/marking/moment/#{@moment}")}
        curriculum_from_strand_id={@moment.strand_id}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )
      |> assign(:delete_assessment_point_error, nil)
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
      push_navigate: [
        to:
          ~p"/strands/#{socket.assigns.strand}/assessment/marking/moment/#{socket.assigns.moment}"
      ]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_assessment_point()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:assessment_view, :assessment_group_by])
    |> assign_sortable_assessment_points()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_assessment_point(
         %{assigns: %{params: %{"new_assessment_point" => "true"}}} = socket
       ) do
    assessment_point =
      %AssessmentPoint{
        moment_id: socket.assigns.moment.id,
        datetime: DateTime.utc_now()
      }

    socket
    |> assign(:assessment_point, assessment_point)
  end

  defp assign_assessment_point(%{assigns: %{params: %{"edit_assessment_point" => id}}} = socket) do
    with true <- id in socket.assigns.assessment_points_ids,
         %AssessmentPoint{} = assessment_point <- Assessments.get_assessment_point(id) do
      assign(socket, :assessment_point, assessment_point)
    else
      _ -> assign(socket, :assessment_point, nil)
    end
  end

  defp assign_assessment_point(socket), do: assign(socket, :assessment_point, nil)

  defp assign_sortable_assessment_points(socket) do
    assessment_points =
      Assessments.list_assessment_points(
        moments_ids: [socket.assigns.moment.id],
        preloads: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )

    socket
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
    |> assign(:assessment_points_length, length(assessment_points))
    |> assign(:assessment_points_ids, Enum.map(assessment_points, &"#{&1.id}"))
  end

  # event handlers

  @impl true
  def handle_event(
        "change_view",
        %{"view" => view},
        %{assigns: %{current_assessment_view: current_assessment_view}} = socket
      )
      when view == current_assessment_view,
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
          |> push_navigate(
            to:
              ~p"/strands/#{socket.assigns.strand}/assessment/marking/moment/#{socket.assigns.moment}"
          )

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("swap_assessment_point_position", %{"from" => i, "to" => j}, socket) do
    sortable_assessment_points =
      socket.assigns.sortable_assessment_points
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_assessment_points, sortable_assessment_points)}
  end

  def handle_event("save_order", _, socket) do
    assessment_points_ids =
      socket.assigns.sortable_assessment_points
      |> Enum.map(fn {ap, _i} -> ap.id end)

    case Assessments.update_assessment_points_positions(assessment_points_ids) do
      {:ok, _assessment_points} ->
        {:noreply,
         socket
         |> push_navigate(
           to:
             ~p"/strands/#{socket.assigns.strand}/assessment/marking/moment/#{socket.assigns.moment}"
         )}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
