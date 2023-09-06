defmodule LantternWeb.OverlayComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents
  import LantternWeb.Gettext

  @doc """
  Renders a slide over.

  ## Examples

      <.slide_over>
        <:title>Slide over title</:title>
        This is a slide over.
        <:actions>
          <button>Cancel</button>
          <button>Submit</button>
        </:actions>
      </.slide_over>
  """
  attr :rest, :global
  slot :title, required: true
  slot :inner_block, required: true
  slot :actions, required: true

  def slide_over(assigns) do
    ~H"""
    <div
      class="relative z-10"
      aria-labelledby="slide-over-title"
      role="dialog"
      aria-modal="true"
      phx-mounted={show_slide_over()}
      phx-remove={hide_slide_over()}
      {@rest}
    >
      <div id="slide-over-backdrop" class="fixed inset-0 bg-white/75 transition-opacity hidden"></div>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div
              id="slide-over-panel"
              class="pointer-events-auto w-screen max-w-xl py-6 transition-translate hidden"
            >
              <div class="flex h-full flex-col divide-y divide-ltrn-hairline bg-white shadow-xl rounded-l">
                <div class="flex min-h-0 flex-1 flex-col overflow-y-scroll py-6 lanttern-bg-1">
                  <div class="px-4 sm:px-6">
                    <div class="flex items-start justify-between">
                      <h2 class="font-display font-black text-3xl" id="slide-over-title">
                        <%= render_slot(@title) %>
                      </h2>
                    </div>
                  </div>
                  <div class="relative mt-6 flex-1 px-4 sm:px-6">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
                <div class="flex flex-shrink-0 justify-end gap-4 px-4 py-4">
                  <%= render_slot(@actions) %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp show_slide_over() do
    JS.add_class(
      "overflow-hidden",
      to: "body"
    )
    |> JS.show(
      to: "#slide-over-backdrop",
      transition: {"ease-in-out duration-500", "opacity-0", "opacity-100"},
      time: 500
    )
    |> JS.show(
      to: "#slide-over-panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-full",
        "translate-x-0"
      },
      time: 500
    )
  end

  defp hide_slide_over() do
    JS.remove_class("overflow-hidden", to: "body")
    |> JS.hide(
      to: "#slide-over-backdrop",
      transition: {"ease-in-out duration-500", "opacity-100", "opacity-0"},
      time: 500
    )
    |> JS.hide(
      to: "#slide-over-panel",
      transition: {
        "ease-in-out duration-500",
        "translate-x-0",
        "translate-x-full"
      },
      time: 500
    )
  end

  @doc """
  Renders a panel overlay.

  To show panel:
  - use `JS.exec("data-show", to: "#panelid")`
  - or mount with `show={true}`

  To hide panel:
  - use `JS.exec("data-cancel", to: "#panelid")`

  ## Examples

      <.panel_overlay id="panelid">
        This is a menu panel overlay.
      </.panel_overlay>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def panel_overlay(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && JS.exec("data-show")}
      phx-remove={hide_panel_overlay(@id)}
      data-show={show_panel_overlay(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-10 hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-white/75 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 z-10 w-screen overflow-y-auto"
        tabindex="0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="flex min-h-full items-stretch justify-stretch p-10">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class="relative transform overflow-hidden min-w-full min-h-full rounded bg-white p-10 shadow-xl transition-all"
          >
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              type="button"
              class="absolute top-2 right-2 flex p-2 rounded-full text-ltrn-subtle hover:bg-slate-100 hover:text-ltrn-primary"
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
            <div id={"#{@id}-content"}>
              <%= render_slot(@inner_block) %>
            </div>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  defp show_panel_overlay(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_panel_overlay(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
