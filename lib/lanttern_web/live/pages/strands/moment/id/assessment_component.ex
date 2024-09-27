defmodule LantternWeb.MomentLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3]
  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentsGridComponent
  alias LantternWeb.Assessments.AssessmentPointFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pt-10 pb-20">
      <.responsive_container>
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <%= gettext("Assessing") %>
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= gettext("Select a class") %>
              </button>
              <%= gettext("to assess students") %>
            </p>
          <% end %>
          <div class="shrink-0 flex items-center gap-6">
            <.collection_action
              :if={@assessment_points_count > 1}
              type="link"
              patch={~p"/strands/moment/#{@moment}?tab=assessment&action=reorder"}
              icon_name="hero-arrows-up-down"
            >
              <%= gettext("Reorder") %>
            </.collection_action>
            <.collection_action
              type="link"
              patch={~p"/strands/moment/#{@moment}?tab=assessment&action=new"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Create assessment point") %>
            </.collection_action>
          </div>
        </div>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:moment_assessment_grid}
        current_user={@current_user}
        moment_id={@moment.id}
        classes_ids={@selected_classes_ids}
        class="mt-6"
        navigate={~p"/strands/moment/#{@moment}?tab=assessment"}
        notify_component={@myself}
      />
      <.slide_over
        :if={@assessment_point}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}?tab=assessment")}
      >
        <:title><%= gettext("Assessment Point") %></:title>
        <.live_component
          module={AssessmentPointFormComponent}
          id={Map.get(@assessment_point, :id) || :new}
          curriculum_from_strand_id={@moment.strand_id}
          notify_component={@myself}
          assessment_point={@assessment_point}
          navigate={~p"/strands/moment/#{@moment}?tab=assessment"}
        />
        <div
          :if={@delete_assessment_point_error}
          class="flex items-start gap-4 p-4 rounded-sm text-sm text-rose-600 bg-rose-100"
        >
          <div>
            <p><%= @delete_assessment_point_error %></p>
            <button
              type="button"
              phx-click="delete_assessment_point_and_entries"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
              class="mt-4 font-display font-bold underline"
            >
              <%= gettext("Understood. Delete anyway") %>
            </button>
          </div>
          <button
            type="button"
            phx-click="dismiss_assessment_point_error"
            phx-target={@myself}
            class="shrink-0"
          >
            <span class="sr-only"><%= gettext("dismiss") %></span>
            <.icon name="hero-x-mark" />
          </button>
        </div>
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
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        filter_type={:classes}
        filter_opts={[strand_id: @moment.strand_id]}
        navigate={~p"/strands/moment/#{@moment}?tab=assessment"}
      />
      <.slide_over
        :if={@is_reordering}
        show
        id="moment-assessment-points-order-overlay"
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}?tab=assessment")}
      >
        <:title><%= gettext("Assessment Points Order") %></:title>
        <ol>
          <li
            :for={{assessment_point, i} <- @sortable_assessment_points}
            id={"sortable-assessment-point-#{assessment_point.id}"}
            class="flex items-center gap-4 mb-4"
          >
            <div class="flex-1 flex items-start p-4 rounded bg-white shadow-lg">
              <%= "#{i + 1}. #{assessment_point.name}" %>
            </div>
            <div class="shrink-0 flex flex-col gap-2">
              <.icon_button
                type="button"
                sr_text={gettext("Move assessment point up")}
                name="hero-chevron-up-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i == 0}
                phx-click={JS.push("assessment_point_position", value: %{from: i, to: i - 1})}
                phx-target={@myself}
              />
              <.icon_button
                type="button"
                sr_text={gettext("Move assessment point down")}
                name="hero-chevron-down-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i + 1 == @assessment_points_count}
                phx-click={JS.push("assessment_point_position", value: %{from: i, to: i + 1})}
                phx-target={@myself}
              />
            </div>
          </li>
        </ol>
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

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )
      |> assign(:assessment_point, nil)
      |> assign(:delete_assessment_point_error, nil)
      |> assign(:is_reordering, false)
      |> assign(:initial_update, true)

    {:ok, socket}
  end

  @impl true
  def update(assigns, %{assigns: %{initial_update: true}} = socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters([:classes],
        strand_id: assigns.moment.strand_id
      )
      |> assign_sortable_assessment_points()
      |> assign(:initial_update, false)
      |> handle_action()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> handle_action()

    {:ok, socket}
  end

  defp handle_action(socket) do
    socket
    |> assign_assessment_point(socket.assigns.params)
    |> assign_is_reordering(socket.assigns.params)
  end

  defp assign_assessment_point(socket, %{"action" => "new"}) do
    socket
    |> assign(:assessment_point, %AssessmentPoint{
      moment_id: socket.assigns.moment.id,
      datetime: DateTime.utc_now()
    })
  end

  defp assign_assessment_point(socket, %{"action" => "edit", "assessment_point_id" => id}) do
    assessment_point =
      socket.assigns.sortable_assessment_points
      |> Enum.map(fn {ap, _i} -> ap end)
      |> Enum.find(&("#{&1.id}" == id))

    assign(socket, :assessment_point, assessment_point)
  end

  defp assign_assessment_point(socket, _params),
    do: assign(socket, :assessment_point, nil)

  defp assign_is_reordering(socket, %{"action" => "reorder"}),
    do: assign(socket, :is_reordering, true)

  defp assign_is_reordering(socket, _params),
    do: assign(socket, :is_reordering, false)

  defp assign_sortable_assessment_points(socket) do
    assessment_points =
      Assessments.list_assessment_points(
        moments_ids: [socket.assigns.moment.id],
        preloads: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )

    socket
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
    |> assign(:assessment_points_count, length(assessment_points))
  end

  # event handlers

  @impl true
  def handle_event("delete_assessment_point", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

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
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_assessment_point_error", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_assessment_point_error, nil)}
  end

  def handle_event("assessment_point_position", %{"from" => i, "to" => j}, socket) do
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
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
