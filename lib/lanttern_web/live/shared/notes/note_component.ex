defmodule LantternWeb.Notes.NoteComponent do
  @moduledoc """
  Renders notes markdown and editor.

  ### Required attrs

  - `:note` - `%Note{}` or `nil`
  - `:current_user` - `%User{}` in `socket.assigns.current_user`
  - `:title` - Title to display when showing notes
  - `:empty_msg` - Message to display when empty
  - `:empty_add_note_msg` - Add note message to display when empty
  - `:strand_id` - When creating strand notes
  - `:moment_id` - When creating moment notes

  ### Optional attrs

  - `:class`
  - `:allow_editing` - Defaults to `false`

  """

  use LantternWeb, :live_component

  alias Lanttern.Notes
  alias Lanttern.Notes.Note

  import LantternWeb.DateTimeHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <%= if @is_editing && @allow_editing do %>
        <.form for={@form} phx-submit="save" phx-target={@myself} id="note-form">
          <.markdown_supported class="mb-6" />
          <.textarea_with_actions
            id={@form[:description].id}
            name={@form[:description].name}
            value={@form[:description].value}
            errors={@form[:description].errors}
            label={gettext("Add your notes...")}
            rows="10"
          >
            <:actions_left :if={@note}>
              <.button
                type="button"
                theme="ghost"
                phx-click="delete"
                phx-target={@myself}
                data-confirm={gettext("Are you sure?")}
              >
                <%= gettext("Delete note") %>
              </.button>
            </:actions_left>
            <:actions>
              <.button type="button" theme="ghost" phx-click="cancel_edit" phx-target={@myself}>
                <%= gettext("Cancel") %>
              </.button>
              <.button type="submit">
                <%= gettext("Save") %>
              </.button>
            </:actions>
          </.textarea_with_actions>
          <.error :for={{msg, _opts} <- @form[:description].errors}><%= msg %></.error>
        </.form>
      <% else %>
        <%= if @note do %>
          <div class="flex items-center justify-between">
            <h3 class="font-display font-bold text-xl">
              <%= @title %>
            </h3>
            <.button
              :if={@allow_editing}
              type="button"
              theme="ghost"
              phx-click="edit"
              phx-target={@myself}
            >
              <%= gettext("Edit") %>
            </.button>
          </div>
          <p class="text-xs">
            <%= gettext("Created at") %> <%= format_local!(
              @note.inserted_at,
              "{Mshort} {D}, {YYYY}, {h24}:{m}"
            ) %>
            <span :if={@note.inserted_at != @note.updated_at} class="text-ltrn-subtle">
              (<%= gettext("updated") %> <%= format_local!(
                @note.updated_at,
                "{Mshort} {D}, {YYYY}, {h24}:{m}"
              ) %>)
            </span>
          </p>
          <.markdown text={@note.description} class="mt-10" />
        <% else %>
          <.empty_state>
            <%= @empty_msg %>
          </.empty_state>
          <div :if={@allow_editing} class="mt-6 text-center">
            <button
              type="button"
              class="font-display font-black underline"
              phx-click="edit"
              phx-target={@myself}
            >
              <%= @empty_add_note_msg %>
            </button>
          </div>
        <% end %>
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
      |> assign(:is_editing, false)
      |> assign(:allow_editing, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    form =
      case assigns.note do
        nil -> Notes.change_note(%Note{})
        note -> Notes.change_note(note)
      end
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("edit", _params, socket),
    do: {:noreply, assign(socket, :is_editing, true)}

  def handle_event("cancel_edit", _params, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("save", %{"note" => params}, socket) do
    socket =
      save_note(socket, params)
      |> case do
        {:ok, note} ->
          notify(__MODULE__, {:saved, note}, socket.assigns)

          socket
          |> assign(:is_editing, false)
          |> assign(:note, note)
          |> assign(:form, Notes.change_note(note) |> to_form())

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Notes.delete_note(socket.assigns.note, log_operation: true) do
        {:ok, note} ->
          notify(__MODULE__, {:deleted, note}, socket.assigns)

          socket
          |> assign(:is_editing, false)
          |> assign(:note, nil)
          |> assign(:form, Notes.change_note(%Note{}) |> to_form())

        {:error, changeset} ->
          assign(socket, :form, to_form(changeset))
      end

    {:noreply, socket}
  end

  # helpers

  defp save_note(%{assigns: %{note: nil, strand_id: strand_id}} = socket, params) do
    Notes.create_strand_note(
      socket.assigns.current_user,
      strand_id,
      params,
      log_operation: true
    )
  end

  defp save_note(%{assigns: %{note: nil, moment_id: moment_id}} = socket, params) do
    Notes.create_moment_note(
      socket.assigns.current_user,
      moment_id,
      params,
      log_operation: true
    )
  end

  defp save_note(%{assigns: %{note: %Note{} = note}} = _socket, params) do
    Notes.update_note(
      note,
      params,
      log_operation: true
    )
  end
end
