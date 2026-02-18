defmodule LantternWeb.StrandLive.NotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Notes

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.Notes.NoteComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <.live_component
          module={NoteComponent}
          id="strand-notes"
          note={@note}
          current_user={@current_user}
          strand_id={@strand.id}
          title={gettext("My strand notes")}
          empty_msg={gettext("You don't have any notes for this strand yet")}
          empty_add_note_msg={gettext("Add a strand note")}
          allow_editing={true}
        />
        <.hr class="my-10" />
        <h4 class="font-display font-black text-xl text-ltrn-subtle">
          {gettext("Student notes")}
        </h4>
        <.empty_state_simple :if={@selected_classes_ids == []} class="mt-6">
          {gettext("Select a class above to view students notes")}
        </.empty_state_simple>
        <div id="students-strand-notes" phx-update="stream" class="mt-10">
          <div
            :for={{dom_id, {student, note}} <- @streams.students_strand_notes}
            id={dom_id}
            class={[
              "rounded-sm p-6 mt-6",
              if(note, do: "bg-white shadow-lg", else: "bg-ltrn-lighter")
            ]}
          >
            <div class="flex items-center gap-4">
              <.profile_icon_with_name
                theme={if note, do: "cyan", else: "subtle"}
                profile_name={student.name}
                extra_info={student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
                class="flex-1"
              />
              <.toggle_expand_button
                :if={note}
                id={"student-strand-note-#{dom_id}-toggle-button"}
                target_selector={"#student-strand-note-#{dom_id}"}
              />
            </div>
            <div
              :if={note}
              class="pt-6 border-t border-ltrn-lighter mt-6"
              id={"student-strand-note-#{dom_id}"}
            >
              <.markdown text={note.description} />
              <.live_component
                :if={note}
                module={AttachmentAreaComponent}
                id={"student-strand-note-attachemnts-#{dom_id}"}
                class="mt-6"
                note_id={note.id}
                title={gettext("Attachments")}
              />
            </div>
          </div>
        </div>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_strand_notes,
        dom_id: fn
          {student, _note} -> "note-from-student-#{student.id}"
          _ -> ""
        end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    note =
      Notes.get_user_note(assigns.current_user, strand_id: assigns.strand.id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)
      |> stream_students_strand_notes()

    {:ok, socket}
  end

  defp stream_students_strand_notes(socket) do
    students_strand_notes =
      socket.assigns.selected_classes_ids
      |> Notes.list_classes_strand_notes(socket.assigns.strand.id)

    socket
    |> stream(:students_strand_notes, students_strand_notes)
  end
end
