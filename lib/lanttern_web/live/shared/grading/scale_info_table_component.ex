defmodule LantternWeb.Grading.ScaleInfoTableComponent do
  @moduledoc """
  This component renders a table with scale info.

  ### Expected external assigns

  - `scale_id`

  ### Optional assigns

  - `class`

  """
  use LantternWeb, :live_component

  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div :if={@rows != []} class={@class}>
        <h6 class="mb-4 font-display font-bold"><%= gettext("Scale ranges") %></h6>
        <div class="w-full overflow-x-auto">
          <table class="w-full rounded-sm font-mono text-xs bg-ltrn-lightest">
            <thead>
              <tr>
                <th class="p-2 text-left"><%= gettext("Grade") %></th>
                <th class="p-2 text-left"><%= gettext("Greater than or equal to") %></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={{ordinal_value, gte} <- @rows}>
                <td class="p-2">
                  <.badge color_map={ordinal_value}><%= ordinal_value.name %></.badge>
                </td>
                <td class="p-2"><%= gte %></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
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
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_ordinal_values()
    |> build_and_assign_rows()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_ordinal_values(%{assigns: %{scale_id: scale_id}} = socket)
       when is_integer(scale_id) do
    scale =
      Grading.get_scale!(
        scale_id,
        preloads: [:ordinal_values]
      )

    # this component will handle only ordinal scales with correctly defined breakpoints
    {ordinal_values, breakpoints} =
      if length(scale.breakpoints) + 1 == length(scale.ordinal_values),
        do: {
          scale.ordinal_values |> Enum.sort_by(& &1.normalized_value),
          scale.breakpoints |> Enum.sort()
        },
        else: {[], []}

    socket
    |> assign(:ordinal_values, ordinal_values)
    |> assign(:breakpoints, breakpoints)
  end

  defp assign_ordinal_values(socket) do
    socket
    |> assign(:ordinal_values, [])
    |> assign(:breakpoints, [])
  end

  defp build_and_assign_rows(%{assigns: %{ordinal_values: ordinal_values}} = socket)
       when ordinal_values != [] do
    breakpoints = socket.assigns.breakpoints

    rows =
      ordinal_values
      |> Enum.with_index()
      |> Enum.map(fn {ordinal_value, index} ->
        gte = if index == 0, do: 0, else: Enum.at(breakpoints, index - 1)
        {ordinal_value, gte}
      end)

    assign(socket, :rows, rows)
  end

  defp build_and_assign_rows(socket), do: assign(socket, :rows, [])
end
