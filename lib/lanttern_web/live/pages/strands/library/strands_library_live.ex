defmodule LantternWeb.StrandsLibraryLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand

  import LantternWeb.FiltersHelpers,
    only: [assign_user_filters: 2, save_profile_filters: 2]

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # shared components
  import LantternWeb.LearningContextComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Strands library"))
      |> assign(:strands_length, 0)
      |> assign_user_filters([:subjects, :years, :starred_strands])
      |> stream_strands()

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
        show_starred_for_profile_id: socket.assigns.current_user.current_profile.id,
        only_starred: socket.assigns.only_starred_strands
      )

    %{
      results: strands,
      keyset: keyset,
      has_next: has_next
    } = page

    socket
    |> stream(:strands, strands)
    |> assign(:strands_length, socket.assigns.strands_length + length(strands))
    |> assign(:keyset, keyset)
    |> assign(:has_next_page, has_next)
  end

  @impl true
  def handle_params(_params, _uri, socket),
    do: {:noreply, socket}

  # event handlers

  @impl true
  def handle_event("toggle_only_starred_strands", _params, socket) do
    only_starred_strands = !socket.assigns.only_starred_strands

    message =
      if only_starred_strands do
        gettext("Showing only starred strands")
      else
        gettext("Showing all strands")
      end

    socket =
      socket
      |> assign(:only_starred_strands, only_starred_strands)
      |> save_profile_filters([:starred_strands])
      |> push_navigate(to: ~p"/strands/library", replace: true)
      |> put_flash(:info, message)

    {:noreply, socket}
  end

  def handle_event("load-more", _params, socket),
    do: {:noreply, stream_strands(socket)}

  def handle_event("star-strand", %{"id" => id, "name" => name}, socket) do
    profile_id = socket.assigns.current_user.current_profile.id

    with {:ok, _} <- LearningContext.star_strand(id, profile_id) do
      strand =
        LearningContext.get_strand!(id, preloads: [:subjects, :years])
        |> Map.put(:is_starred, true)

      socket =
        socket
        |> put_flash(:info, "\"#{name}\" added to your starred strands")
        |> stream_insert(:strands, strand)

      {:noreply, socket}
    end
  end

  def handle_event("unstar-strand", %{"id" => id, "name" => name}, socket) do
    profile_id = socket.assigns.current_user.current_profile.id

    with {:ok, _} <- LearningContext.unstar_strand(id, profile_id) do
      strand =
        LearningContext.get_strand!(id, preloads: [:subjects, :years])
        |> Map.put(:is_starred, false)

      socket =
        socket
        |> put_flash(:info, "\"#{name}\" removed from your starred strands")

      socket =
        if socket.assigns.only_starred_strands do
          socket
          |> stream_delete(:strands, strand)
          |> assign(:strands_length, socket.assigns.strands_length - 1)
        else
          stream_insert(socket, :strands, strand)
        end

      {:noreply, socket}
    end
  end
end
