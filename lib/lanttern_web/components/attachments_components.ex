defmodule LantternWeb.AttachmentsComponents do
  @moduledoc """
  Shared function components related to `Attachments` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.OverlayComponents

  alias Lanttern.Attachments.Attachment

  @doc """
  Renders an attachment card.
  """
  attr :attachment, Attachment, required: true
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :on_signed_url, :any, required: true
  slot :inner_block

  def attachment_card(assigns) do
    ~H"""
    <.card_base id={@id} class={["p-6", @class]}>
      <%= if(@attachment.is_external) do %>
        <.badge>{gettext("External link")}</.badge>
        <a
          href={@attachment.link}
          target="_blank"
          class="block mt-2 text-sm underline hover:text-ltrn-subtle"
        >
          {@attachment.name}
        </a>
      <% else %>
        <.badge theme="cyan">{gettext("Upload")}</.badge>
        <.link
          phx-click={@on_signed_url.(@attachment.link)}
          class="block mt-2 text-sm underline hover:text-ltrn-subtle"
          target="_blank"
        >
          {@attachment.name}
        </.link>
      <% end %>
      {render_slot(@inner_block)}
    </.card_base>
    """
  end

  @doc """
  Renders an assessment point entry badge.
  """
  attr :attachments, :any, required: true, doc: "list or stream of attachments."
  attr :allow_editing, :boolean, default: false
  attr :attachments_length, :integer, default: nil, doc: "required when edit is allowed"
  attr :on_move_up, :any, default: nil, doc: "function. required when edit is allowed"
  attr :on_move_down, :any, default: nil, doc: "function. required when edit is allowed"
  attr :on_edit, :any, default: nil, doc: "function. required when edit is allowed"
  attr :on_remove, :any, default: nil, doc: "function. required when edit is allowed"
  attr :on_signed_url, :any, required: true, doc: "function. required when open signed link"

  attr :on_toggle_share, :any,
    default: nil,
    doc: "function. If present, will render a toggle button based on attachment `is_shared`."

  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def attachments_list(assigns) do
    attachments = normalize_attachments(assigns)
    assigns = assign(assigns, :attachments, attachments)

    ~H"""
    <ul id={@id} phx-update="stream" class={@class}>
      <li
        :for={{dom_id, {attachment, i}} <- @attachments}
        id={dom_id}
        class="flex items-center gap-4 mt-4"
      >
        <%= if @allow_editing do %>
          <.sortable_card
            is_move_up_disabled={i == 0}
            on_move_up={@on_move_up.(i)}
            is_move_down_disabled={i + 1 == @attachments_length}
            on_move_down={@on_move_down.(i)}
            class="flex-1 min-w-0"
          >
            <div class="flex items-center gap-4">
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
                <%= if(attachment.is_external) do %>
                  <.badge>{gettext("External link")}</.badge>
                  <a
                    href={attachment.link}
                    target="_blank"
                    class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                  >
                    {attachment.name}
                  </a>
                <% else %>
                  <.badge theme="cyan">{gettext("Upload")}</.badge>
                  <.link
                    phx-click={@on_signed_url.(attachment.link)}
                    class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                    target="_blank"
                  >
                    {attachment.name}
                  </.link>
                <% end %>
                <div :if={@on_toggle_share} class="flex items-center gap-2 mt-6">
                  <.toggle
                    enabled={attachment.is_shared}
                    theme="student"
                    phx-click={@on_toggle_share.(attachment.id, i)}
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
          </.sortable_card>
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
          <div class="flex-1 min-w-0 p-4 rounded-sm bg-white shadow-lg">
            <%= if(attachment.is_external) do %>
              <.badge>{gettext("External link")}</.badge>
              <a
                href={attachment.link}
                target="_blank"
                class="block mt-2 text-sm underline hover:text-ltrn-subtle"
              >
                {attachment.name}
              </a>
            <% else %>
              <.badge theme="cyan">{gettext("Upload")}</.badge>
              <.link
                phx-click={@on_signed_url.(attachment.link)}
                class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                target="_blank"
              >
                {attachment.name}
              </.link>
            <% end %>
          </div>
        <% end %>
      </li>
    </ul>
    """
  end

  # normalize all attachments to indexed LiveStream format {dom_id, {attachment, index}}

  defp normalize_attachments(%{attachments: %Phoenix.LiveView.LiveStream{} = attachments}),
    do: attachments

  defp normalize_attachments(%{attachments: attachments, id: component_id}) do
    attachments
    |> Enum.with_index()
    |> Enum.map(fn {attachment, i} ->
      {"#{component_id}-attachment-#{attachment.id}", {attachment, i}}
    end)
  end
end
