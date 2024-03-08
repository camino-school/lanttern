defmodule LantternWeb.BadgeButtonPickerComponent do
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]}>
      <.badge_button
        :for={item <- @items}
        theme={if item.id in @selected_ids, do: "primary", else: "default"}
        icon_name={if item.id in @selected_ids, do: "hero-check-mini", else: "hero-plus-mini"}
        phx-click={@on_select.(item.id)}
      >
        <%= Map.get(item, @item_key) %>
      </.badge_button>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:items, [])
      |> assign(:item_key, :name)
      |> assign(:selected_ids, [])
      |> assign(:on_select, fn _id -> %JS{} end)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end
end
