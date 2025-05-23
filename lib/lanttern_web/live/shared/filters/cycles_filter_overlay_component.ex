defmodule LantternWeb.Filters.CyclesFilterOverlayComponent do
  @moduledoc """
  Renders a cycles filter overlay.

  Expected external assigns:

  ```elixir
  attr :current_user, Lanttern.Identity.User, required: true
  attr :title, :string, required: true
  attr :navigate, :string
  attr :filter_opts, :list, default: [], doc: "opts used in `assign_cycle_filter/2`"
  attr :cycles, :list, required: true
  attr :selected_cycles_ids, :list, required: true
  ```
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
        <.badge_button_picker
          on_select={
            &JS.push("toggle_filter",
              value: %{"id" => &1},
              target: @myself
            )
          }
          items={@cycles}
          selected_ids={@selected_cycles_ids}
          class="mt-4"
        />
        <div :if={@filter_info} class="mt-6 flex items-center gap-2 text-ltrn-subtle">
          <.icon name="hero-information-circle-mini" />
          <p class="text-xs"><%= @filter_info %></p>
        </div>
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

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:has_changes, false)
      |> assign(:filter_opts, [])
      |> assign(:filter_info, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("toggle_filter", %{"id" => id}, socket) do
    socket =
      socket
      |> handle_filter_toggle(:cycles, id)
      |> assign(:has_changes, true)

    {:noreply, socket}
  end

  def handle_event("update_filters", _, socket) do
    {:noreply, assign(socket, :has_changes, false)}
  end

  def handle_event("clear_filters", _, socket) do
    clear_profile_filters(
      socket.assigns.current_user,
      [:cycles],
      socket.assigns.filter_opts
    )

    {:noreply, handle_navigation(socket)}
  end

  def handle_event("apply_filters", _, socket) do
    socket =
      socket
      |> save_profile_filters([:cycles], socket.assigns.filter_opts)
      |> assign(:has_changes, false)
      |> handle_navigation()

    {:noreply, socket}
  end
end
