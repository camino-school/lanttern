defmodule LantternWeb.Taxonomy.YearPickerComponent do
  use LantternWeb, :live_component

  alias Lanttern.Taxonomy

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]}>
      <.badge_button
        :for={year <- @years}
        theme={if year.id in @selected_ids, do: "cyan", else: "default"}
        icon_name={if year.id in @selected_ids, do: "hero-check-mini", else: "hero-plus-mini"}
        phx-click={@on_select.(year.id)}
      >
        <%= year.name %>
      </.badge_button>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:selected_ids, [])
      |> assign(:on_select, fn _id -> %JS{} end)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:years, fn ->
        Taxonomy.list_years()
      end)

    {:ok, socket}
  end
end
