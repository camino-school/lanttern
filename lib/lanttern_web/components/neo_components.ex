defmodule LantternWeb.NeoComponents do
  @moduledoc """
  Provides neo core components.

  We might replace core components in the future with this module.
  """
  use Phoenix.Component

  import LantternWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders navigation tabs.

  ## Examples

      <.neo_tabs>
        <:tab patch={~p"/home"}>Home</:tab>
        <:tab patch={~p"/page-1"} is_current="true">Page 1</:tab>
        <:tab patch={~p"/page-2"}>Page 2</:tab>
      </.neo_tabs>

  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  slot :tab, required: true do
    attr :patch, :string
    attr :navigate, :string
    attr :is_current, :boolean
    attr :theme, :string, doc: "ai (or nothing)"
  end

  def neo_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-4", @class]} id={@id}>
      <.link
        :for={tab <- @tab}
        patch={Map.get(tab, :patch)}
        navigate={Map.get(tab, :navigate)}
        class={[
          "relative shrink-0 flex items-center gap-1 py-4 font-display font-bold whitespace-nowrap",
          if(Map.get(tab, :is_current),
            do: get_active_text_class(Map.get(tab, :theme)),
            else: get_inactive_text_class(Map.get(tab, :theme))
          )
        ]}
      >
        <.icon :if={Map.get(tab, :theme) == "ai"} name="hero-sparkles-micro" class="h-4 w-4" />
        {render_slot(tab)}
        <span
          :if={Map.get(tab, :is_current)}
          class={["absolute h-1 inset-x-0 bottom-0", get_active_bar_class(Map.get(tab, :theme))]}
        />
      </.link>
    </nav>
    """
  end

  defp get_active_text_class("ai"), do: "text-ltrn-ai-accent"
  defp get_active_text_class(_), do: "text-ltrn-dark"

  defp get_inactive_text_class("ai"), do: "text-ltrn-subtle hover:text-ltrn-ai-accent"
  defp get_inactive_text_class(_), do: "text-ltrn-subtle hover:text-ltrn-dark"

  defp get_active_bar_class("ai"), do: "bg-ltrn-ai-accent"
  defp get_active_bar_class(_), do: "bg-ltrn-dark"
end
