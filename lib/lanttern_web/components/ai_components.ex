defmodule LantternWeb.AIComponents do
  @moduledoc """
  Provides core AI components.
  """
  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a AI panel overlay.

  To show panel:
      * use `JS.exec("data-show", to: "#panelid")`
      * or mount with `show={true}`

  To hide panel:
      * use `JS.exec("data-cancel", to: "#panelid")`

  ## Examples

      <.ai_panel_overlay id="panelid">
        This is a menu panel overlay.
      </.ai_panel_overlay>
  """
  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :panel_title, :string, default: nil
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def ai_panel_overlay(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && JS.exec("data-show")}
      phx-remove={hide_ai_panel_overlay(@id)}
      data-show={show_ai_panel_overlay(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class="fixed inset-0 bg-white/50 transition-opacity"
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
        <div class="flex h-full items-stretch justify-stretch max-w-lg pt-10 sm:p-4">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class="flex flex-col min-w-full h-full p-2 rounded bg-amber-50 shadow-xl transform transition-all overflow-hidden"
          >
            <div
              id={"#{@id}-content"}
              class={["flex-1 border-4 overflow-auto ltrn-ai-overlay-border", @class]}
            >
              <h4 :if={@panel_title} class="mb-6 font-display font-black text-lg text-ltrn-ai-dark">
                <%= @panel_title %>
              </h4>
              <%= render_slot(@inner_block) %>
            </div>
            <h6 class="shrink-0 flex items-center gap-2 mt-2">
              <.ai_spots />
              <span class="font-display font-black text-xl text-ltrn-ai-dark">LantternAI</span>
            </h6>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  defp show_ai_panel_overlay(js \\ %JS{}, id) when is_binary(id) do
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
         "opacity-0 translate-y-10 sm:-translate-x-2 sm:scale-95",
         "opacity-100 translate-y-0 sm:translate-x-0 sm:scale-100"},
      time: 300,
      display: "flex"
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  defp hide_ai_panel_overlay(js \\ %JS{}, id) do
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
         "opacity-100 translate-y-0 sm:translate-x-0 sm:scale-100",
         "opacity-0 translate-y-10 sm:-translate-x-2 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders a floating AI button.
  Used to open a `<.ai_panel_overlay />`.
  ## Examples
      <.floating_ai_button id="aibuttonid" />
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :type, :string, required: true, doc: "button | link"
  attr :patch, :string, default: nil, doc: "use with type=\"link\""
  attr :navigate, :string, default: nil, doc: "use with type=\"link\""
  attr :replace, :boolean, default: false, doc: "use with type=\"link\""
  attr :rest, :global

  def floating_ai_button(%{type: "link"} = assigns) do
    ~H"""
    <.link
      id={@id}
      class={[
        floating_ai_button_class(),
        @class
      ]}
      patch={@patch}
      navigate={@navigate}
      replace={@replace}
      {@rest}
    >
      <.ai_spots />
      <span class={floating_ai_button_text_class()}>AI</span>
    </.link>
    """
  end

  def floating_ai_button(%{type: "button"} = assigns) do
    ~H"""
    <button
      id={@id}
      class={[
        floating_ai_button_class(),
        @class
      ]}
      {@rest}
    >
      <.ai_spots />
      <span class={floating_ai_button_text_class()}>AI</span>
    </button>
    """
  end

  defp floating_ai_button_class do
    [
      "fixed bottom-4 left-4 flex items-center justify-center gap-2 p-2 rounded-full bg-ltrn-ai-lightest",
      "shadow-lg overflow-hidden hover:shadow-ltrn-ai-spectrum-main",
      "transition-[box-shadow]"
    ]
  end

  defp floating_ai_button_text_class,
    do: "font-display font-black text-base text-ltrn-ai-dark"

  @doc """
  Renders an AI action bar.
  ## Examples
      <.ai_action_bar>
        <.action />
      </.ai_action_bar>
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :name, :string, default: "LantternAI"

  slot :inner_block, required: true

  def ai_action_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex items-center gap-2 p-2 rounded bg-ltrn-ai-lightest",
        "shadow-lg overflow-hidden",
        @class
      ]}
    >
      <.ai_spots />
      <span class="font-display font-bold text-sm text-ltrn-ai-dark"><%= @name %></span>
      <div class="flex-1 flex items-center gap-6 justify-end pr-2">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders an AI content indicator.
  """
  attr :class, :any, default: nil

  def ai_content_indicator(assigns) do
    ~H"""
    <div class={["w-4 h-4 rounded-full -rotate-45 ltrn-ai-indicator-bg", @class]}></div>
    """
  end

  # helpers

  defp ai_spots(assigns) do
    ~H"""
    <div class="relative w-6 h-6">
      <div class="absolute w-full h-full rounded-full bg-ltrn-ai-spectrum-1 blur ltrn-ai-spot-1-anim">
      </div>
      <div class="absolute w-full h-full rounded-full bg-ltrn-ai-spectrum-main blur"></div>
      <div class="absolute w-full h-full rounded-full bg-ltrn-ai-spectrum-2 blur ltrn-ai-spot-2-anim">
      </div>
      <div class="absolute w-full h-full rounded-full bg-ltrn-ai-spectrum-3 blur ltrn-ai-spot-3-anim">
      </div>
      <div class="absolute w-full h-full rounded-full bg-ltrn-ai-spectrum-4 blur ltrn-ai-spot-4-anim">
      </div>
      <div class="relative w-full h-full rounded-full border-4 border-white shadow"></div>
    </div>
    """
  end
end
