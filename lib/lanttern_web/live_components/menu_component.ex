defmodule LantternWeb.MenuComponent do
  use LantternWeb, :live_component

  def mount(socket) do
    active_nav =
      cond do
        socket.view in [
          LantternWeb.AssessmentPointsLive,
          LantternWeb.AssessmentPointsExplorerLive,
          LantternWeb.AssessmentPointLive
        ] ->
          :assessment_points

        socket.view in [LantternWeb.CurriculumLive, LantternWeb.CurriculumBNCCEFLive] ->
          :curriculum

        true ->
          nil
      end

    {:ok, assign(socket, :active_nav, active_nav)}
  end

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
        class="flex items-stretch h-full divide-x divide-ltrn-hairline ltrn-bg-menu"
      >
        <div class="flex-1 flex flex-col justify-between">
          <nav>
            <ul class="grid grid-cols-3 gap-px border-b border-ltrn-hairline bg-ltrn-hairline">
              <.nav_item active={@active_nav == nil} path={~p"/"}>
                Dashboard
              </.nav_item>
              <.nav_item active={@active_nav == :assessment_points} path={~p"/assessment_points"}>
                Assessment points
              </.nav_item>
              <.nav_item active={@active_nav == :curriculum} path={~p"/curriculum"}>
                Curriculum
              </.nav_item>
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
              <li class="mt-4">
                <.link href={~p"/users/log_out"} method="delete">
                  Log out
                </.link>
              </li>
            </ul>
          </nav>
        </div>
      </.panel_overlay>
    </div>
    """
  end

  attr :path, :string, required: true
  attr :active, :boolean, required: true
  slot :inner_block, required: true

  def nav_item(assigns) do
    ~H"""
    <li class="bg-white">
      <.link
        navigate={@path}
        class={[
          "group relative block p-10 font-display font-black text-lg",
          if(@active, do: "text-ltrn-text", else: "text-ltrn-subtle underline hover:no-underline")
        ]}
      >
        <span class={[
          "absolute top-2 left-2 block w-6 h-6",
          if(@active, do: "bg-ltrn-primary", else: "group-hover:bg-ltrn-subtle")
        ]} />
        <%= render_slot(@inner_block) %>
      </.link>
    </li>
    """
  end
end
