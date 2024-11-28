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
    <.responsive_grid id={@id} phx-update="stream" class="px-6 py-10 sm:px-10">
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
      |> assign_user_filters([:subjects, :years])
      |> assign(:is_creating_strand, false)
      |> stream_strands()
      |> assign(:page_title, gettext("Strands"))

    {:ok, socket}
  end

  defp stream_strands(socket) do
    page =
      LearningContext.list_strands_page(
        preloads: [:subjects, :years],
        first: 20,
        after: socket.assigns[:keyset],
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids,
        show_starred_for_profile_id: socket.assigns.current_user.current_profile.id
      )

    %{
      results: strands,
      keyset: keyset,
      has_next: has_next
    } = page

    starred_strands =
      LearningContext.list_strands(
        only_starred_for_profile_id: socket.assigns.current_user.current_profile.id,
        preloads: [:subjects, :years],
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids
      )

    socket
    |> stream(:strands, strands)
    |> assign(:has_strands, length(strands) > 0)
    |> assign(:keyset, keyset)
    |> assign(:has_next_page, has_next)
    |> stream(:starred_strands, starred_strands)
    |> assign(:has_starred_strands, length(starred_strands) > 0)
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
