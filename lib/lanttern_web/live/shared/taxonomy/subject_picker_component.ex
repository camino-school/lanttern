defmodule LantternWeb.Taxonomy.SubjectPickerComponent do
  use LantternWeb, :live_component

  alias Lanttern.Taxonomy

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]}>
      <.badge_button
        :for={subject <- @subjects}
        theme={if subject.id in @selected_ids, do: "primary", else: "default"}
        icon_name={if subject.id in @selected_ids, do: "hero-check-mini", else: "hero-plus-mini"}
        phx-click={@on_select.(subject.id)}
      >
        <%= subject.name %>
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
      |> assign_new(:subjects, fn ->
        Taxonomy.list_subjects()
      end)

    {:ok, socket}
  end
end
