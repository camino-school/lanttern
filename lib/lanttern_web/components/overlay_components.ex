defmodule LantternWeb.OverlayComponents do
  @moduledoc """
  Provides core overlay components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents
  import LantternWeb.Gettext

  @doc """
  Renders a modal.

  To show modal:

      * use `JS.exec("data-show", to: "#modalid")`
      * or mount with `show={true}`

  To hide modal:

      * use `JS.exec("data-cancel", to: "#modalid")`

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && JS.exec("data-show")}
      phx-remove={hide_modal(@id)}
      data-show={show_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-white/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="relative hidden p-10 rounded-xl bg-white shadow-lg transition"
            >
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="absolute top-4 right-5 flex-none p-3 opacity-20 hover:opacity-40"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders a slide over.

  To show slide over:

      * use `JS.exec("data-show", to: "#slideoverid")`
      * or mount with `show={true}`

  To hide slide over:

      * use `JS.exec("data-cancel", to: "#slideoverid")`

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
  attr :prevent_close_on_click_away, :boolean, default: false

  slot :title, required: true
  slot :inner_block, required: true
  slot :actions
  slot :actions_left

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
              phx-click-away={
                if not @prevent_close_on_click_away, do: JS.exec("data-cancel", to: "##{@id}")
              }
              class="pointer-events-auto w-screen max-w-xl transition-translate"
            >
              <div class="flex h-full flex-col divide-y divide-ltrn-lighter bg-white shadow-xl rounded-l">
                <div class="relative flex min-h-0 flex-1 flex-col overflow-y-scroll ltrn-bg-slide-over">
                  <h2
                    class="shrink-0 px-4 sm:px-6 py-6 font-display font-black text-3xl"
                    id={"#{@id}-title"}
                  >
                    <%= render_slot(@title) %>
                  </h2>
                  <div id={"#{@id}-content"} class="flex-1 p-4 sm:px-6">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
                <div :if={render_slot(@actions)} class="flex shrink-0 justify-between gap-4 p-4">
                  <div class="flex items-center gap-4">
                    <%= render_slot(@actions_left) %>
                  </div>
                  <div class="flex items-center gap-4">
                    <%= render_slot(@actions) %>
                  </div>
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
      * use `JS.exec("data-show", to: "#panelid")`
      * or mount with `show={true}`

  To hide panel:
      * use `JS.exec("data-cancel", to: "#panelid")`

  ## Examples

      <.panel_overlay id="panelid">
        This is a menu panel overlay.
      </.panel_overlay>
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil
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
        class="fixed inset-0 z-30 w-screen"
        tabindex="0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="flex h-full items-stretch justify-stretch pt-10 sm:p-10">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class="relative transform min-w-full h-full rounded bg-white shadow-xl transition-all"
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

  @doc """
  Renders a menu button.

  View `menu-button-hook.js` for more information on
  function component and JS integration.

  """

  attr :id, :string, required: true
  slot :menu_items, required: true, doc: "Use `<.menu_button_item>` components here"

  def menu_button(assigns) do
    ~H"""
    <div class="relative shrink-0">
      <button
        type="button"
        class="group w-8 h-8 rounded-full text-center"
        id={"menu-button-#{@id}-button"}
        aria-haspopup="true"
        phx-click={JS.exec("data-open")}
        phx-hook="MenuButton"
        data-open={open_menu_button(@id)}
        data-cancel={close_menu_button(@id)}
      >
        <span class="sr-only">Open options</span>
        <.icon
          name="hero-ellipsis-horizontal-mini"
          class="w-5 h-5 text-ltrn-subtle group-hover:text-ltrn-dark"
        />
      </button>
      <div
        id={"menu-button-#{@id}"}
        class="hidden absolute right-0 z-10 mt-1 w-32 origin-top-right rounded-sm bg-white py-2 shadow-lg ring-1 ring-ltrn-lighter focus:outline-none"
        role="menu"
        aria-orientation="vertical"
        aria-labelledby={"menu-button-#{@id}-button"}
        tabindex="-1"
        phx-window-keydown={JS.exec("data-cancel", to: "#menu-button-#{@id}-button")}
        phx-key="escape"
        phx-click-away={JS.exec("data-cancel", to: "#menu-button-#{@id}-button")}
      >
        <%= render_slot(@menu_items) %>
      </div>
    </div>
    """
  end

  defp open_menu_button(id, js \\ %JS{}) do
    js
    |> JS.show(
      to: "#menu-button-#{id}",
      transition: {
        "ease-out duration-100",
        "transform opacity-0 scale-95",
        "transform opacity-100 scale-100"
      },
      time: 100
    )
    |> JS.set_attribute({"aria-expanded", "true"})
  end

  defp close_menu_button(id, js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#menu-button-#{id}",
      transition: {
        "ease-out duration-75",
        "transform opacity-100 scale-100",
        "transform opacity-0 scale-95"
      },
      time: 75
    )
    |> JS.remove_attribute("aria-expanded")
  end

  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global, doc: "Use it to pass `phx-` bindings"
  slot :inner_block, required: true

  def menu_button_item(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      class={["block w-full px-3 py-1 text-sm text-left focus:bg-ltrn-lighter", @class]}
      role="menuitem"
      tabindex="-1"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
