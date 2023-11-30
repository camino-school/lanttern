defmodule LantternWeb.DashboardLive.Index do
  @moduledoc """
  Dashboard live view
  """

  use LantternWeb, :live_view
  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileView

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
                phx-click={JS.patch(~p"/dashboard/filter_view/#{@filter_view.id}/edit")}
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

    filter_views =
      Personalization.list_profile_views(
        profile_id: profile_id,
        preloads: [:subjects, :classes]
      )

    filter_view_count = length(filter_views)

    socket =
      socket
      |> stream(:filter_views, filter_views)
      |> assign(:filter_view_count, filter_view_count)
      |> assign(:current_filter_view_id, nil)
      |> assign(:show_filter_view_overlay, false)

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit_filter_view, %{"id" => id}) do
    socket
    |> assign(:filter_view_overlay_title, "Edit assessment points filter view")
    |> assign(
      :filter_view,
      Personalization.get_profile_view!(id, preloads: [:subjects, :classes])
    )
  end

  defp apply_action(socket, :new_filter_view, _params) do
    socket
    |> assign(:filter_view_overlay_title, "Create assessment points filter view")
    |> assign(:filter_view, %ProfileView{
      profile_id: socket.assigns.current_user.current_profile_id,
      classes: [],
      subjects: []
    })
  end

  defp apply_action(socket, :index, _params), do: socket

  # event handlers

  def handle_event("delete_filter_view", %{"id" => filter_view_id} = _params, socket) do
    profile_view = Personalization.get_profile_view!(filter_view_id)

    case Personalization.delete_profile_view(profile_view) do
      {:ok, _} ->
        socket =
          socket
          |> stream_delete(:filter_views, profile_view)
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

  def handle_info(
        {LantternWeb.DashboardLive.FilterViewFormComponent, {:created, filter_view}},
        socket
      ) do
    socket =
      socket
      |> stream_insert(:filter_views, filter_view)
      |> put_flash(:info, "Profile view created.")
      |> update(:filter_view_count, fn count -> count + 1 end)
      |> push_patch(to: ~p"/dashboard")

    {:noreply, socket}
  end

  def handle_info(
        {LantternWeb.DashboardLive.FilterViewFormComponent, {:updated, filter_view}},
        socket
      ) do
    socket =
      socket
      |> stream_insert(:filter_views, filter_view)
      |> put_flash(:info, "Profile view updated.")
      |> push_patch(to: ~p"/dashboard")

    {:noreply, socket}
  end
end
