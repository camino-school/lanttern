defmodule LantternWeb.StrandLive.AboutComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <.markdown text={@strand.description} />
      <div class="flex items-end justify-between gap-6">
        <h3 class="mt-16 font-display font-black text-3xl">Goals</h3>
        <div class="shrink-0 flex items-center gap-6">
          <.collection_action
            :if={@has_goal_position_change}
            type="button"
            icon_name="hero-check-circle"
            phx-click="save_order"
            phx-target={@myself}
            class="font-bold"
          >
            Save new order
          </.collection_action>
          <.collection_action
            type="button"
            icon_name="hero-plus-circle"
            phx-click="new_goal"
            phx-target={@myself}
          >
            Add strand goal
          </.collection_action>
        </div>
      </div>
      <p class="mt-4">
        Under the hood, goals in Lanttern are defined by assessment points linked directly to the strand — when adding goals, we are adding assessment points which, in turn, hold the curriculum items we'll want to assess along the strand course.
      </p>
      <div :for={{curriculum_item, i} <- @curriculum_items} class="mt-6">
        <div class="flex-1 flex items-stretch gap-6 p-6 rounded bg-white shadow-lg">
          <div class="flex-1">
            <div class="flex items-center gap-4">
              <p class="font-display font-bold text-sm">
                <%= curriculum_item.curriculum_component.name %>
              </p>
              <.button
                type="button"
                theme="ghost"
                phx-click={JS.push("edit_goal", value: %{id: curriculum_item.assessment_point_id})}
                phx-target={@myself}
              >
                Edit
              </.button>
            </div>
            <p class="mt-4"><%= curriculum_item.name %></p>
          </div>
          <div class="shrink-0 flex flex-col justify-center gap-2">
            <.icon_button
              type="button"
              sr_text="Move curriculum item up"
              name="hero-chevron-up-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i == 0}
              phx-click={JS.push("swap_goal_position", value: %{from: i, to: i - 1})}
              phx-target={@myself}
            />
            <.icon_button
              type="button"
              sr_text="Move curriculum item down"
              name="hero-chevron-down-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i + 1 == length(@curriculum_items)}
              phx-click={JS.push("swap_goal_position", value: %{from: i, to: i + 1})}
              phx-target={@myself}
            />
          </div>
        </div>
      </div>
      <.slide_over
        :if={@live_action in [:new_goal, :edit_goal]}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}?tab=about")}
      >
        <:title>Strand Goal</:title>
        <.live_component
          module={AssessmentPointFormComponent}
          id={Map.get(@assessment_point, :id) || :new}
          strand_id={@strand.id}
          notify_component={@myself}
          assessment_point={@assessment_point}
          navigate={~p"/strands/#{@strand}?tab=about"}
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
              data-confirm="Are you sure?"
              class="mt-4 font-display font-bold underline"
            >
              Understood. Delete anyway
            </button>
          </div>
          <button
            type="button"
            phx-click="dismiss_assessment_point_error"
            phx-target={@myself}
            class="shrink-0"
          >
            <span class="sr-only">dismiss</span>
            <.icon name="hero-x-mark" />
          </button>
        </div>
        <:actions_left :if={@assessment_point.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_assessment_point"
            phx-target={@myself}
            data-confirm="Are you sure?"
          >
            Delete
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#assessment-point-form-overlay")}
          >
            Cancel
          </.button>
          <.button type="submit" form="assessment-point-form" phx-disable-with="Saving...">
            Save
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:assessment_point, %AssessmentPoint{datetime: DateTime.utc_now()})
     |> assign(:delete_assessment_point_error, nil)
     |> assign(:has_goal_position_change, false)}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :curriculum_items,
       Curricula.list_strand_curriculum_items(strand.id, preloads: :curriculum_component)
       |> Enum.with_index()
     )}
  end

  # event handlers

  @impl true
  def handle_event("new_goal", _params, socket) do
    {:noreply,
     socket
     |> assign(:assessment_point, %AssessmentPoint{datetime: DateTime.utc_now()})
     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/goal/new")}
  end

  def handle_event("edit_goal", %{"id" => assessment_point_id}, socket) do
    assessment_point = Assessments.get_assessment_point(assessment_point_id)

    {:noreply,
     socket
     |> assign(:assessment_point, assessment_point)
     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/goal/edit")}
  end

  def handle_event("delete_assessment_point", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

      {:error, _changeset} ->
        # we may have more error types, but for now we are handling only this one
        message =
          "This goal already have some entries. Deleting it will cause data loss."

        {:noreply, socket |> assign(:delete_assessment_point_error, message)}
    end
  end

  def handle_event("delete_assessment_point_and_entries", _, socket) do
    case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_assessment_point_error", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_assessment_point_error, nil)}
  end

  def handle_event("swap_goal_position", %{"from" => i, "to" => j}, socket) do
    curriculum_items =
      socket.assigns.curriculum_items
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply,
     socket
     |> assign(:curriculum_items, curriculum_items)
     |> assign(:has_goal_position_change, true)}
  end

  def handle_event("save_order", _, socket) do
    assessment_points_ids =
      socket.assigns.curriculum_items
      |> Enum.map(fn {ci, _i} -> ci.assessment_point_id end)

    case Assessments.update_assessment_points_positions(assessment_points_ids) do
      {:ok, _assessment_points} ->
        {:noreply, assign(socket, :has_goal_position_change, false)}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # helpers

  # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  defp swap(a, i1, i2) do
    e1 = Enum.at(a, i1)
    e2 = Enum.at(a, i2)

    a
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end
end
