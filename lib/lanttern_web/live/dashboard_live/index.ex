defmodule LantternWeb.DashboardLive.Index do
  @moduledoc """
  ### PubSub subscription topics

  - "dashboard:profile_id" on `handle_params`

  Expected broadcasted messages in `handle_info/2` documentation.
  """

  use LantternWeb, :live_view
  alias Phoenix.PubSub
  alias Lanttern.Explorer

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
