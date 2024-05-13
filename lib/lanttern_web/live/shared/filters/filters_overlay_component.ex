defmodule LantternWeb.Filters.FiltersOverlayComponent do
  @moduledoc """
  Renders a filter overlay
  """

  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id}>
        <h5 class="mb-10 font-display font-black text-xl">
          <%= @title %>
        </h5>
        <.filter_group myself={@myself} {get_filter_groups_attrs(@filter_type, assigns)} />
        <div class="flex justify-between gap-2 mt-10">
          <.button type="button" theme="ghost" phx-click={JS.push("clear_filters", target: @myself)}>
            <%= gettext("Clear filters") %>
          </.button>
          <div class="flex gap-2">
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
          </div>
        </div>
      </.modal>
    </div>
    """
  end

  attr :type, :string, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :items, :list, required: true
  attr :selected_ids, :list, required: true

  defp filter_group(assigns) do
    ~H"""
    <div>
      <.badge_button_picker
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
      type: "subjects",
      items: assigns.subjects,
      selected_ids: assigns.selected_subjects_ids
    }
  end

  defp get_filter_groups_attrs(:years, assigns) do
    %{
      type: "years",
      items: assigns.years,
      selected_ids: assigns.selected_years_ids
    }
  end

  defp get_filter_groups_attrs(:classes, assigns) do
    %{
      type: "classes",
      items: assigns.classes,
      selected_ids: assigns.selected_classes_ids
    }
  end

  defp get_filter_groups_attrs(:cycles, assigns) do
    %{
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
      |> assign(:filter_opts, [])

    {:ok, socket}
  end

  @impl true
  def update(%{filter_type: filter_type} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters(
        [filter_type],
        assigns.current_user,
        Map.get(assigns, :filter_opts, [])
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
      [socket.assigns.filter_type],
      socket.assigns.filter_opts
    )

    {:noreply, handle_navigation(socket)}
  end

  def handle_event("apply_filters", _, socket) do
    socket =
      socket
      |> save_profile_filters(
        socket.assigns.current_user,
        [socket.assigns.filter_type],
        socket.assigns.filter_opts
      )
      |> assign(:has_changes, false)
      |> handle_navigation()

    {:noreply, socket}
  end
end
