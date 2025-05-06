defmodule LantternWeb.StudentLive.AIComponent do
  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-10 px-4">
        <button type="button">Request AI report</button>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket
end
