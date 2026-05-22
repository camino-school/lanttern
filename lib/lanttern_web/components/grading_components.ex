defmodule LantternWeb.GradingComponents do
  @moduledoc """
  Shared function components related to `Grading` context
  """

  use Phoenix.Component
  import LantternWeb.CoreComponents

  @doc """
  Renders the first and last ordinal values of a scale as badges,
  giving a quick visual sense of the scale range.

  Requires `ordinal_values` preloaded on `scale`.
  When `id` is omitted, no tooltip is rendered.
  """
  attr :scale, :any, required: true

  attr :id, :string,
    default: nil,
    doc: "When set, renders a tooltip with the full scale name and values"

  def ordinal_scale_range(%{scale: %{ordinal_values: []}} = assigns) do
    ~H"—"
  end

  def ordinal_scale_range(%{scale: %{ordinal_values: [_only]}} = assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <.badge class="shrink-0" color_map={hd(@scale.ordinal_values)}>
        {ov_short(hd(@scale.ordinal_values))}
      </.badge>
      <.tooltip :if={@id} id={"#{@id}-scale-tooltip"}>
        {@scale.name}: {ov_list_label(@scale.ordinal_values)}
      </.tooltip>
    </div>
    """
  end

  def ordinal_scale_range(assigns) do
    ~H"""
    <div class="flex items-center gap-1">
      <.badge class="shrink-0" color_map={hd(@scale.ordinal_values)}>
        {ov_short(hd(@scale.ordinal_values))}
      </.badge>
      —
      <.badge class="shrink-0" color_map={List.last(@scale.ordinal_values)}>
        {ov_short(List.last(@scale.ordinal_values))}
      </.badge>
      <.tooltip :if={@id} id={"#{@id}-scale-tooltip"}>
        {@scale.name}: {ov_list_label(@scale.ordinal_values)}
      </.tooltip>
    </div>
    """
  end

  defp ov_short(%{short_name: short_name, name: name}),
    do: short_name || String.slice(name, 0..2)

  defp ov_list_label(ordinal_values),
    do: Enum.map_join(ordinal_values, ", ", & &1.name)
end
