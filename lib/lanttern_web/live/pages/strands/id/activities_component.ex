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
          Strand activities
        </h3>
        <.collection_action
          type="link"
          patch={~p"/strands/#{@strand}/new_activity"}
          icon_name="hero-plus-circle"
        >
          Create new activity
        </.collection_action>
      </div>
      <%= if @activities_count == 0 do %>
        <div class="p-10 rounded shadow-xl bg-white">
          <.empty_state>No activities for this strand yet</.empty_state>
        </div>
      <% else %>
        <div phx-update="stream" id="strand-activities" class="flex flex-col gap-4">
          <div
            :for={{dom_id, {activity, i}} <- @streams.activities}
            class="flex flex-col gap-6 p-6 rounded shadow-xl bg-white"
            id={dom_id}
          >
            <.link
              navigate={~p"/strands/activity/#{activity.id}"}
              class="font-display font-black text-xl"
            >
              <%= "#{i + 1}." %>
              <span class="underline"><%= activity.name %></span>
            </.link>
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
        <:title>New activity</:title>
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
            Cancel
          </.button>
          <.button type="submit" form="activity-form">
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
     |> stream_configure(
       :activities,
       dom_id: fn {activity, _i} -> "activity-#{activity.id}" end
     )}
  end

  @impl true
  def update(assigns, socket) do
    activities =
      LearningContext.list_activities(strands_ids: [assigns.strand.id])
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:activities_count, length(activities))
     |> stream(:activities, activities)}
  end
end
