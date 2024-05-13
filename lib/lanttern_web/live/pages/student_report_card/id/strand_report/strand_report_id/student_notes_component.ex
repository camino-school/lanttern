defmodule LantternWeb.StudentStrandReportLive.StudentNotesComponent do
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
          id="student-strand-notes"
          note={@note}
          current_user={@current_user}
          strand_id={@strand_id}
          title={
            if @is_student,
              do: gettext("My strand notes"),
              else: gettext("Student strand notes")
          }
          empty_msg={
            if @is_student,
              do: gettext("You don't have any notes for this strand yet"),
              else: gettext("No student notes for this strand")
          }
          empty_add_note_msg={gettext("Add a strand note")}
          allow_editing={@is_student}
        />
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
      Notes.get_student_note(student_id, strand_id: strand_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)

    {:ok, socket}
  end
end
