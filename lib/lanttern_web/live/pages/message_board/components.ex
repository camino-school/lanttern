defmodule LantternWeb.MessageBoard.Components do
  @moduledoc """
  Shared function components related to `MessageBoard` context
  """
  use Phoenix.Component
  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  alias Lanttern.MessageBoard.MessageV2, as: Message

  @doc """
  Renders message board cards for admin
  """
  attr :message, Message, required: true
  attr :on_delete, JS, default: nil
  attr :edit_patch, :string, default: nil
  attr :id, :any, default: nil

  def message_card_admin(assigns) do
    ~H"""
    <div
      id={"message-#{@message.id}"}
      class="aspect-square relative bg-white/90 backdrop-blur-sm rounded-md border border-l-12 border-ltrn-lightest shadow-xl z-20"
      style={"
       border-color: var(--color-ltrn-lightest);
       border-left-color: #{@message.color};
       border-left-opacity: 1;
       border-opacity: 0.5;
      "}
    >
      <%= if @message.cover && @message.cover != "" && !@message.archived_at do %>
        <div class="w-full h-9/16 overflow-hidden rounded-tr-md">
          <img
            src={@message.cover || "/placeholder.svg"}
            alt={@message.name}
            class="w-full h-full aspect-video object-cover"
          />
        </div>
      <% end %>
      <div class={
        if(@message.cover && @message.cover != "" && !@message.archived_at,
          do: "pt-2 px-6 pb-6 pl-4",
          else: "p-6 pl-4"
        )
      }>
        <div class="flex items-start gap-4">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <h3
                class="font-display font-black text-xl line-clamp-4"
                title={@message.name}
              >
                {@message.name}
              </h3>
            </div>
          </div>
        </div>
        <div class="absolute bottom-6 right-6 flex items-center gap-2">
          <.action
            :if={@on_delete && @message.archived_at}
            type="button"
            phx-click={@on_delete}
            icon_name="hero-x-mark-mini"
            theme="subtle"
            size="sm"
            data-confirm={gettext("Are you sure? This action cannot be undone.")}
            title={gettext("Delete")}
          >
          </.action>
          <.action
            :if={@edit_patch && !@message.archived_at}
            id={"message-#{@message.id}-edit"}
            class="inline-flex hover:text-gray-600"
            type="link"
            patch={@edit_patch}
            theme="subtle"
            icon_name="hero-pencil-mini"
          >
          </.action>
        </div>
      </div>
    </div>
    """
  end
end
