defmodule LantternWeb.Attachments.AttachmentViewComponent do
  @moduledoc """
  Creates a view-only attachment list.

  Handles presigned URL fetching

  ### Supported attrs/assigns

  - `attachment` (required, %Attachment{})
  - `no_card` (optional, boolean) - render without card container
  - `show_upload_and_link_badges` (optional, boolean)
  - `class` (optional, any)

  ### Supported slots

  - `inner_block` (optional, any)

  """

  use LantternWeb, :live_component

  alias Lanttern.SupabaseHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        if(!@no_card, do: [card_base_classes(), "p-6"]),
        @class
      ]}
    >
      <.badge :if={!@show_upload_and_link_badges}>{gettext("Attachment")}</.badge>
      <%= if(@attachment.is_external) do %>
        <.badge :if={@show_upload_and_link_badges}>{gettext("Link")}</.badge>
        <a
          href={@attachment.link}
          target="_blank"
          class="block mt-2 text-sm underline hover:text-ltrn-subtle"
        >
          {@attachment.name}
        </a>
      <% else %>
        <.badge :if={@show_upload_and_link_badges} theme="cyan">{gettext("Upload")}</.badge>
        <a
          :if={@attachment.signed_link}
          href={@attachment.signed_link}
          class="block mt-2 text-sm underline hover:text-ltrn-subtle"
          target="_blank"
        >
          {@attachment.name}
        </a>
        <div
          :if={!@attachment.signed_link && !@attachment.signed_link_error}
          class="flex items-center gap-2 mt-2 text-sm text-ltrn-subtle"
        >
          <.spinner />
          <span>
            {gettext("Loading %{attachment}", attachment: @attachment.name)}
          </span>
        </div>
        <div
          :if={@attachment.signed_link_error}
          class="flex items-center gap-2 mt-2 text-sm text-ltrn-subtle"
        >
          <.icon name="hero-exclamation-circle-mini" />
          <span>
            {gettext("Something went wrong while fetching the attachment")}
          </span>
        </div>
      <% end %>
      {if @inner_block, do: render_slot(@inner_block)}
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:inner_block, nil)
      |> assign(:no_card, false)
      |> assign(:show_upload_and_link_badges, false)
      |> assign(:class, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> fetch_presigned_url()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp fetch_presigned_url(%{assigns: %{attachment: %{is_external: false} = attachment}} = socket) do
    socket
    |> start_async(:fetch_presigned_url, fn ->
      case SupabaseHelpers.create_signed_url(attachment.link) do
        {:ok, url} ->
          %{attachment | signed_link: url}

        {:error, _error} ->
          %{attachment | signed_link: nil, signed_link_error: true}
      end
    end)
  end

  defp fetch_presigned_url(socket), do: socket

  # async handlers

  @impl true
  def handle_async(:fetch_presigned_url, {:ok, attachment}, socket) do
    {:noreply, assign(socket, :attachment, attachment)}
  end

  def handle_async(:fetch_presigned_url, {:exit, _reason}, socket) do
    {:noreply, socket}
  end
end
