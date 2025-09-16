defmodule LantternWeb.MessageBoard.MessageBoardGridComponent do
  @moduledoc """
  LiveComponent for rendering a grid of message board cards.

  Displays messages in a responsive grid layout and handles card interactions.
  """
  use LantternWeb, :live_component

  import LantternWeb.MessageBoard.Components

  @impl true
  def handle_event("card_lookout", %{"id" => id}, socket) do
    send(self(), {:card_lookout, id})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-8">
      <div :if={@show_title}>
        <h2 class="flex items-center gap-2 font-display font-black text-2xl">
          {gettext("Message board")}
        </h2>
      </div>

      <%= for section <- @sections do %>
        <div class="space-y-4 px-0">
          <!-- Mobile-only full-bleed carousel -->
          <div class="md:hidden -mx-6">
            <div>
              <h3 class="text-lg font-bold mb-1 pl-6">
                {section.name}
              </h3>
            </div>

            <div
              id={"section-#{section.id}-messages-wrapper-mobile"}
              class="relative"
              style="overflow: visible;"
            >
              <div
                id={"section-#{section.id}-messages-mobile"}
                class="hide-scrollbar snap-x snap-mandatory overflow-x-auto flex gap-4 pl-0"
              >
                <!-- spacer to offset first card by 16px on mobile -->
                <div class="flex-shrink-0" style="width:10px;" aria-hidden="true"></div>
                <%= for message <- section.messages do %>
                  <div
                    id={"section-#{section.id}-message-#{message.id}-mobile"}
                    class="snap-center flex-shrink-0 w-[80vw] max-w-[320px] scroll-smooth"
                    style="overflow: visible;"
                  >
                    <div class="mt-1 mb-9">
                      <!-- mobile bottom gutter so shadow is visible -->
                      <.message_card
                        id={"sect-#{section.id}-msg-#{message.id}-card"}
                        message={message}
                        class="mx-0"
                      >
                        <div :if={@show_see_more} class="absolute bottom-3 right-4">
                          <button
                            class="w-full flex items-center justify-between gap-[14px] transition-colors hover:text-ltrn-subtle group"
                            phx-click="card_lookout"
                            phx-value-id={message.id}
                          >
                            <span class="font-display font-bold text-sm">
                              {gettext("See more")}
                            </span>
                            <.icon
                              name="hero-arrow-right"
                              class="w-6 h-6 mapping-3 transition-transform group-hover:translate-x-1"
                            />
                          </button>
                        </div>
                      </.message_card>
                    </div>
                  </div>
                <% end %>
                <!-- trailing spacer to balance the initial offset -->
                <div class="flex-shrink-0" style="width:10px;" aria-hidden="true"></div>
              </div>

              <div class="mt-0 flex items-center justify-center space-x-2 indicators">
                <%= for message <- section.messages do %>
                  <a
                    href={"#section-#{section.id}-message-#{message.id}-mobile"}
                    class="block w-2 h-2 rounded-full bg-white focus:outline-none indicator-dot"
                    style="border: 1px solid #94A3B8;"
                    aria-label={gettext("Go to message %{id}", id: message.id)}
                  >
                  </a>
                <% end %>
              </div>

              <style>
                <%= for message <- section.messages do %>
                  #section-<%= section.id %>-messages-wrapper-mobile:has(#section-<%= section.id %>-message-<%= message.id %>-mobile:target) .indicators a[href="#section-<%= section.id %>-message-<%= message.id %>-mobile"] {
                      background: <%= message.color || "#94A3B8" %>;
                      border-color: <%= message.color || "#94A3B8" %>;
                    }
                <% end %>
              </style>
            </div>
          </div>

    <!-- Desktop/tablet: use existing grid within responsive container -->
          <div class="hidden md:block">
            <div>
              <h3 class="text-lg font-bold mb-1 px-6 md:px-0">
                {section.name}
              </h3>
            </div>

            <div
              id={"section-#{section.id}-messages-wrapper"}
              class="relative"
              style="overflow: visible;"
            >
              <div
                id={"section-#{section.id}-messages"}
                class="hide-scrollbar ml-0 snap-none md:overflow-visible md:grid md:grid-cols-2 lg:grid-cols-3 md:gap-4 gap-4 md:px-0"
              >
                <%= for message <- section.messages do %>
                  <div
                    id={"section-#{section.id}-message-#{message.id}"}
                    class="md:static md:w-auto md:max-w-none"
                    style="overflow: visible;"
                  >
                    <div class="mt-0 mb-1">
                      <.message_card
                        id={"sect-#{section.id}-msg-#{message.id}-responsive-card"}
                        message={message}
                        class="mx-0"
                      >
                        <div :if={@show_see_more} class="absolute bottom-3 right-4">
                          <button
                            class="w-full flex items-center justify-between gap-[14px] transition-colors hover:text-ltrn-subtle group"
                            phx-click="card_lookout"
                            phx-value-id={message.id}
                          >
                            <span class="font-display font-bold text-sm">
                              {gettext("See more")}
                            </span>
                            <.icon
                              name="hero-arrow-right"
                              class="w-6 h-6 mapping-3 transition-transform group-hover:translate-x-1"
                            />
                          </button>
                        </div>
                      </.message_card>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
