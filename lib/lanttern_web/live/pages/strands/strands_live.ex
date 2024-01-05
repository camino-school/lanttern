defmodule LantternWeb.StrandsLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Taxonomy

  # live components
  alias LantternWeb.LearningContext.StrandFormComponent

  # function components

  attr :items, :list, required: true
  attr :type, :string, required: true

  def filter_buttons(%{items: []} = assigns) do
    ~H"""
    <button type="button" phx-click={show_filter()} class="underline hover:text-ltrn-primary">
      all <%= @type %>
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

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_subjects, [])
     |> assign(:current_years, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:subjects, Taxonomy.list_subjects())
     |> assign(:years, Taxonomy.list_years())
     # sync subjects_ids and years_ids filters with profile
     |> handle_params_and_profile_filters_sync(
       params,
       [:subjects_ids, :years_ids],
       &handle_assigns/2,
       fn params -> ~p"/strands?#{params}" end
     )}
  end

  # event handlers

  @impl true
  def handle_event("load-more", _params, socket) do
    {:noreply, load_strands(socket)}
  end

  def handle_event("filter", params, socket) do
    # enforce years and subjects in params,
    # required to clear profile filters when none is selected
    params = %{
      subjects_ids: Map.get(params, "subjects_ids"),
      years_ids: Map.get(params, "years_ids")
    }

    {:noreply,
     socket
     |> push_navigate(to: ~p"/strands?#{params}")}
  end

  def handle_event("clear-filters", _params, socket) do
    params = %{
      subjects_ids: nil,
      years_ids: nil
    }

    {:noreply,
     socket
     |> push_navigate(to: path(socket, ~p"/strands?#{params}"))}
  end

  # info handlers

  @impl true
  def handle_info({StrandFormComponent, {:saved, strand}}, socket) do
    {:noreply, stream_insert(socket, :strands, strand)}
  end

  # helpers

  defp handle_assigns(socket, params) do
    params_years_ids =
      case Map.get(params, "years_ids") do
        ids when is_list(ids) -> ids
        _ -> nil
      end

    params_subjects_ids =
      case Map.get(params, "subjects_ids") do
        ids when is_list(ids) -> ids
        _ -> nil
      end

    form =
      %{
        "years_ids" => params_years_ids || [],
        "subjects_ids" => params_subjects_ids || []
      }
      |> Phoenix.Component.to_form()

    socket
    |> assign_subjects(params)
    |> assign_years(params)
    |> assign(:form, form)
    |> load_strands()
  end

  defp assign_subjects(socket, %{"subjects_ids" => subjects_ids}) when subjects_ids != "" do
    current_subjects =
      socket.assigns.subjects
      |> Enum.filter(&("#{&1.id}" in subjects_ids))

    assign(socket, :current_subjects, current_subjects)
  end

  defp assign_subjects(socket, _params), do: socket

  defp assign_years(socket, %{"years_ids" => years_ids}) when years_ids != "" do
    current_years =
      socket.assigns.years
      |> Enum.filter(&("#{&1.id}" in years_ids))

    assign(socket, :current_years, current_years)
  end

  defp assign_years(socket, _params), do: socket

  defp load_strands(socket) do
    subjects_ids =
      socket.assigns.current_subjects
      |> Enum.map(& &1.id)

    years_ids =
      socket.assigns.current_years
      |> Enum.map(& &1.id)

    {strands, meta} =
      LearningContext.list_strands(
        preloads: [:subjects, :years],
        after: socket.assigns[:end_cursor],
        subjects_ids: subjects_ids,
        years_ids: years_ids
      )

    strands_count = length(strands)

    socket
    |> stream(:strands, strands)
    |> assign(:strands_count, strands_count)
    |> assign(:end_cursor, meta.end_cursor)
    |> assign(:has_next_page, meta.has_next_page?)
  end

  defp show_filter(js \\ %JS{}) do
    js
    # |> JS.push("show-filter")
    |> JS.exec("data-show", to: "#strands-filters")
  end

  defp filter(js \\ %JS{}) do
    js
    |> JS.push("filter")
    |> JS.exec("data-cancel", to: "#strands-filters")
  end

  defp clear_filters(js \\ %JS{}) do
    js
    |> JS.push("clear-filters")
    |> JS.exec("data-cancel", to: "#strands-filters")
  end
end
