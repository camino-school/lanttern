defmodule LantternWeb.StrandLive.NotesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization

  # shared

  alias LantternWeb.Personalization.NoteComponent

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
            <%= gettext("Other notes in this strand") %>
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
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{current_user: user, strand: strand} = assigns, socket) do
    note =
      Personalization.get_user_note(user, strand_id: strand.id)

    moments_notes =
      Personalization.list_user_notes(user, strand_id: strand.id)

    has_moments_notes = moments_notes != []

    socket =
      socket
      |> assign(assigns)
      |> assign(:note, note)
      |> stream(:moments_notes, moments_notes)
      |> assign(:has_moments_notes, has_moments_notes)

    {:ok, socket}
  end
end
