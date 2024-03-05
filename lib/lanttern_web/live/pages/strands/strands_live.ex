defmodule LantternWeb.StrandsLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Personalization

  import LantternWeb.PersonalizationHelpers

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # shared components
  import LantternWeb.LearningContextComponents
  alias LantternWeb.Taxonomy.SubjectPickerComponent
  alias LantternWeb.Taxonomy.YearPickerComponent

  # function components

  attr :items, :list, required: true
  attr :type, :string, required: true

  def filter_buttons(%{items: []} = assigns) do
    ~H"""
    <button type="button" phx-click={show_filter()} class="underline hover:text-ltrn-primary">
      <%= gettext("all %{type}", type: @type) %>
    </button>
    """
  end

  def filter_buttons(%{items: items, type: type} = assigns) do
    items =
      if length(items) > 3 do
        {first_two, rest} = Enum.split(items, 2)

        first_two
        |> Enum.map(& &1.name)
        |> Enum.join(" / ")
        |> Kernel.<>(" / + #{length(rest)} #{type}")
      else
        items
        |> Enum.map(& &1.name)
        |> Enum.join(" / ")
      end

    assigns = assign(assigns, :items, items)

    ~H"""
    <button type="button" phx-click={show_filter()} class="underline hover:text-ltrn-primary">
      <%= @items %>
    </button>
    """
  end

  attr :id, :string, required: true
  attr :strands, :list, required: true

  def strands_grid(assigns) do
    ~H"""
    <div id={@id} phx-update="stream" class="grid grid-cols-3 gap-10 mt-12">
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
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:subjects, :years], socket.assigns.current_user)
      |> assign(:is_creating_strand, false)
      |> stream_strands()

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

  def handle_event("toggle_subject_id", %{"id" => id}, socket) do
    selected_subjects_ids =
      case id in socket.assigns.selected_subjects_ids do
        true ->
          socket.assigns.selected_subjects_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_subjects_ids]
      end

    {:noreply, assign(socket, :selected_subjects_ids, selected_subjects_ids)}
  end

  def handle_event("toggle_year_id", %{"id" => id}, socket) do
    selected_years_ids =
      case id in socket.assigns.selected_years_ids do
        true ->
          socket.assigns.selected_years_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_years_ids]
      end

    {:noreply, assign(socket, :selected_years_ids, selected_years_ids)}
  end

  def handle_event("clear_filters", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{subjects_ids: [], years_ids: []}
    )

    {:noreply, push_navigate(socket, to: ~p"/strands")}
  end

  def handle_event("apply_filters", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids
      }
    )

    {:noreply, push_navigate(socket, to: ~p"/strands")}
  end

  # helpers

  defp show_filter(js \\ %JS{}),
    do: js |> JS.exec("data-show", to: "#strands-filters")
end
