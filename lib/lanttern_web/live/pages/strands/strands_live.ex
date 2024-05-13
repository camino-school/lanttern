defmodule LantternWeb.StrandsLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  import LantternWeb.FiltersHelpers

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # shared components
  import LantternWeb.LearningContextComponents

  # function components

  attr :id, :string, required: true
  attr :strands, :list, required: true

  def strands_grid(assigns) do
    ~H"""
    <.responsive_grid id={@id} phx-update="stream">
      <.strand_card
        :for={{dom_id, strand} <- @strands}
        id={dom_id}
        strand={strand}
        on_star_click={
          JS.push(
            if(strand.is_starred, do: "unstar-strand", else: "star-strand"),
            value: %{id: strand.id, name: strand.name}
          )
        }
        navigate={~p"/strands/#{strand}"}
        class="shrink-0 w-64 sm:w-auto"
      />
    </.responsive_grid>
    """
  end

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters(
        [:subjects, :years],
        socket.assigns.current_user
      )
      |> assign(:is_creating_strand, false)
      |> stream_strands()
      |> assign(:page_title, gettext("Strands"))

    {:ok, socket}
  end

  defp stream_strands(socket) do
    %{
      selected_subjects_ids: subjects_ids,
      selected_years_ids: years_ids
    } =
      socket.assigns

    {strands, meta} =
      LearningContext.list_strands(
        preloads: [:subjects, :years],
        after: socket.assigns[:end_cursor],
        subjects_ids: subjects_ids,
        years_ids: years_ids,
        show_starred_for_profile_id: socket.assigns.current_user.current_profile.id
      )

    strands_count = length(strands)

    starred_strands =
      LearningContext.list_starred_strands(
        socket.assigns.current_user.current_profile.id,
        preloads: [:subjects, :years],
        subjects_ids: subjects_ids,
        years_ids: years_ids
      )

    starred_strands_count = length(starred_strands)

    socket
    |> stream(:strands, strands)
    |> assign(:strands_count, strands_count)
    |> assign(:end_cursor, meta.end_cursor)
    |> assign(:has_next_page, meta.has_next_page?)
    |> stream(:starred_strands, starred_strands)
    |> assign(:starred_strands_count, starred_strands_count)
  end

  # event handlers

  @impl true
  def handle_event("create-strand", _params, socket),
    do: {:noreply, assign(socket, :is_creating_strand, true)}

  def handle_event("cancel-strand-creation", _params, socket),
    do: {:noreply, assign(socket, :is_creating_strand, false)}

  def handle_event("load-more", _params, socket),
    do: {:noreply, stream_strands(socket)}

  def handle_event("star-strand", %{"id" => id, "name" => name}, socket) do
    profile_id = socket.assigns.current_user.current_profile.id

    with {:ok, _} <- LearningContext.star_strand(id, profile_id) do
      {:noreply,
       socket
       |> put_flash(:info, "\"#{name}\" added to your starred strands")
       |> push_navigate(to: ~p"/strands", replace: true)}
    end
  end

  def handle_event("unstar-strand", %{"id" => id, "name" => name}, socket) do
    profile_id = socket.assigns.current_user.current_profile.id

    with {:ok, _} <- LearningContext.unstar_strand(id, profile_id) do
      {:noreply,
       socket
       |> put_flash(:info, "\"#{name}\" removed from your starred strands")
       |> push_navigate(to: ~p"/strands", replace: true)}
    end
  end
end
