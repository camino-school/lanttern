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
      <.panel_overlay
        id="menu"
        class="flex items-stretch h-full divide-x divide-ltrn-hairline ltrn-bg-2"
      >
        <div class="flex-1 flex flex-col justify-between">
          <nav>
            <ul class="grid grid-cols-3 gap-px border-b border-ltrn-hairline bg-ltrn-hairline">
              <.nav_item>Dashboard</.nav_item>
              <.nav_item>Assessment points</.nav_item>
              <.nav_item>Curriculum</.nav_item>
            </ul>
          </nav>
          <h5 class="relative flex items-center ml-6 mb-6 font-display font-black text-3xl text-ltrn-text">
            <span class="w-20 h-20 rounded-full bg-ltrn-mesh-primary blur-sm" />
            <span class="relative -ml-10">lanttern</span>
          </h5>
        </div>
        <div class="w-96 p-10 font-display">
          <p class="mb-4 font-black text-lg text-ltrn-primary">You're logged in as</p>
          <p class="font-black text-4xl text-ltrn-text">Username Here</p>
          <p class="mt-2 font-black text-lg text-ltrn-text">@ School Name</p>
          <nav class="mt-10">
            <ul class="font-bold text-lg underline text-ltrn-subtle">
              <li>Change School</li>
              <li>Edit profile</li>
              <li class="mt-4">Logout</li>
            </ul>
          </nav>
        </div>
      </.panel_overlay>
    </div>
    """
  end

  slot :inner_block, required: true

  def nav_item(assigns) do
    ~H"""
    <li class="relative p-10 font-display font-black text-lg text-ltrn-subtle underline bg-white">
      <%= render_slot(@inner_block) %>
    </li>
    """
  end
end
