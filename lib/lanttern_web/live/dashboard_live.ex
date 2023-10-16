defmodule LantternWeb.DashboardLive do
  @moduledoc """
  ### PubSub subscription topics

  - "dashboard:profile_id" on `handle_params`

  Expected broadcasted messages in `handle_info/2` documentation.
  """

  use LantternWeb, :live_view
  alias Phoenix.PubSub
  alias Lanttern.Explorer

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Dashboard 🚧</.page_title_with_menu>
      <div class="mt-40">
        <.link
          navigate={~p"/assessment_points"}
          class="flex items-center font-display font-black text-lg text-ltrn-subtle"
        >
          Assessment points <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          navigate={~p"/curriculum"}
          class="flex items-center mt-10 font-display font-black text-lg text-ltrn-subtle"
        >
          Curriculum <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
      </div>
      <div class="flex items-center justify-between pb-6 mt-40 border-b border-ltrn-hairline">
        <h3 class="font-display font-bold text-2xl">
          <.link
            navigate={~p"/assessment_points"}
            class="inline-block underline hover:text-ltrn-subtle"
          >
            Assessment points
          </.link>
          filter views
        </h3>
        <button
          type="button"
          class="shrink-0 flex items-center gap-2 font-display text-base underline hover:text-ltrn-primary"
          phx-click="add_filter_view"
        >
          Create new view <.icon name="hero-plus-circle" class="w-6 h-6 text-ltrn-primary" />
        </button>
      </div>
      <%= if @filter_view_count > 0 do %>
        <div
          id="assessment-points-filter-views"
          class="grid grid-cols-3 gap-10 mt-6"
          phx-update="stream"
        >
          <.filter_view_card
            :for={{dom_id, filter_view} <- @streams.assessment_points_filter_views}
            id={dom_id}
            filter_view={filter_view}
          />
        </div>
      <% else %>
        <.empty_state>You don't have any filter view yet</.empty_state>
      <% end %>
    </div>
    <.live_component
      module={LantternWeb.AssessmentPointsFilterViewOverlayComponent}
      id="create-assessment-points-filter-view-overlay"
      current_user={@current_user}
      show={@show_filter_view_overlay}
      topic={"dashboard:#{@current_user.current_profile_id}"}
      on_cancel={JS.push("cancel_filter_view")}
      filter_view_id={@current_filter_view_id}
    />
    """
  end

  # view components

  attr :id, :string, required: true
  attr :filter_view, :map, required: true

  def filter_view_card(%{filter_view: filter_view} = assigns) do
    assigns =
      assigns
      |> assign(
        :path_params,
        %{
          classes_ids: Map.get(filter_view, :classes) |> Enum.map(& &1.id),
          subjects_ids: Map.get(filter_view, :subjects) |> Enum.map(& &1.id)
        }
      )

    ~H"""
    <.card_base id={@id}>
      <:upper_block>
        <div class="flex gap-2">
          <.link
            navigate={~p"/assessment_points?#{@path_params}"}
            class="flex-1 font-display font-black text-2xl line-clamp-3 underline hover:text-ltrn-subtle"
            title={@filter_view.name}
          >
            <%= @filter_view.name %>
          </.link>
          <.menu_button id={@id}>
            <:menu_items>
              <.menu_button_item
                id={"edit-filter-view-#{@id}"}
                phx-click="edit_filter_view"
                phx-value-id={@filter_view.id}
              >
                Edit
              </.menu_button_item>
              <.menu_button_item
                id={"remove-filter-view-#{@id}"}
                class="text-red-500"
                phx-click="delete_filter_view"
                phx-value-id={@filter_view.id}
                data-confirm="Are you sure?"
              >
                Delete
              </.menu_button_item>
            </:menu_items>
          </.menu_button>
        </div>
      </:upper_block>
      <:lower_block>
        <div class="flex flex-wrap gap-2">
          <.badge :for={class <- @filter_view.classes}><%= class.name %></.badge>
          <.badge :for={subject <- @filter_view.subjects}><%= subject.name %></.badge>
        </div>
      </:lower_block>
    </.card_base>
    """
  end

  attr :id, :string, required: true
  slot :upper_block
  slot :lower_block

  def card_base(assigns) do
    ~H"""
    <div
      id={@id}
      class="flex flex-col justify-between min-h-[15rem] p-6 rounded shadow-xl"
      phx-mounted={highlight_mounted(to_classes: "bg-white")}
      phx-remove={highlight_remove(to_classes: "bg-white")}
    >
      <%= render_slot(@upper_block) %>
      <div class="mt-10">
        <%= render_slot(@lower_block) %>
      </div>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    profile_id = socket.assigns.current_user.current_profile_id

    if connected?(socket) do
      PubSub.subscribe(
        Lanttern.PubSub,
        "dashboard:#{profile_id}"
      )
    end

    filter_views = list_filter_views(profile_id)
    filter_view_count = length(filter_views)

    socket =
      socket
      |> stream(:assessment_points_filter_views, filter_views)
      |> assign(:filter_view_count, filter_view_count)
      |> assign(:current_filter_view_id, nil)
      |> assign(:show_filter_view_overlay, false)

    {:ok, socket}
  end

  # event handlers

  def handle_event("add_filter_view", _params, socket) do
    {:noreply, assign(socket, :show_filter_view_overlay, true)}
  end

  def handle_event("edit_filter_view", %{"id" => filter_view_id} = _params, socket) do
    socket =
      socket
      |> assign(:current_filter_view_id, String.to_integer(filter_view_id))
      |> assign(:show_filter_view_overlay, true)

    {:noreply, socket}
  end

  def handle_event("delete_filter_view", %{"id" => filter_view_id} = _params, socket) do
    assessment_points_filter_view = Explorer.get_assessment_points_filter_view!(filter_view_id)

    case Explorer.delete_assessment_points_filter_view(assessment_points_filter_view) do
      {:ok, _} ->
        socket =
          socket
          |> stream_delete(:assessment_points_filter_views, assessment_points_filter_view)
          |> update(:filter_view_count, fn count -> count - 1 end)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply, put_flash(socket, :error, "Something is not right")}
    end
  end

  def handle_event("cancel_filter_view", _params, socket) do
    socket =
      socket
      |> assign(:show_filter_view_overlay, false)
      |> assign(:current_filter_view_id, false)

    {:noreply, socket}
  end

  # info handlers

  @doc """
  Handles sent or broadcasted messages from children Live Components.

  ## Clauses

  #### Assessment points filter view create success

  Broadcasted to `"dashboard:profile_id"` from `LantternWeb.AssessmentPointsFilterViewOverlayComponent`.

      handle_info({:assessment_points_filter_view_created, assessment_points_filter_view}, socket)

  #### Assessment points filter view update success

  Broadcasted to `"dashboard:profile_id"` from `LantternWeb.AssessmentPointsFilterViewOverlayComponent`.

      handle_info({:assessment_points_filter_view_updated, assessment_points_filter_view}, socket)

  """

  def handle_info(
        {:assessment_points_filter_view_created, _assessment_points_filter_view},
        socket
      ) do
    socket =
      socket
      |> stream(
        :assessment_points_filter_views,
        list_filter_views(socket.assigns.current_user.current_profile_id),
        reset: true
      )
      |> put_flash(:info, "Assessment points filter view created.")
      |> update(:filter_view_count, fn count -> count + 1 end)
      |> assign(:show_filter_view_overlay, false)

    {:noreply, socket}
  end

  def handle_info(
        {:assessment_points_filter_view_updated, assessment_points_filter_view},
        socket
      ) do
    socket =
      socket
      |> stream_insert(
        :assessment_points_filter_views,
        assessment_points_filter_view
      )
      |> put_flash(:info, "Assessment points filter view updated.")
      |> assign(:current_filter_view_id, false)
      |> assign(:show_filter_view_overlay, false)

    {:noreply, socket}
  end

  # helpers

  defp list_filter_views(profile_id) do
    Explorer.list_assessment_points_filter_views(
      profile_id: profile_id,
      preloads: [:subjects, :classes]
    )
  end
end
