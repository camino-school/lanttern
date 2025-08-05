defmodule LantternWeb.Grading.OrdinalValueBadgeComponent do
  @moduledoc """
  This component renders an ordinal value badge.

  It's a wrapper of `<.badge>`, but handles the
  ordinal value loading via `update_many/1`.

  ### Expected external assigns

  - `ordinal_value_id`

  ### Optional assigns

  - `class`

  """
  use LantternWeb, :live_component

  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.badge color_map={@ordinal_value}>
        {@ordinal_value.name}
      </.badge>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    ordinal_values_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.ordinal_value_id
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    ordinal_values_map =
      Grading.list_ordinal_values(ids: ordinal_values_ids)
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    assigns_sockets
    |> Enum.map(&update_single(&1, ordinal_values_map))
  end

  defp update_single({assigns, %{assigns: %{initialized: false}} = socket}, ordinal_values_map) do
    ordinal_value = Map.get(ordinal_values_map, assigns.ordinal_value_id)

    socket
    |> assign(assigns)
    |> assign(:ordinal_value, ordinal_value)
    |> assign(:initialized, true)
  end

  defp update_single({_assigns, socket}, _ordinal_values_map), do: socket
end
