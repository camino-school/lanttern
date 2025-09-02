defmodule LantternWeb.Attachments.AttachmentRenderComponent do
  @moduledoc """
  Creates an attachment area UI.

  ### Supported contexts:
  - message attachments (use `message_id` assign)

  ### Supported attrs/assigns

  - `title` (optional, string)
  - `class` (optional, any)
  - `current_user` (optional, `%User{}`) - required when `allow_editing` is `true`
  - `message_id` (optional, integer) - view supported contexts above
  - `shared_with_student` (optional, boolean) - used with student cycle info and moment card. View supported contexts above

  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [swap: 3]

  alias Lanttern.Assessments
  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.MessageBoard
  alias Lanttern.SupabaseHelpers

  # shared

  import LantternWeb.AttachmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[@class, if(@attachments_length == 0, do: "hidden")]}>
      <div :if={@attachments_length > 0}>
        <ul id={@id} phx-update="stream" class={@class}>
          <li
            :for={{dom_id, {attachment, i}} <- @streams.attachments}
            id={dom_id}
            class="flex items-center gap-4 my-4 mx-0"
          >
            <div class="flex-1 min-w-0 bg-white shadow-lg rounded">
              <%= if(attachment.is_external) do %>
                <div class="m-4 rounded">
                  <div class="text-sm text-gray-500 mb-2">
                    {gettext("External link")}
                  </div>
                  <a
                    href={attachment.link}
                    target="_blank"
                    class="inline-flex items-center space-x-2 text-sm font-semibold underline hover:text-ltrn-subtle"
                  >
                    <%!-- <img src="/images/icons/google-drive.png" alt="Google Drive Icon" class="h-5 w-5" /> --%>
                    <.icon name="hero-link" class="w-6 h-6" />
                    <span>{attachment.name}</span>
                  </a>
                </div>
              <% else %>
                <.link
                  phx-click={
                    JS.push("signed_url", value: %{"url" => attachment.link}, target: @myself)
                  }
                  class="flex items-center w-full bg-white gap-4 rounded"
                  target="_blank"
                >
                  <div class="flex flex-col flex-grow min-w-0 m-4">
                    <strong class="font-semibold hover:text-ltrn-subtle truncate">
                      {Path.basename(attachment.name)}
                    </strong>
                    <span class="text-sm text-gray-500">
                      {file_type_label(attachment.name)}
                    </span>
                  </div>
                  <%= if is_image_url?(attachment.link) do %>
                    <img
                      src={get_thumbnail(attachment.link)}
                      alt="Imagem"
                      class="h-24 w-24 object-cover rounded-r"
                    />
                  <% end %>
                </.link>
              <% end %>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:title, nil)
      |> assign(:class, nil)
      |> assign(:attachment, nil)
      |> assign(:shared_with_student, nil)
      |> stream_configure(
        :attachments,
        dom_id: fn {attachment, _i} -> "attachment-#{attachment.id}" end
      )
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
    |> assign_type()
    |> stream_attachments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_type(%{assigns: %{message_id: _}} = socket),
    do: assign(socket, :type, :message_attachments)

  defp stream_attachments(%{assigns: %{type: :message_attachments, message_id: id}} = socket) do
    attachments = Attachments.list_attachments(message_id: id)
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  def handle_event("signed_url", %{"url" => url}, socket) do
    case SupabaseHelpers.create_signed_url(url) do
      {:ok, external} ->
        {:noreply, push_event(socket, "open_external", %{url: external})}

      {:error, :invalid_object_key} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid URL"))}
    end
  end

  defp get_thumbnail(url) do
    case SupabaseHelpers.create_signed_url(url) do
      {:ok, external} -> external
      {:error, :invalid_object_key} -> ""
    end
  end

  defp is_image_url?(url) when is_binary(url) do
    image_extensions = ~w(.png .jpg .jpeg .gif .bmp .webp .svg)

    Enum.any?(image_extensions, fn ext ->
      String.ends_with?(String.downcase(url), ext)
    end)
  end

  defp is_image_url?(_), do: false

  defp file_type_label(url) do
    ext = url |> Path.extname() |> String.trim_leading(".") |> String.upcase()
    "#{ext} image"
  end
end
