defmodule LantternWeb.MessageBoard.Components do
  @moduledoc """
  Shared function components related to `MessageBoard` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  alias Lanttern.MessageBoard.Message

  @doc """
  Renders message board cards.
  """
  attr :message, Message,
    required: true,
    doc: "expects `classes` preload when `show_sent_to` is true"

  attr :edit_patch, :string, default: nil
  attr :on_unarchive, JS, default: nil
  attr :on_delete, JS, default: nil
  attr :show_sent_to, :boolean, default: false
  attr :class, :any, default: nil
  attr :id, :any, default: nil
  attr :tz, :string, default: nil

  def message_board_card(assigns) do
    ~H"""
    <.card_base id={@id} class={["p-6", @class]}>
      <div class="flex items-start justify-between gap-4">
        <h5 class="flex-1 font-display font-black text-xl" inner-html={}>
          {Phoenix.HTML.raw(Earmark.as_html!(@message.name, inner_html: true))}
        </h5>
        <.action
          :if={@on_unarchive}
          type="button"
          phx-click={@on_unarchive}
          icon_name="hero-arrow-up-tray-mini"
          data-confirm={gettext("Are you sure?")}
        >
          {gettext("Unarchive")}
        </.action>
        <.action
          :if={@on_delete}
          type="button"
          phx-click={@on_delete}
          icon_name="hero-x-mark-mini"
          theme="alert"
          data-confirm={gettext("Are you sure? This action cannot be undone.")}
        >
          {gettext("Delete")}
        </.action>
        <.action :if={@edit_patch} type="link" patch={@edit_patch} icon_name="hero-pencil-mini">
          {gettext("Edit")}
        </.action>
        <div
          :if={@message.is_pinned && is_nil(@message.archived_at)}
          class="flex items-center justify-center w-6 h-6 rounded-full bg-ltrn-mesh-cyan"
          title={gettext("Pinned message")}
        >
          <%!-- there's no pin in Hero Icons. I imported one from https://tabler.io/icons --%>
          <.icon name="hero-pin-mini" class="text-ltrn-primary" />
        </div>
      </div>
      <%!-- <div class="flex flex-row-reverse sm:flex-row items-center gap-2 mt-2 text-xs">
        <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
        <div class="flex-1 sm:flex sm:items-center sm:gap-2">
          <%= format_by_locale(@message.inserted_at, @tz) %>
          <%= if @message.inserted_at != @message.updated_at do %>
            <div class="mt-1 sm:mt-0 text-ltrn-subtle">
              <%= "(#{gettext("Updated")} #{format_by_locale(@message.updated_at, @tz)})" %>
            </div>
          <% end %>
        </div>
      </div> --%>
      <div
        :if={@show_sent_to}
        class="flex flex-row-reverse sm:flex-row items-center gap-2 mt-2 text-xs"
      >
        <%= if @message.send_to == "classes" do %>
          <.icon name="hero-users-mini" class="w-5 h-5 text-ltrn-subtle" />
          <.badge :for={class <- @message.classes}>{class.name}</.badge>
        <% else %>
          <.icon name="hero-user-group-mini" class="w-5 h-5 text-ltrn-subtle" />
          <.badge>{gettext("Sent to all school")}</.badge>
        <% end %>
      </div>
      <.markdown text={@message.content} class="mt-10" />
    </.card_base>
    """
  end

  @doc """
  Renders message board cards.
  """
  attr :message, Message, required: true
  attr :on_delete, JS, default: nil
  attr :edit_patch, :string, default: nil

  attr :mode, :string,
    required: true,
    doc: "expects `mode` defined when show in admin and student/guardian view."

  def card_message(assigns) do
    ~H"""
    <div
      id={"message-#{@message.id}"}
      class="aspect-square relative bg-white/90 backdrop-blur-sm shadow-sm hover:shadow-lg transition-all duration-200 rounded-sm border-l-12 group cursor-pointer"
      style={"border-color: #{@message.color}"}
    >
      <%= if @message.cover && @message.cover != "" do %>
        <div class="w-full h-3/5 overflow-hidden rounded-tr-lg">
          <img
            src={@message.cover || "/placeholder.svg"}
            alt={@message.name}
            class="w-full h-full object-cover"
          />
        </div>
      <% end %>
      <div class="p-6">
        <div class="flex items-start gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h3 class="font-bold text-lg text-gray-800 truncate">
                {@message.name}
              </h3>
            </div>
            <p class="text-gray-600 text-sm mb-4 line-clamp-2">
              {@message.subtitle}
            </p>
          </div>
        </div>
        <%= if @mode == "admin" do %>
          <div class="absolute bottom-6 right-6">
            <.action
              :if={@edit_patch}
              id={"message-#{@message.id}-edit"}
              class="inline-flex hover:text-gray-600 group-hover:text-gray-900"
              type="link"
              patch={@edit_patch}
              icon_name="hero-pencil-mini"
            ></.action>
          </div>
        <% else %>
          <div class="absolute bottom-3 right-6">
            <button class="w-full flex justify-between items-center text-gray-900 hover:text-gray-900 transition-colors group-hover:text-blue-600">
              <span class="font-medium" phx-click="card_lookout" phx-value-id={@message.id}>
                {gettext("Find out more")}&nbsp
              </span>
              <.icon
                name="hero-arrow-right"
                class="w-5 h-4 mapping-3 transition-transform group-hover:translate-x-1
              "
              />
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def message_card(assigns) do
    ~H"""
    <div
      class="bg-white/90 backdrop-blur-sm shadow-sm hover:shadow-lg transition-all duration-200 rounded-sm border-l-12 group cursor-pointer"
      style={"border-color: #{@message.color}"}
    >
      <%= if @message.cover && @message.cover != "" do %>
        <div class="rounded-tr-lg">
          <img
            src={@message.cover || "/placeholder.svg"}
            alt={@message.name}
          />
        </div>
      <% end %>
      <div class="p-6">
        <div class="flex items-start">

          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h3 class="font-bold text-lg text-gray-800 truncate">
                {@message.name}
              </h3>
            </div>
            <p class="text-gray-600 text-sm mb-4 line-clamp-2">
              {@message.subtitle}
            </p>
          </div>
        </div>
        <div class="absolute bottom-3 right-6">
          <button class="w-full flex justify-between items-center text-gray-900 hover:text-gray-900 transition-colors group-hover:text-blue-600">
            <span class="font-medium" phx-click="card_lookout" phx-value-id={@message.id}>
              {gettext("Find out more")}&nbsp
            </span>
            <.icon
              name="hero-arrow-right"
              class="w-5 h-4 mapping-3 transition-transform group-hover:translate-x-1
              "
            />
          </button>
        </div>
      </div>
    </div>
    """
  end
end
