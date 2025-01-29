defmodule LantternWeb.OverlayComponents do
  @moduledoc """
  Provides core overlay components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents
  use Gettext, backend: Lanttern.Gettext

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
      <div
        id={"#{@id}-bg"}
        class="bg-ltrn-dark/75 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
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

  slot :title
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
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-backdrop"} class="fixed inset-0 bg-ltrn-dark/75 transition-opacity" />
      <div
        class="fixed inset-0 overflow-hidden"
        tabindex="0"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
      >
        <div class="absolute inset-0 overflow-hidden">
          <div class={[
            "pointer-events-none fixed top-20 bottom-0 flex max-w-full",
            "md:inset-y-0 md:right-0"
          ]}>
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={
                if not @prevent_close_on_click_away, do: JS.exec("data-cancel", to: "##{@id}")
              }
              class="pointer-events-auto w-screen md:max-w-xl transition-translate"
            >
              <div class="flex flex-col h-full divide-y divide-ltrn-lighter bg-white shadow-xl rounded-l">
                <div class="flex-1 min-h-0 overflow-y-scroll ltrn-bg-slide-over">
                  <h2
                    :if={@title != []}
                    class="px-4 sm:px-6 py-6 font-display font-black text-3xl"
                    id={"#{@id}-title"}
                  >
                    <%= render_slot(@title) %>
                  </h2>
                  <div id={"#{@id}-content"} class="p-4 sm:px-6">
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
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-ltrn-dark/75 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 z-50 w-screen"
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
            <div id={"#{@id}-content"} class={@class}>
              <%= render_slot(@inner_block) %>
            </div>
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              type="button"
              class="absolute top-2 right-2 flex p-2 rounded-full text-ltrn-subtle hover:bg-slate-100 hover:text-ltrn-primary"
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
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

  slot :item, required: true do
    attr :id, :string, required: true
    attr :text, :string, required: true
    attr :on_click, JS, required: true
    attr :theme, :string
    attr :confirm_msg, :string, doc: "use for adding a data-confirm attr"
  end

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
        <button
          :for={item <- @item}
          id={item.id}
          type="button"
          class={[
            "block w-full px-3 py-1 text-sm text-left focus:bg-ltrn-lighter",
            menu_button_item_theme_classes(Map.get(item, :theme, "default"))
          ]}
          role="menuitem"
          tabindex="-1"
          phx-click={
            item.on_click
            |> JS.exec("data-cancel", to: "#menu-button-#{@id}-button")
          }
          data-confirm={Map.get(item, :confirm_msg)}
        >
          <%= item.text %>
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a dropdown menu.

  Using a JS hook, this component handles the interaction between
  the button referenced by the `button_id` assign and the menu
  (view `dropdown-menu-hook.js` for more information).

  This component should be used in a parent with `postion: relative`.

  """

  attr :id, :string, required: true
  attr :button_id, :string, required: true
  attr :class, :string, default: nil
  attr :position, :string, default: "left", doc: "left or right"

  attr :z_index, :string,
    default: "10",
    doc:
      "use any existing Tailwind z-index value, or \"custom\" to override it with the class attr (e.g. to use an arbitrary value, z-[15])"

  slot :item, required: true do
    attr :text, :string, required: true
    attr :on_click, JS, required: true
    attr :theme, :string
    attr :confirm_msg, :string, doc: "use for adding a data-confirm attr"
  end

  def dropdown_menu(assigns) do
    position_classes =
      case assigns.position do
        "right" -> "right-0"
        _ -> "left-0"
      end

    z_index_class = get_z_index_class(assigns.z_index)

    assigns =
      assigns
      |> assign(:position_classes, position_classes)
      |> assign(:z_index_class, z_index_class)

    ~H"""
    <div
      id={@id}
      class={[
        "hidden absolute mt-1 min-w-full w-max max-w-sm rounded-sm bg-white py-2 shadow-lg ring-1 ring-ltrn-lighter focus:outline-none",
        @z_index_class,
        @position_classes,
        @class
      ]}
      role="menu"
      aria-orientation="vertical"
      aria-labelledby={@button_id}
      tabindex="-1"
      phx-window-keydown={JS.exec("data-close")}
      phx-key="escape"
      phx-click-away={JS.exec("data-close")}
      data-close={close_dropdown_menu(@id)}
      data-open={open_dropdown_menu(@id)}
      phx-hook="DropdownMenu"
    >
      <button
        :for={item <- @item}
        type="button"
        class={[
          "block w-full px-3 py-1 text-sm text-left focus:bg-ltrn-lighter",
          menu_button_item_theme_classes(Map.get(item, :theme, "default"))
        ]}
        role="menuitem"
        tabindex="-1"
        phx-click={
          item.on_click
          |> JS.exec("data-close", to: "##{@id}")
        }
        data-confirm={Map.get(item, :confirm_msg)}
      >
        <%= item.text %>
      </button>
    </div>
    """
  end

  @doc """
  Renders a selection filter modal.
  """

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :items, :list, required: true
  attr :selected_items_ids, :list, required: true
  attr :use_color_map_as_active, :boolean, default: false

  attr :on_cancel, JS,
    default: %JS{},
    doc: "the function to execute on cancel (click outside of modal or cancel click)"

  attr :on_select, :any, required: true, doc: "the function to execute on item select"

  attr :on_save, JS,
    default: nil,
    doc: "function. if present, will render a save and cancel button"

  def selection_filter_modal(assigns) do
    ~H"""
    <.modal id={@id} on_cancel={@on_cancel}>
      <h5 class="mb-10 font-display font-black text-xl">
        <%= @title %>
      </h5>
      <.badge_button_picker
        on_select={&@on_select.(&1)}
        items={@items}
        selected_ids={@selected_items_ids}
        use_color_map_as_active={@use_color_map_as_active}
      />
      <div :if={@on_save} class="flex justify-between gap-6 mt-10">
        <.action
          type="button"
          theme="subtle"
          size="md"
          phx-click={JS.exec("data-cancel", to: "##{@id}")}
        >
          <%= gettext("Cancel") %>
        </.action>
        <.action type="button" theme="primary" size="md" phx-click={@on_save}>
          <%= gettext("Save") %>
        </.action>
      </div>
    </.modal>
    """
  end

  # this solution looks odd, but it's the best idea
  # I could came with to inform Tailwind to compile
  # all the z- classes
  defp get_z_index_class("0"), do: "z-0"
  defp get_z_index_class("10"), do: "z-10"
  defp get_z_index_class("20"), do: "z-20"
  defp get_z_index_class("30"), do: "z-30"
  defp get_z_index_class("40"), do: "z-40"
  defp get_z_index_class("50"), do: "z-50"
  defp get_z_index_class("auto"), do: "auto"
  defp get_z_index_class(_z_index), do: nil

  @menu_button_item_themes %{
    "default" => "text-ltrn-dark",
    "alert" => "text-ltrn-alert-accent"
  }

  defp menu_button_item_theme_classes(theme),
    do: Map.get(@menu_button_item_themes, theme, @menu_button_item_themes["default"])

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

  defp open_dropdown_menu(id) do
    JS.show(
      to: "##{id}",
      transition: {
        "ease-out duration-100",
        "transform opacity-0 scale-95",
        "transform opacity-100 scale-100"
      },
      time: 100
    )
    |> JS.set_attribute({"aria-expanded", "true"})
  end

  defp close_dropdown_menu(id) do
    JS.hide(
      to: "##{id}",
      transition: {
        "ease-out duration-75",
        "transform opacity-100 scale-100",
        "transform opacity-0 scale-95"
      },
      time: 75
    )
    |> JS.remove_attribute("aria-expanded")
  end
end
