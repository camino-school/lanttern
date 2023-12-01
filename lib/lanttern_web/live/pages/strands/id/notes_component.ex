defmodule LantternWeb.StrandLive.NotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization
  alias Lanttern.Personalization.Note

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <%= if @is_editing do %>
        <.form for={@form} phx-submit="save" phx-target={@myself} id="strand-note-form">
          <.markdown_supported class="mb-6" />
          <.textarea_with_actions
            id={@form[:description].id}
            name={@form[:description].name}
            value={@form[:description].value}
            errors={@form[:description].errors}
            label="Add your notes..."
            rows="10"
          >
            <:actions_left :if={@note}>
              <.button
                type="button"
                theme="ghost"
                phx-click="delete"
                phx-target={@myself}
                data-confirm="Are you sure?"
              >
                Delete note
              </.button>
            </:actions_left>
            <:actions>
              <.button type="button" theme="ghost" phx-click="cancel_edit" phx-target={@myself}>
                Cancel
              </.button>
              <.button type="submit">
                Save
              </.button>
            </:actions>
          </.textarea_with_actions>
          <.error :for={{msg, _opts} <- @form[:description].errors}><%= msg %></.error>
        </.form>
      <% else %>
        <%= if @note do %>
          <div class="flex items-center justify-between mb-10">
            <h3 class="font-display font-bold text-xl">My strand notes (visible only to you)</h3>
            <.button type="button" theme="ghost" phx-click="edit" phx-target={@myself}>
              Edit
            </.button>
          </div>
          <.markdown text={@note.description} />
        <% else %>
          <.empty_state>You don't have any notes for this strand yet</.empty_state>
          <div class="mt-6 text-center">
            <button
              type="button"
              class="font-display font-black underline"
              phx-click="edit"
              phx-target={@myself}
            >
              Add a strand note
            </button>
          </div>
        <% end %>
        <%= if length(@activities_notes) > 0 do %>
          <h4 class="mt-10 font-display font-bold text-lg">Other notes in this strand</h4>
          <div :for={note <- @activities_notes} class="mt-6">
            <.link
              navigate={~p"/strands/activity/#{note.activity.id}?tab=notes"}
              class="font-display text-base"
            >
              <%= "Activity #{note.activity.position}:" %>
              <span class="underline"><%= note.activity.name %></span>
            </.link>
            <div class="mt-4 line-clamp-4">
              <.markdown text={note.description} class="prose-sm" />
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :is_editing, false)}
  end

  @impl true
  def update(%{current_user: user, strand: strand} = assigns, socket) do
    note =
      Personalization.get_user_note(user, strand_id: strand.id)

    activities_notes =
      Personalization.list_user_notes(user, strand_id: strand.id)

    form =
      case note do
        nil -> Personalization.change_note(%Note{})
        note -> Personalization.change_note(note)
      end
      |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:note, note)
     |> assign(:activities_notes, activities_notes)
     |> assign(:form, form)}
  end

  # event handlers

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:is_editing, true)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply,
     socket
     |> assign(:is_editing, false)}
  end

  def handle_event("save", %{"note" => params}, socket) do
    save_note(
      socket.assigns.note,
      params,
      socket
    )
    |> case do
      {:ok, note} ->
        {:noreply,
         socket
         |> assign(:is_editing, false)
         |> assign(:note, note)
         |> assign(:form, Personalization.change_note(note) |> to_form())}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))}
    end
  end

  def handle_event("delete", _params, socket) do
    Personalization.delete_note(socket.assigns.note)

    {:noreply,
     socket
     |> assign(:is_editing, false)
     |> assign(:note, nil)
     |> assign(:form, Personalization.change_note(%Note{}) |> to_form())}
  end

  # helpers

  defp save_note(nil, params, socket) do
    Personalization.create_strand_note(
      socket.assigns.current_user,
      socket.assigns.strand.id,
      params
    )
  end

  defp save_note(note, params, _socket) do
    Personalization.update_note(
      note,
      params
    )
  end
end
