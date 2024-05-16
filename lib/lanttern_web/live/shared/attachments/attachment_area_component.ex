defmodule LantternWeb.Attachments.AttachmentAreaComponent do
  @moduledoc """
  Creates an attachment area UI.

  Supports only notes attachments (for now).
  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [swap: 3]

  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.Notes

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <ul :if={@attachments_length > 0} id="attachments-list" phx-update="stream">
        <li
          :for={{dom_id, {attachment, i}} <- @streams.attachments}
          id={dom_id}
          class="flex items-center gap-4 mb-4"
        >
          <.sortable_card
            is_move_up_disabled={i == 0}
            on_move_up={
              JS.push("reorder_attachments",
                value: %{from: i, to: i - 1},
                target: @myself
              )
            }
            is_move_down_disabled={i + 1 == @attachments_length}
            on_move_down={
              JS.push("reorder_attachments",
                value: %{from: i, to: i + 1},
                target: @myself
              )
            }
            class="flex-1"
          >
            <a href={attachment.link} target="_blank" class="flex-1 group mt-2 text-sm">
              <%= attachment.name %>
              <span class="block mt-2 text-xs underline group-hover:text-ltrn-subtle">
                <%= attachment.link %>
              </span>
            </a>
          </.sortable_card>
          <.icon_button
            name="hero-trash"
            theme="ghost"
            rounded
            sr_text={gettext("Remove attachment")}
            phx-click="delete"
            phx-target={@myself}
            phx-value-id={attachment.id}
            data-confirm={gettext("Are you sure? This action cannot be undone.")}
          />
        </li>
      </ul>
      <%= if @is_adding_external do %>
        <div class="p-4 border border-dashed border-ltrn-subtle rounded bg-white shadow-lg">
          <.form
            for={@external_form}
            id="external-attachment-form"
            phx-target={@myself}
            phx-change="validate_external"
            phx-submit="create_external"
          >
            <.input
              field={@external_form[:name]}
              type="text"
              label={gettext("Attachment name")}
              class="mb-6"
              phx-debounce="1500"
            />
            <.input
              field={@external_form[:link]}
              type="text"
              label={gettext("Link")}
              class="mb-6"
              phx-debounce="1500"
            />
            <div class="flex justify-end gap-2">
              <.button
                type="button"
                theme="ghost"
                phx-click="cancel_add_external"
                phx-target={@myself}
              >
                <%= gettext("Cancel") %>
              </.button>
              <.button type="submit" phx-disable-with={gettext("Saving...")}>
                <%= gettext("Attach") %>
              </.button>
            </div>
          </.form>
        </div>
      <% else %>
        <div class="grid grid-cols-2 gap-2">
          <div class="p-4 border border-dashed border-ltrn-subtle rounded text-center text-ltrn-subtle bg-white shadow-lg">
            <div>
              <.icon name="hero-document-plus" class="h-8 w-8 mx-auto mb-6" />
              <div>
                <label class="cursor-pointer text-ltrn-primary hover:text-ltrn-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark">
                  <span><%= gettext("Upload a file") %></span>
                  <%!-- <.live_file_input upload={@upload} class="sr-only" /> --%>
                </label>
                <span><%= gettext("or drag and drop here") %></span>
              </div>
            </div>
          </div>
          <div class="p-4 border border-dashed border-ltrn-subtle rounded text-center bg-white shadow-lg">
            <.icon name="hero-link" class="h-8 w-8 mx-auto mb-6 text-ltrn-subtle" />
            <div>
              <button
                type="button"
                class="inline text-ltrn-primary hover:text-ltrn-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
                phx-click="add_external"
                phx-target={@myself}
              >
                <%= gettext("Or add a link to an external file") %>
                <span class="text-ltrn-subtle"><%= gettext("(e.g. Google Docs)") %></span>
              </button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:is_adding_external, false)
      |> stream_configure(
        :attachments,
        dom_id: fn {attachment, _i} -> "attachment-#{attachment.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    changeset =
      %Attachment{}
      |> Attachments.change_attachment()

    socket =
      socket
      |> assign_external_form(changeset)
      |> stream_attachments()

    {:ok, socket}
  end

  defp stream_attachments(socket) do
    attachments = Notes.list_note_attachments(socket.assigns.note_id)
    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  # event handlers

  @impl true
  def handle_event("add_external", _, socket),
    do: {:noreply, assign(socket, :is_adding_external, true)}

  def handle_event("cancel_add_external", _, socket),
    do: {:noreply, assign(socket, :is_adding_external, false)}

  def handle_event("validate_external", %{"attachment" => attachment_params}, socket) do
    changeset =
      %Attachment{}
      |> Attachments.change_attachment(attachment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_external_form(socket, changeset)}
  end

  def handle_event("create_external", %{"attachment" => params}, socket) do
    %{
      current_user: current_user,
      note_id: note_id
    } = socket.assigns

    # add is_external to params
    params =
      params
      |> Map.put("is_external", true)

    case Notes.create_note_attachment(current_user, note_id, params) do
      {:ok, attachment} ->
        notify_parent(__MODULE__, {:created, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_external_form(socket, changeset)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    attachment = Attachments.get_attachment!(id)

    case Attachments.delete_attachment(attachment) do
      {:ok, _attachment} ->
        socket =
          socket
          |> stream_attachments()

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> assign(:error_msg, gettext("Error deleting attachment"))

        {:noreply, socket}
    end
  end

  def handle_event("reorder_attachments", %{"from" => i, "to" => j}, socket) do
    attachments_ids =
      socket.assigns.attachments_ids
      |> swap(i, j)

    case Notes.update_note_attachments_positions(attachments_ids) do
      :ok ->
        socket =
          socket
          |> stream_attachments()

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # helpers

  defp assign_external_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :external_form, to_form(changeset))
end
