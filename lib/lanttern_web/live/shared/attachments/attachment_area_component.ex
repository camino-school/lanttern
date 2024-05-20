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
      <div :if={@title} class="flex items-center gap-2 mb-4">
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
          class="flex items-center gap-4 mb-4"
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
                <a href={attachment.link} target="_blank" class="group flex-1 min-w-0 text-sm">
                  <%= attachment.name %>
                  <span class="block max-w-full mt-2 text-xs underline text-ellipsis overflow-hidden group-hover:text-ltrn-subtle">
                    <%= attachment.link %>
                  </span>
                </a>
              </div>
            </.sortable_card>
            <.menu_button id={attachment.id}>
              <:item
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
              <a href={attachment.link} target="_blank" class="group mt-2 text-sm">
                <%= attachment.name %>
                <span class="block mt-2 text-xs underline text-ellipsis overflow-hidden group-hover:text-ltrn-subtle">
                  <%= attachment.link %>
                </span>
              </a>
            </div>
          <% end %>
        </li>
      </ul>
      <%= if @is_adding_external || @is_editing do %>
        <div class="p-4 border border-dashed border-ltrn-subtle rounded bg-white shadow-lg">
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
      <% else %>
        <div :if={@allow_editing} class="grid grid-cols-2 gap-2">
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
      |> assign(:title, nil)
      |> assign(:class, nil)
      |> assign(:allow_editing, false)
      |> assign(:attachment, nil)
      |> assign(:is_adding_external, false)
      |> assign(:is_editing, false)
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
    type =
      case socket.assigns do
        %{is_adding_external: true} -> :new_external
        %{is_editing: true} -> :edit
      end

    save_attachment(socket, type, params)
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

  # save attachment clauses:
  # :new_external -> when is_adding_external
  # :edit -> when is_editing

  defp save_attachment(socket, :new_external, params) do
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
