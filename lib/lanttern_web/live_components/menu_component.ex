defmodule LantternWeb.MenuComponent do
  use LantternWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <button
        type="button"
        class="group flex gap-1 items-center p-2 rounded bg-white shadow-xl hover:bg-slate-100"
        phx-click={JS.exec("data-show", to: "#menu")}
        aria-label="open menu"
      >
        <.icon name="hero-bars-3 text-ltrn-subtle" />
        <div class="w-6 h-6 rounded-full bg-ltrn-mesh-primary blur-sm group-hover:blur-none transition-[filter]" />
      </button>
      <.panel_overlay id="menu">
        Test
      </.panel_overlay>
    </div>
    """
  end
end
