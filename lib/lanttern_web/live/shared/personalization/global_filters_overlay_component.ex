defmodule LantternWeb.Personalization.GlobalFiltersOverlayComponent do
  use LantternWeb, :live_component

  import LantternWeb.PersonalizationHelpers

  # shared components
  alias LantternWeb.BadgeButtonPickerComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id}>
        <:title><%= @title %></:title>
        <.filter_group
          :for={filter_type <- @filters}
          myself={@myself}
          {get_filter_groups_attrs(filter_type, assigns)}
        />
        <:actions_left>
          <.button type="button" theme="ghost" phx-click={JS.push("clear_filters", target: @myself)}>
            <%= gettext("Clear filters") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
            <%= gettext("Cancel") %>
          </.button>
          <.button
            type="button"
            disabled={!@has_changes}
            phx-click={JS.push("apply_filters", target: @myself)}
            phx-disable-with={gettext("Applying filters...")}
          >
            <%= gettext("Apply filters") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :type, :string, required: true
  attr :myself, :any, required: true
  attr :items, :list, required: true
  attr :selected_ids, :list, required: true

  defp filter_group(assigns) do
    ~H"""
    <div class="mb-10">
      <p class="font-display font-black text-lg">
        <%= @title %>
      </p>
      <.live_component
        module={BadgeButtonPickerComponent}
        id={"global-#{@type}-filter"}
        on_select={
          &JS.push("toggle_filter",
            value: %{"id" => &1, "type" => @type},
            target: @myself
          )
        }
        items={@items}
        selected_ids={@selected_ids}
        class="mt-4"
      />
    </div>
    """
  end

  defp get_filter_groups_attrs(:subjects, assigns) do
    %{
      title: gettext("Subjects"),
      type: "subjects",
      items: assigns.subjects,
      selected_ids: assigns.selected_subjects_ids
    }
  end

  defp get_filter_groups_attrs(:years, assigns) do
    %{
      title: gettext("Years"),
      type: "years",
      items: assigns.years,
      selected_ids: assigns.selected_years_ids
    }
  end

  defp get_filter_groups_attrs(:classes, assigns) do
    %{
      title: gettext("Classes"),
      type: "classes",
      items: assigns.classes,
      selected_ids: assigns.selected_classes_ids
    }
  end

  defp get_filter_groups_attrs(:cycles, assigns) do
    %{
      title: gettext("Cycles"),
      type: "cycles",
      items: assigns.cycles,
      selected_ids: assigns.selected_cycles_ids
    }
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:has_changes, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters(
        [:subjects, :years, :classes, :cycles],
        assigns.current_user
      )

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("toggle_filter", %{"id" => id, "type" => type}, socket) do
    socket =
      socket
      |> handle_filter_toggle(String.to_atom(type), id)
      |> assign(:has_changes, true)

    {:noreply, socket}
  end

  def handle_event("update_filters", _, socket) do
    {:noreply, assign(socket, :has_changes, false)}
  end

  def handle_event("clear_filters", _, socket) do
    clear_profile_filters(
      socket.assigns.current_user,
      socket.assigns.filters
    )

    {:noreply, handle_navigation(socket)}
  end

  def handle_event("apply_filters", _, socket) do
    socket =
      socket
      |> save_profile_filters(socket.assigns.current_user, socket.assigns.filters)
      |> assign(:has_changes, false)
      |> handle_navigation()

    {:noreply, socket}
  end
end
