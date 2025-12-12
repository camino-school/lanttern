defmodule LantternWeb.AttachmentsComponents do
  @moduledoc """
  Shared function components related to `Attachments` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.OverlayComponents

  alias LantternWeb.Attachments.AttachmentViewComponent

  @doc """
  Renders an attachment list.
  """
  attr :attachments, :any, required: true, doc: "list or stream of attachments."
  attr :allow_editing, :boolean, default: false
  attr :attachments_length, :integer, default: nil, doc: "required when edit is allowed"

  attr :sortable_event, :string,
    default: nil,
    doc: "the value used in `data-sortable-event`. required when edit is allowed"

  attr :on_edit, :any, default: nil, doc: "function. required when edit is allowed"
  attr :on_remove, :any, default: nil, doc: "function. required when edit is allowed"

  attr :on_toggle_share, :any,
    default: nil,
    doc: "function. If present, will render a toggle button based on attachment `is_shared`."

  attr :id, :string, required: true
  attr :class, :any, default: nil

  def attachments_list(assigns) do
    attachments = normalize_attachments(assigns)
    assigns = assign(assigns, :attachments, attachments)

    ~H"""
    <ul
      id={@id}
      phx-update="stream"
      class={@class}
      phx-hook="Sortable"
      data-sortable-handle=".sortable-handle"
      data-sortable-event={@sortable_event}
    >
      <li
        :for={{dom_id, attachment} <- @attachments}
        id={"#{@id}-#{dom_id}"}
        class="flex items-center gap-4 mt-4"
      >
        <%= if @allow_editing do %>
          <.draggable_card class="flex-1 flex items-center gap-4 min-w-0 px-4 py-6">
            <div class="flex-1 flex items-center gap-4">
              <button
                type="button"
                phx-hook="CopyToClipboard"
                data-clipboard-text={"[#{attachment.name}](#{attachment.link})"}
                id={"clipboard-#{dom_id}"}
                class={[
                  "group relative shrink-0 p-1 rounded-full text-ltrn-subtle hover:bg-ltrn-lighter",
                  "[&.copied-to-clipboard]:text-ltrn-primary [&.copied-to-clipboard]:bg-ltrn-mesh-cyan"
                ]}
              >
                <.icon
                  name="hero-square-2-stack"
                  class="block group-[.copied-to-clipboard]:hidden w-6 h-6"
                />
                <.icon name="hero-check hidden group-[.copied-to-clipboard]:block" class="w-6 h-6" />
                <.tooltip>{gettext("Copy attachment link markdown")}</.tooltip>
              </button>
              <div class="flex-1 min-w-0">
                <.live_component
                  module={AttachmentViewComponent}
                  id={"#{@id}-#{dom_id}-view"}
                  attachment={attachment}
                  no_card
                  show_upload_and_link_badges
                />
                <div :if={@on_toggle_share} class="flex items-center gap-2 mt-6">
                  <.toggle
                    enabled={attachment.is_shared}
                    theme="student"
                    phx-click={@on_toggle_share.(attachment.id)}
                  />
                  <span :if={attachment.is_shared} class="text-ltrn-student-dark">
                    {gettext("Shared with students and guardians")}
                  </span>
                  <span :if={!attachment.is_shared} class="text-ltrn-subtle">
                    {gettext("Share with students and guardians")}
                  </span>
                </div>
              </div>
            </div>
          </.draggable_card>
          <.menu_button id={attachment.id}>
            <:item
              :if={attachment.is_external}
              id={"edit-attachment-#{attachment.id}"}
              text={gettext("Edit")}
              on_click={@on_edit.(attachment.id)}
            />
            <:item
              id={"remove-attachment-#{attachment.id}"}
              text={gettext("Remove")}
              on_click={@on_remove.(attachment.id)}
              theme="alert"
              confirm_msg={gettext("Are you sure? This action cannot be undone.")}
            />
          </.menu_button>
        <% else %>
          <.live_component
            module={AttachmentViewComponent}
            id={"#{@id}-#{dom_id}-view"}
            attachment={attachment}
            class="flex-1 min-w-0"
          />
        <% end %>
      </li>
    </ul>
    """
  end

  # normalize all attachments to LiveStream format {dom_id, attachment}

  defp normalize_attachments(%{attachments: %Phoenix.LiveView.LiveStream{} = attachments}),
    do: attachments

  defp normalize_attachments(%{attachments: attachments, id: component_id}) do
    attachments
    |> Enum.map(fn attachment ->
      {"#{component_id}-attachment-#{attachment.id}", attachment}
    end)
  end
end
