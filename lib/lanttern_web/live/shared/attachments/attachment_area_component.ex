defmodule LantternWeb.Attachments.AttachmentAreaComponent do
  @moduledoc """
  Creates an attachment area UI.

  Supports only notes attachments (for now).
  """

  use LantternWeb, :live_component

  import Lanttern.Utils, only: [swap: 3]
  alias Lanttern.SupabaseHelpers

  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.Notes

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[@class, if(!@is_editing && @attachments_length == 0, do: "hidden")]}>
      <div :if={@title} class="flex items-center gap-2">
        <.icon name="hero-paper-clip" class="w-6 h-6" />
        <h5 class="font-display font-bold text-sm"><%= @title %></h5>
      </div>
      <ul
        :if={@attachments_length > 0}
        id="attachments-list"
        phx-update="stream"
        class={if @is_editing, do: "hidden"}
      >
        <li
          :for={{dom_id, {attachment, i}} <- @streams.attachments}
          id={dom_id}
          class="flex items-center gap-4 mt-4"
        >
          <%= if @allow_editing do %>
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
                  <.tooltip><%= gettext("Copy attachment link markdown") %></.tooltip>
                </button>
                <div class="flex-1 min-w-o">
                  <%= if(attachment.is_external) do %>
                    <.badge><%= gettext("External link") %></.badge>
                  <% else %>
                    <.badge theme="cyan"><%= gettext("Upload") %></.badge>
                  <% end %>
                  <a
                    href={attachment.link}
                    target="_blank"
                    class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                  >
                    <%= attachment.name %>
                  </a>
                </div>
              </div>
            </.sortable_card>
            <.menu_button id={attachment.id}>
              <:item
                :if={attachment.is_external}
                id={"edit-attachment-#{attachment.id}"}
                text={gettext("Edit")}
                on_click={JS.push("edit", value: %{"id" => attachment.id}, target: @myself)}
              />
              <:item
                id={"remove-attachment-#{attachment.id}"}
                text={gettext("Remove")}
                on_click={JS.push("delete", value: %{"id" => attachment.id}, target: @myself)}
                theme="alert"
                confirm_msg={gettext("Are you sure? This action cannot be undone.")}
              />
            </.menu_button>
          <% else %>
            <div class="flex-1 min-w-0 p-4 rounded bg-white shadow-lg">
              <%= if(attachment.is_external) do %>
                <.badge><%= gettext("External link") %></.badge>
              <% else %>
                <.badge theme="cyan"><%= gettext("Upload") %></.badge>
              <% end %>
              <a
                href={attachment.link}
                target="_blank"
                class="block mt-2 text-sm underline hover:text-ltrn-subtle"
              >
                <%= attachment.name %>
              </a>
            </div>
          <% end %>
        </li>
      </ul>
      <div
        :if={@is_adding_external || @is_editing}
        class="p-4 border border-dashed border-ltrn-subtle rounded mt-4 bg-white shadow-lg"
      >
        <.form
          for={@form}
          id="external-attachment-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Attachment name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:link]}
            type="text"
            label={gettext("Link")}
            class="mb-6"
            phx-debounce="1500"
          />
          <div class="flex justify-end gap-2">
            <.button type="button" theme="ghost" phx-click="cancel" phx-target={@myself}>
              <%= gettext("Cancel") %>
            </.button>
            <.button type="submit" phx-disable-with={gettext("Saving...")}>
              <%= gettext("Save") %>
            </.button>
          </div>
        </.form>
      </div>
      <div
        :for={entry <- @uploads.attachment_file.entries}
        class="p-4 border border-dashed border-ltrn-subtle rounded mt-4 shadow-lg bg-white"
      >
        <p class="flex items-center gap-2 text-sm text-ltrn-subtle">
          <.icon name="hero-paper-clip-mini" />
          <%= gettext("File upload") %>
        </p>
        <p class="mt-2 font-bold">
          <%= entry.client_name %>
        </p>
        <.error_block :if={@invalid_upload_msg} class="mt-4">
          <%= @invalid_upload_msg %>
        </.error_block>
        <%!-- <%= inspect(entry) %>
        <%= for err <- upload_errors(@uploads.attachment_file, entry) do %>
          <p class="alert alert-danger"><%= err %></p>
        <% end %> --%>

        <div class="flex justify-end gap-4 mt-10">
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.push("cancel_upload", value: %{"ref" => entry.ref}, target: @myself)}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="attachments-upload-form" disabled={!entry.valid?}>
            <%= gettext("Upload") %>
          </.button>
        </div>
      </div>
      <div
        :if={@allow_editing && !@is_adding_external && !@is_editing}
        class={
          [
            "grid grid-cols-2 gap-2 mt-4",
            # we don't use the conditional rendering with :if for attachment files
            # because we need the #attachments-upload-form for upload
            if(@uploads.attachment_file.entries != [], do: "hidden")
          ]
        }
      >
        <div
          class="p-4 border border-dashed border-ltrn-subtle rounded text-center text-ltrn-subtle bg-white shadow-lg"
          phx-drop-target={@uploads.attachment_file.ref}
        >
          <form
            id="attachments-upload-form"
            phx-submit="upload"
            phx-change="validate_upload"
            phx-target={@myself}
          >
            <.icon name="hero-document-plus" class="h-8 w-8 mx-auto mb-6" />
            <div>
              <label
                for={@uploads.attachment_file.ref}
                class="cursor-pointer text-ltrn-primary hover:text-ltrn-dark focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-ltrn-dark"
              >
                <span><%= gettext("Upload a file") %></span>
                <.live_file_input upload={@uploads.attachment_file} class="sr-only" />
              </label>
              <span><%= gettext("or drag and drop here") %></span>
            </div>
          </form>
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
      <.error_block
        :if={@upload_error}
        class="mt-4"
        on_dismiss={JS.push("clear_upload_error", target: @myself)}
      >
        <%= @upload_error %>
      </.error_block>
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
      |> assign(:allow_editing, false)
      |> assign(:attachment, nil)
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)
      |> assign(:upload_error, nil)
      |> stream_configure(
        :attachments,
        dom_id: fn {attachment, _i} -> "attachment-#{attachment.id}" end
      )
      |> allow_upload(:attachment_file,
        accept: :any,
        max_file_size: 5_000_000,
        max_entries: 1
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream_attachments()

    {:ok, socket}
  end

  defp stream_attachments(socket) do
    attachments =
      if socket.assigns.note_id do
        Notes.list_note_attachments(socket.assigns.note_id)
      else
        []
      end

    attachments_ids = Enum.map(attachments, & &1.id)

    socket
    |> stream(:attachments, Enum.with_index(attachments), reset: true)
    |> assign(:attachments_length, length(attachments))
    |> assign(:attachments_ids, attachments_ids)
  end

  # event handlers

  @impl true
  def handle_event("add_external", _, socket) do
    changeset =
      %Attachment{}
      |> Attachments.change_attachment()

    socket =
      socket
      |> assign(:is_adding_external, true)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    attachment = Attachments.get_attachment!(id)
    changeset = Attachments.change_attachment(attachment, %{})

    socket =
      socket
      |> assign(:is_editing, true)
      |> assign(:attachment, attachment)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    socket =
      socket
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)

    {:noreply, socket}
  end

  def handle_event("validate", %{"attachment" => attachment_params}, socket) do
    changeset =
      %Attachment{}
      |> Attachments.change_attachment(attachment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"attachment" => params}, socket) do
    case socket.assigns do
      %{is_adding_external: true} ->
        # add is_external to params
        params =
          params
          |> Map.put("is_external", true)

        save_attachment(socket, :new, params)

      %{is_editing: true} ->
        save_attachment(socket, :edit, params)
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

  def handle_event("validate_upload", _, socket) do
    upload_conf = socket.assigns.uploads.attachment_file

    invalid_upload_msg =
      case upload_conf.entries do
        [entry] -> upload_errors(upload_conf, entry)
        _ -> []
      end
      |> Enum.map(&upload_error_to_string(upload_conf, &1))
      |> case do
        [] -> nil
        error_messages -> Enum.join(error_messages, " ")
      end

    socket =
      socket
      |> assign(:invalid_upload_msg, invalid_upload_msg)

    {:noreply, socket}
  end

  def handle_event("upload", _, socket) do
    [consumed_upload_res] =
      consume_uploaded_entries(socket, :attachment_file, fn %{path: file_path}, entry ->
        SupabaseHelpers.upload_object(
          "attachments",
          entry.client_name,
          file_path,
          %{content_type: entry.client_type}
        )
        |> case do
          {:ok, object} ->
            attachment_url =
              "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object["Key"])}"

            {:ok, {:ok, {attachment_url, entry.client_name}}}

          {:error, message} ->
            {:ok, {:error, message}}
        end
      end)

    case consumed_upload_res do
      {:ok, {link, name}} ->
        params = %{
          "name" => name,
          "link" => link
        }

        save_attachment(socket, :new, params)

      {:error, message} ->
        socket =
          socket
          |> assign(:upload_error, message)

        {:noreply, socket}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment_file, ref)}
  end

  def handle_event("clear_upload_error", _, socket) do
    {:noreply, assign(socket, :upload_error, nil)}
  end

  # helpers

  # save attachment clauses:
  # :new -> when is_adding_external or uploading attachment
  # :edit -> when is_editing

  defp save_attachment(socket, :new, params) do
    %{
      current_user: current_user,
      note_id: note_id
    } = socket.assigns

    case Notes.create_note_attachment(current_user, note_id, params) do
      {:ok, attachment} ->
        notify_parent(__MODULE__, {:created, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_adding_external, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_attachment(socket, :edit, params) do
    %{attachment: attachment} = socket.assigns

    case Attachments.update_attachment(attachment, params) do
      {:ok, attachment} ->
        notify_parent(__MODULE__, {:edited, attachment}, socket.assigns)

        socket =
          socket
          |> assign(:is_editing, false)
          |> stream_attachments()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset),
    do: assign(socket, :form, to_form(changeset))
end
