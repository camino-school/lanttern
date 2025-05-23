defmodule LantternWeb.MomentLive.NotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Notes

  # shared

  alias LantternWeb.Notes.NoteComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <.live_component
          module={NoteComponent}
          id="moment-notes"
          note={@note}
          current_user={@current_user}
          moment_id={@moment.id}
          title={gettext("My moment notes")}
          empty_msg={gettext("You don't have any notes for this moment yet")}
          empty_add_note_msg={gettext("Add a moment note")}
          allow_editing={true}
          tz={@current_user.tz}
        />
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{current_user: user, moment: moment} = assigns, socket) do
    note =
      Notes.get_user_note(user, moment_id: moment.id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)

    {:ok, socket}
  end
end
