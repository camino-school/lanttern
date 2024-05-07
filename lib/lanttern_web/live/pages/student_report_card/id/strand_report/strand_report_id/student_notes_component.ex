defmodule LantternWeb.StudentStrandReportLive.StudentNotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization
  alias Lanttern.Personalization.Note

  import LantternWeb.DateTimeHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <%= if @is_editing and @is_student do %>
          <.form for={@form} phx-submit="save" phx-target={@myself} id="strand-note-form">
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
                <%= if @is_student,
                  do: gettext("My strand notes"),
                  else: gettext("Student strand notes") %>
              </h3>
              <.button
                :if={@is_student}
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
              <%= if @is_student,
                do: gettext("You don't have any notes for this strand yet"),
                else: gettext("No student notes for this strand") %>
            </.empty_state>
            <div :if={@is_student} class="mt-6 text-center">
              <button
                type="button"
                class="font-display font-black underline"
                phx-click="edit"
                phx-target={@myself}
              >
                <%= gettext("Add a strand note") %>
              </button>
            </div>
          <% end %>
        <% end %>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :is_editing, false)}
  end

  @impl true
  def update(assigns, socket) do
    %{student_id: student_id, strand_id: strand_id} = assigns

    note =
      Personalization.get_student_note(student_id, strand_id: strand_id)

    form =
      case note do
        nil -> Personalization.change_note(%Note{})
        note -> Personalization.change_note(note)
      end
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)
      |> assign(:form, form)

    {:ok, socket}
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
      socket.assigns.strand_id,
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
