defmodule LantternWeb.Filters.InlineFiltersComponent do
  @moduledoc """
  Renders an inline filter component based on the list of items and selected ids
  from `LantternWeb.FiltersHelpers.assign_user_filters/4`.

  This component receives the inital state from the parent view/component,
  but handles its own internal state (selected items).
  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]}>
      <.badge_button
        :if={!@hide_all_opt}
        id={"#{@id}-all"}
        phx-click={JS.push("toggle_all", target: @myself)}
        {get_select_all_attrs(@selected_items_ids)}
      >
        <%= @all_text %>
      </.badge_button>
      <.badge_button
        :for={item <- @filter_items}
        id={"#{@id}-#{item.id}"}
        phx-click={JS.push("toggle_filter", value: %{"id" => item.id}, target: @myself)}
        {get_filter_attrs(item.id, @selected_items_ids)}
      >
        <%= item.name %>
      </.badge_button>
      <.badge_button :if={@has_changes} theme="dark" phx-click="apply_filters" phx-target={@myself}>
        <%= gettext("Apply filters") %>
      </.badge_button>
    </div>
    """
  end

  defp get_select_all_attrs(selected_items_ids) do
    case selected_items_ids do
      [] ->
        %{
          theme: "primary",
          icon_name: "hero-check-mini"
        }

      _ ->
        %{
          theme: nil,
          icon_name: nil
        }
    end
  end

  defp get_filter_attrs(item_id, selected_items_ids) do
    case item_id in selected_items_ids do
      true ->
        %{
          theme: "primary",
          icon_name: "hero-check-mini"
        }

      _ ->
        %{
          theme: nil,
          icon_name: nil
        }
    end
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:hide_all_opt, false)
      |> assign(:is_single, false)
      |> assign(:all_text, gettext("All"))

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:initial_selected_items_ids, assigns.selected_items_ids)
      |> assign(:has_changes, false)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("toggle_all", _params, %{assigns: %{is_single: true}} = socket) do
    notify(__MODULE__, {:apply, []}, socket.assigns)

    {:noreply, socket}
  end

  def handle_event("toggle_all", _params, socket) do
    socket =
      socket
      |> assign(:selected_items_ids, [])
      |> assign(:has_changes, check_if_has_changes(socket.assigns.initial_selected_items_ids, []))

    {:noreply, socket}
  end

  def handle_event("toggle_filter", %{"id" => id}, %{assigns: %{is_single: true}} = socket) do
    notify(__MODULE__, {:apply, [id]}, socket.assigns)

    {:noreply, socket}
  end

  def handle_event("toggle_filter", %{"id" => id}, socket) do
    selected_items_ids =
      case id in socket.assigns.selected_items_ids do
        true ->
          socket.assigns.selected_items_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_items_ids]
      end

    socket =
      socket
      |> assign(:selected_items_ids, selected_items_ids)
      |> assign(
        :has_changes,
        check_if_has_changes(socket.assigns.initial_selected_items_ids, selected_items_ids)
      )

    {:noreply, socket}
  end

  def handle_event("apply_filters", _params, socket) do
    notify(__MODULE__, {:apply, socket.assigns.selected_items_ids}, socket.assigns)

    {:noreply, socket}
  end

  defp check_if_has_changes([], []), do: false
  defp check_if_has_changes([], _current_selected_ids), do: true
  defp check_if_has_changes(_initial_selected_ids, []), do: true

  defp check_if_has_changes(initial_selected_ids, current_selected_ids) do
    is_same_length = length(initial_selected_ids) == length(current_selected_ids)
    has_same_items = Enum.all?(initial_selected_ids, &(&1 in current_selected_ids))

    not is_same_length or not has_same_items
  end
end
