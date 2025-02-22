defmodule LantternWeb.MomentLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Filters

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, assign_strand_classes_filter: 1]

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentsGridComponent
  alias LantternWeb.Assessments.AssessmentPointFormComponent
  import LantternWeb.AssessmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-4">
          <.action
            type="button"
            phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
            icon_name="hero-chevron-down-mini"
          >
            <%= format_action_items_text(@selected_classes, gettext("No class selected")) %>
          </.action>
          <.assessment_view_dropdow
            current_assessment_view={@current_assessment_view}
            on_change={
              fn view -> JS.push("change_view", value: %{"view" => view}, target: @myself) end
            }
          />
        </div>
        <div class="flex gap-4">
          <.action
            :if={@assessment_points_length > 1}
            type="link"
            patch={~p"/strands/moment/#{@moment}/assessment?is_reordering=true"}
            icon_name="hero-arrows-up-down-mini"
          >
            <%= gettext("Reorder") %>
          </.action>
          <.action
            type="link"
            patch={~p"/strands/moment/#{@moment}/assessment?new_assessment_point=true"}
            icon_name="hero-plus-circle-mini"
          >
            <%= gettext("New assessment point") %>
          </.action>
        </div>
      </.action_bar>
      <.responsive_container :if={@selected_classes == []} class="py-10">
        <p class="flex items-center gap-2">
          <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
          <%= gettext("Select a class above to view full assessments grid") %>
        </p>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:moment_assessment_grid}
        current_user={@current_user}
        current_assessment_view={@current_assessment_view}
        moment_id={@moment.id}
        classes_ids={@selected_classes_ids}
        navigate={~p"/strands/moment/#{@moment}/assessment"}
        notify_component={@myself}
      />
      <.slide_over
        :if={@assessment_point}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}/assessment")}
      >
        <:title><%= gettext("Assessment Point") %></:title>
        <.delete_assessment_point_error
          :if={@delete_assessment_point_error}
          error={@delete_assessment_point_error}
          on_confirm_delete={JS.push("delete_assessment_point_and_entries", target: @myself)}
          on_dismiss={JS.push("dismiss_assessment_point_error", target: @myself)}
          class="mb-6"
        />
        <.live_component
          module={AssessmentPointFormComponent}
          id={Map.get(@assessment_point, :id) || :new}
          curriculum_from_strand_id={@moment.strand_id}
          notify_component={@myself}
          assessment_point={@assessment_point}
          navigate={~p"/strands/moment/#{@moment}/assessment"}
        />
        <.delete_assessment_point_error
          :if={@delete_assessment_point_error}
          error={@delete_assessment_point_error}
          on_confirm_delete={JS.push("delete_assessment_point_and_entries", target: @myself)}
          on_dismiss={JS.push("dismiss_assessment_point_error", target: @myself)}
        />
        <:actions_left :if={not is_nil(@assessment_point.id)}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_assessment_point"
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
            phx-click={JS.exec("data-cancel", to: "#assessment-point-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="assessment-point-form" phx-disable-with="Saving...">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        profile_filter_opts={[strand_id: @moment.strand_id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={~p"/strands/moment/#{@moment}/assessment"}
      />
      <.slide_over
        :if={Map.get(@params, "is_reordering") == "true"}
        show
        id="moment-assessment-points-order-overlay"
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}/assessment")}
      >
        <:title><%= gettext("Assessment Points Order") %></:title>
        <.sortable_card
          :for={{assessment_point, i} <- @sortable_assessment_points}
          class="mb-4"
          id={"sortable-assessment-point-#{assessment_point.id}"}
          is_move_up_disabled={i == 0}
          on_move_up={
            JS.push("swap_assessment_point_position", value: %{from: i, to: i - 1}, target: @myself)
          }
          is_move_down_disabled={i + 1 == @assessment_points_length}
          on_move_down={
            JS.push("swap_assessment_point_position", value: %{from: i, to: i - 1}, target: @myself)
          }
        >
          <p><%= assessment_point.name %></p>
        </.sortable_card>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-assessment-points-order-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="button" phx-click="save_order" phx-target={@myself}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :error, :any, required: true
  attr :on_confirm_delete, JS, required: true
  attr :on_dismiss, JS, required: true

  defp delete_assessment_point_error(assigns) do
    ~H"""
    <div class={["flex items-start gap-4 p-4 rounded-sm text-sm text-rose-600 bg-rose-100", @class]}>
      <div>
        <p><%= @error %></p>
        <button
          type="button"
          phx-click={@on_confirm_delete}
          data-confirm={gettext("Are you sure?")}
          class="mt-4 font-display font-bold underline"
        >
          <%= gettext("Understood. Delete anyway") %>
        </button>
      </div>
      <button type="button" phx-click={@on_dismiss} class="shrink-0">
        <span class="sr-only"><%= gettext("dismiss") %></span>
        <.icon name="hero-x-mark" />
      </button>
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
    |> assign_strand_classes_filter()
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

  defp assign_assessment_point(
         %{assigns: %{params: %{"edit_assessment_point" => binary_id}}} = socket
       ) do
    with {id, _} <- Integer.parse(binary_id),
         true <- id in socket.assigns.assessment_points_ids,
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
    |> assign(:assessment_points_ids, Enum.map(assessment_points, & &1.id))
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
          |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

  def handle_event("delete_assessment_point", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/assessment")}

      {:error, _changeset} ->
        # we may have more error types, but for now we are handling only this one
        message =
          gettext(
            "This assessment point already have some entries. Deleting it will cause data loss."
          )

        {:noreply, socket |> assign(:delete_assessment_point_error, message)}
    end
  end

  def handle_event("delete_assessment_point_and_entries", _, socket) do
    case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_assessment_point_error", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_assessment_point_error, nil)}
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
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
