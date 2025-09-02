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
  <.card_base id={@id} class={["p-6 pl-4 border border-l-12 border-ltrn-lightest shadow-xl z-20", @class]} style={"border-color: var(--color-ltrn-lightest); border-left-color: #{@message.color};"}>
    <div class="flex items-start justify-between gap-4">
      <h5 class="flex-1 font-display font-black text-xl" inner-html={} title={@message.name}>
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

  def message_card_admin(assigns) do
    ~H"""
    <div
      id={"message-#{@message.id}"}
      class="aspect-square relative bg-white/90 backdrop-blur-sm rounded-md border border-l-12 border-ltrn-lightest shadow-xl z-20 cursor-pointer"
      style={"
       border-color: var(--color-ltrn-lightest);
       border-left-color: #{@message.color};
       border-left-opacity: 1;
       border-opacity: 0.5;
      "}
    >
      <%= if @message.cover && @message.cover != "" do %>
        <div class="w-full h-9/16 overflow-hidden rounded-tr-md">
          <img
            src={@message.cover || "/placeholder.svg"}
            alt={@message.name}
            class="w-full h-full aspect-video object-cover"
          />
        </div>
      <% end %>
      <div class="p-6 pl-4">
        <div class="flex items-start gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h3 class={"font-display font-black text-xl" <> (if @message.cover && @message.cover != "", do: " truncate", else: "")} title={@message.name}>
                {@message.name}
              </h3>
            </div>
          </div>
        </div>
        <%= if @mode == "admin" do %>
          <div class="absolute bottom-6 right-6">
            <.action
              :if={@edit_patch}
              id={"message-#{@message.id}-edit"}
              class="inline-flex hover:text-gray-600 group-hover:text-slate-700"
              type="link"
              patch={@edit_patch}
              theme="subtle"
              icon_name="hero-pencil-mini"
            >
            </.action>
          </div>
        <% else %>
          <p class={"text-gray-600 text-sm mb-4 " <> (if @message.cover && @message.cover != "", do: "line-clamp-2 truncate", else: "") } title={@message.subtitle}>
            {@message.subtitle}
          </p>
          <div class="absolute bottom-3 right-4">
            <button class="w-full flex items-center justify-between gap-[14px] transition-colors group-hover:text-blue-600">
              <span class="font-display font-bold text-base" phx-click="card_lookout" phx-value-id={@message.id}>
                {gettext("Find out more")}&nbsp
              </span>
              <.icon
                name="hero-arrow-right"
                class="w-6 h-6 mapping-3 transition-transform group-hover:translate-x-1"
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
      class="overflow-auto-x aspect-square max-w-80 bg-white/90 backdrop-blur-sm rounded-sm border border-l-12 border-ltrn-lightest group cursor-pointer shadow-xl z-20"
      style={"border-color: var(--color-ltrn-lightest); border-left-color: #{@message.color};"}
    >
      <%= if @message.cover && @message.cover != "" do %>
        <div class="w-full h-9/16 overflow-hidden rounded-tr-md">
          <img
            src={@message.cover || "/placeholder.svg"}
            alt={@message.name}
          />
        </div>
      <% end %>
      <div class="p-6 pl-4">
        <div class="flex items-start">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h3 class={"font-display font-black text-xl" <> (if @message.cover && @message.cover != "", do: " truncate", else: "")} title={@message.name}>
                {@message.name}
              </h3>
            </div>
            <p class={"text-gray-600 text-sm mb-4 " <> (if @message.cover && @message.cover != "", do: "line-clamp-2 truncate", else: "") } title={@message.subtitle}>
              {@message.subtitle}
            </p>
          </div>
        </div>
        <div class="absolute bottom-3 right-4">
          <button class="w-full flex items-center justify-between gap-[14px] hover:text-slate-700 transition-colors group-hover:text-slate-400">
            <span class="font-display font-bold  text-sm" phx-click="card_lookout" phx-value-id={@message.id}>
              {gettext("See more")}
            </span>
            <.icon
              name="hero-arrow-right"
              class="w-6 h-6 mapping-3"
            />
          </button>
        </div>
      </div>
    </div>
    """
  end
end
