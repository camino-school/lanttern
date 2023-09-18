defmodule LantternWeb.OverlayComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents
  import LantternWeb.Gettext

  @doc """
  Renders a slide over.

  To show slide over:
  - use `JS.exec("data-show", to: "#slideoverid")`
  - or mount with `show={true}`

  To hide slide over:
  - use `JS.exec("data-cancel", to: "#slideoverid")`

  ## Examples

      <.slide_over id="slideoverid>
        <:title>Slide over title</:title>
        This is a slide over.
        <:actions>
          <button>Cancel</button>
          <button>Submit</button>
        </:actions>
      </.slide_over>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}

  slot :title, required: true
  slot :inner_block, required: true
  slot :actions

  def slide_over(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && JS.exec("data-show")}
      phx-remove={hide_slide_over(@id)}
      data-show={show_slide_over(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-30 hidden"
    >
      <div id={"#{@id}-backdrop"} class="fixed inset-0 bg-white/75 transition-opacity" />
      <div
        class="fixed inset-0 overflow-hidden"
        tabindex="0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="pointer-events-auto w-screen max-w-xl transition-translate"
            >
              <div class="flex h-full flex-col divide-y divide-ltrn-hairline bg-white shadow-xl rounded-l">
                <div class="flex min-h-0 flex-1 flex-col overflow-y-scroll py-6 ltrn-bg-slide-over">
                  <div class="px-4 sm:px-6">
                    <div class="flex items-start justify-between">
                      <h2 class="font-display font-black text-3xl" id={"#{@id}-title"}>
                        <%= render_slot(@title) %>
                      </h2>
                    </div>
                  </div>
                  <div id={"#{@id}-content"} class="relative mt-6 flex-1 px-4 sm:px-6">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
                <div
                  :if={render_slot(@actions)}
                  class="flex flex-shrink-0 justify-end gap-4 px-4 py-4"
                >
                  <%= render_slot(@actions) %>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp show_slide_over(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-backdrop",
      transition: {"ease-in-out duration-500", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      transition: {
        "ease-in-out duration-500",
        "translate-x-full",
        "translate-x-0"
      },
      time: 500
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_slide_over(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"ease-in-out duration-500", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition: {
        "ease-in-out duration-500",
        "translate-x-0",
        "translate-x-full"
      },
      time: 500
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
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
  attr :class, :any, default: ""
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
      class="relative z-30 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-white/75 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 z-30 w-screen overflow-y-auto"
        tabindex="0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="flex h-full items-stretch justify-stretch p-10">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class="relative transform overflow-hidden min-w-full h-full rounded bg-white shadow-xl transition-all"
          >
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              type="button"
              class="absolute top-2 right-2 flex p-2 rounded-full text-ltrn-subtle hover:bg-slate-100 hover:text-ltrn-primary"
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
            <div id={"#{@id}-content"} class={@class}>
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
      to: "##{id}-backdrop",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"},
      time: 300
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_panel_overlay(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
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
