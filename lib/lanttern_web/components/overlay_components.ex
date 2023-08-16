defmodule LantternWeb.OverlayComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

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
      <div
        id="slide-over-backdrop"
        class="fixed inset-0 bg-white bg-opacity-75 transition-opacity hidden"
      >
      </div>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <div
              id="slide-over-panel"
              class="pointer-events-auto w-screen max-w-xl py-6 transition-translate hidden"
            >
              <div class="flex h-full flex-col divide-y divide-gray-200 bg-white shadow-xl rounded-l">
                <div class="flex min-h-0 flex-1 flex-col overflow-y-scroll py-6">
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
                <div class="flex flex-shrink-0 justify-end px-4 py-4">
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
end
