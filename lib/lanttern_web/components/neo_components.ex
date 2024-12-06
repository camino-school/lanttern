defmodule LantternWeb.NeoComponents do
  @moduledoc """
  Provides neo core components.

  We might replace core components in the future with this module.
  """
  use Phoenix.Component

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
  end

  def neo_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-4", @class]} id={@id}>
      <.link
        :for={tab <- @tab}
        patch={Map.get(tab, :patch)}
        navigate={Map.get(tab, :navigate)}
        class={[
          "relative shrink-0 py-4 font-display font-bold whitespace-nowrap",
          if(Map.get(tab, :is_current),
            do: "text-ltrn-dark",
            else: "text-ltrn-subtle hover:text-ltrn-dark"
          )
        ]}
      >
        <%= render_slot(tab) %>
        <span :if={Map.get(tab, :is_current)} class="absolute h-1 bg-ltrn-dark inset-x-0 bottom-0" />
      </.link>
    </nav>
    """
  end
end
