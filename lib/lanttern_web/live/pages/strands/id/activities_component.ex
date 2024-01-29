defmodule LantternWeb.StrandLive.ActivitiesComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Activity

  # live components
  alias LantternWeb.LearningContext.ActivityFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div class="flex items-end justify-between mb-4">
        <h3 class="font-display font-bold text-lg">
          <%= gettext("Strand activities") %>
        </h3>
        <div class="shrink-0 flex items-center gap-6">
          <.collection_action
            :if={@activities_count > 1}
            type="button"
            phx-click={JS.exec("data-show", to: "#strand-activities-order-overlay")}
            icon_name="hero-arrows-up-down"
          >
            <%= gettext("Reorder") %>
          </.collection_action>
          <.collection_action
            type="link"
            patch={~p"/strands/#{@strand}/new_activity"}
            icon_name="hero-plus-circle"
          >
            <%= gettext("Create new activity") %>
          </.collection_action>
        </div>
      </div>
      <%= if @activities_count == 0 do %>
        <div class="p-10 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No activities for this strand yet") %></.empty_state>
        </div>
      <% else %>
        <div phx-update="stream" id="strand-activities" class="flex flex-col gap-4">
          <div
            :for={{dom_id, {activity, i}} <- @streams.activities}
            class="flex flex-col gap-6 p-6 rounded shadow-xl bg-white"
            id={dom_id}
          >
            <div class="flex items-center justify-between gap-6">
              <.link
                navigate={~p"/strands/activity/#{activity.id}"}
                class="font-display font-black text-xl"
              >
                <%= "#{i + 1}." %>
                <span class="underline"><%= activity.name %></span>
              </.link>
              <div class="shrink-0 flex gap-2">
                <.badge :for={subject <- activity.subjects}>
                  <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", subject.name) %>
                </.badge>
              </div>
            </div>
            <div class="line-clamp-6">
              <.markdown text={activity.description} class="prose-sm" />
            </div>
          </div>
        </div>
      <% end %>
      <.slide_over
        :if={@live_action == :new_activity}
        id="activity-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}?tab=activities")}
      >
        <:title><%= gettext("New activity") %></:title>
        <.live_component
          module={ActivityFormComponent}
          id={:new}
          activity={%Activity{strand_id: @strand.id, subjects: []}}
          strand_id={@strand.id}
          action={:new}
          navigate={fn activity -> ~p"/strands/activity/#{activity}" end}
          notify_parent
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#activity-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="activity-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.reorder_overlay
        :if={@activities_count > 1}
        sortable_activities={@sortable_activities}
        activities_count={@activities_count}
        myself={@myself}
      />
    </div>
    """
  end

  attr :sortable_activities, :list, required: true
  attr :activities_count, :integer, required: true
  attr :myself, :any, required: true

  def reorder_overlay(assigns) do
    ~H"""
    <.slide_over id="strand-activities-order-overlay">
      <:title><%= gettext("Strand Activities Order") %></:title>
      <ol>
        <li
          :for={{activity, i} <- @sortable_activities}
          id={"sortable-activity-#{activity.id}"}
          class="flex items-center gap-4 mb-4"
        >
          <div class="flex-1 flex items-start p-4 rounded bg-white shadow-lg">
            <%= "#{i + 1}. #{activity.name}" %>
          </div>
          <div class="shrink-0 flex flex-col gap-2">
            <.icon_button
              type="button"
              sr_text={gettext("Move activity up")}
              name="hero-chevron-up-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i == 0}
              phx-click={JS.push("set_activity_position", value: %{from: i, to: i - 1})}
              phx-target={@myself}
            />
            <.icon_button
              type="button"
              sr_text={gettext("Move activity down")}
              name="hero-chevron-down-mini"
              theme="ghost"
              rounded
              size="sm"
              disabled={i + 1 == @activities_count}
              phx-click={JS.push("set_activity_position", value: %{from: i, to: i + 1})}
              phx-target={@myself}
            />
          </div>
        </li>
      </ol>
      <:actions>
        <.button
          type="button"
          theme="ghost"
          phx-click={JS.exec("data-cancel", to: "#strand-activities-order-overlay")}
        >
          <%= gettext("Cancel") %>
        </.button>
        <.button type="button" phx-click="save_order" phx-target={@myself}>
          <%= gettext("Save") %>
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> stream_configure(
       :activities,
       dom_id: fn {activity, _i} -> "activity-#{activity.id}" end
     )}
  end

  @impl true
  def update(assigns, socket) do
    activities =
      LearningContext.list_activities(strands_ids: [assigns.strand.id], preloads: :subjects)
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:activities_count, length(activities))
     |> stream(:activities, activities)
     |> assign(:sortable_activities, activities)}
  end

  # event handlers

  @impl true
  def handle_event("set_activity_position", %{"from" => i, "to" => j}, socket) do
    sortable_activities =
      socket.assigns.sortable_activities
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_activities, sortable_activities)}
  end

  def handle_event("save_order", _, socket) do
    activities_ids =
      socket.assigns.sortable_activities
      |> Enum.map(fn {ap, _i} -> ap.id end)

    case LearningContext.update_strand_activities_positions(
           socket.assigns.strand.id,
           activities_ids
         ) do
      {:ok, _activities} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=activities")}

      {:error, _} ->
        {:noreply, socket}
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
