defmodule LantternWeb.GradingComponents do
  use Phoenix.Component

  import LantternWeb.CoreComponents

  @doc """
  Renders a ordinal value badge.
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  attr :ordinal_value, :map,
    default: nil,
    doc: "map with `:bg_color` and `:text_color` keys"

  attr :show_remove, :boolean, default: false
  attr :rest, :global, doc: "use to pass phx-* bindings to the remove button"
  slot :inner_block, required: true

  def ordinal_value_badge(assigns) do
    ~H"""
    <.badge
      id={@id}
      class={@class}
      show_remove={@show_remove}
      {@rest}
      {apply_style_from_ordinal_value(@ordinal_value)}
    >
      <%= render_slot(@inner_block) %>
    </.badge>
    """
  end

  @doc """
  Creates a style attr based on ordinal values `bg_color` and `text_color`
  """
  def apply_style_from_ordinal_value(%{bg_color: bg_color, text_color: text_color}) do
    %{
      style: "background-color: #{bg_color}; color: #{text_color}"
    }
  end

  def apply_style_from_ordinal_value(_), do: %{}

  @doc """
  Creates a style attr based on scale start and stop colors
  """
  def apply_gradient_from_scale(%{start_bg_color: start_bg_color, stop_bg_color: stop_bg_color})
      when is_binary(start_bg_color) and is_binary(stop_bg_color) do
    %{
      style: "background-image: linear-gradient(to right, #{start_bg_color}, #{stop_bg_color})"
    }
  end

  def apply_gradient_from_scale(_), do: %{}
end
