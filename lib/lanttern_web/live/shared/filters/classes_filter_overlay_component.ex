defmodule LantternWeb.Filters.ClassesFilterOverlayComponent do
  @moduledoc """
  Renders a classes filter overlay.

  Expected external assigns:

  ```elixir
  attr :profile_filter_opts, :any, doc: "the keyword list used in `clear_profile_filters/3` and `save_profile_fitlers/3` (e.g. `strand_id`)"
  attr :current_user, Lanttern.Identity.User, required: true
  attr :title, :string, required: true
  attr :navigate, :string
  attr :classes, :list, required: true
  attr :selected_classes_ids, :list, required: true
  ```
  """

  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers

  # shared

  alias LantternWeb.Schools.ClassSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id}>
        <h5 class="mb-6 font-display font-black text-xl">
          <%= @title %>
        </h5>
        <.badge_button_picker
          on_select={
            &JS.push("toggle_filter",
              value: %{"id" => &1},
              target: @myself
            )
          }
          items={@classes}
          selected_ids={@selected_classes_ids}
          label_setter="class_with_cycle"
          current_user_or_cycle={@current_user}
        />
        <form class="mt-6">
          <.live_component
            module={ClassSearchComponent}
            id="class-search"
            notify_component={@myself}
            label={gettext("Search all school classes")}
          />
        </form>
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
      |> assign(:profile_filter_opts, [])

    {:ok, socket}
  end

  @impl true
  def update(%{action: {ClassSearchComponent, {:selected, class}}}, socket) do
    selected_classes_ids =
      [class.id | socket.assigns.selected_classes_ids]
      |> Enum.uniq()

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> maybe_add_class_from_search(class)
      |> assign(:has_changes, true)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  # the selected class may not be part of the initial class list
  # in this case, we add the selected class to the list
  defp maybe_add_class_from_search(socket, class) do
    classes_ids = Enum.map(socket.assigns.classes, & &1.id)

    if class.id in classes_ids do
      socket
    else
      classes = socket.assigns.classes ++ [class]
      assign(socket, :classes, classes)
    end
  end

  # event handlers

  @impl true
  def handle_event("toggle_filter", %{"id" => id}, socket) do
    socket =
      socket
      |> handle_filter_toggle(:classes, id)
      |> assign(:has_changes, true)

    {:noreply, socket}
  end

  def handle_event("update_filters", _, socket) do
    {:noreply, assign(socket, :has_changes, false)}
  end

  def handle_event("clear_filters", _, socket) do
    clear_profile_filters(
      socket.assigns.current_user,
      [:classes],
      socket.assigns.profile_filter_opts
    )

    {:noreply, handle_navigation(socket)}
  end

  def handle_event("apply_filters", _, socket) do
    socket =
      socket
      |> save_profile_filters([:classes], socket.assigns.profile_filter_opts)
      |> assign(:has_changes, false)
      |> handle_navigation()

    {:noreply, socket}
  end
end
