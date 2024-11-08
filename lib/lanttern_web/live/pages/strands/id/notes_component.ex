defmodule LantternWeb.StrandLive.NotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Notes

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3]

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
        <%= if @has_moments_notes do %>
          <h4 class="mt-10 font-display font-bold text-lg">
            <%= gettext("Moments notes in this strand") %>
          </h4>
          <div :for={{dom_id, note} <- @streams.moments_notes} class="mt-6" id={dom_id}>
            <.link
              navigate={~p"/strands/moment/#{note.moment.id}?tab=notes"}
              class="font-display text-base"
            >
              <%= "Moment #{note.moment.position}:" %>
              <span class="underline"><%= note.moment.name %></span>
            </.link>
            <div class="mt-4 line-clamp-4">
              <.markdown text={note.description} size="sm" />
            </div>
          </div>
        <% end %>
        <.hr class="my-20" />
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
              <%= gettext("students strand notes") %>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= gettext("Select a class") %>
              </button>
              <%= gettext("to view students strand notes") %>
            </p>
          <% end %>
        </div>
        <div id="students-strand-notes" phx-update="stream" class="mt-10">
          <div
            :for={{dom_id, {student, note}} <- @streams.students_strand_notes}
            id={dom_id}
            class={[
              "rounded p-6 mt-6",
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
              <.markdown text={note.description} size="sm" />
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
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes to view student notes")}
        filter_type={:classes}
        filter_opts={[strand_id: @strand.id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}?tab=notes"}
      />
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

    moments_notes =
      Notes.list_user_notes(assigns.current_user, strand_id: assigns.strand.id)

    has_moments_notes = moments_notes != []

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)
      |> stream(:moments_notes, moments_notes)
      |> assign(:has_moments_notes, has_moments_notes)
      |> assign_user_filters([:classes], strand_id: assigns.strand.id)
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
