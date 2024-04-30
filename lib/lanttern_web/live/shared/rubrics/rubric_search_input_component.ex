defmodule LantternWeb.Rubrics.RubricSearchInputComponent do
  @moduledoc """
  Renders a rubric search input
  """

  use LantternWeb, :live_component

  alias Lanttern.Rubrics

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <p class="mb-2 text-sm">
        Search rubrics by criteria,<br /> or serch by id adding # before the id. E.g.
        <.inline_code>
          #123
        </.inline_code>
      </p>
      <form class="relative">
        <.base_input
          id={@id}
          name="query"
          type="text"
          value=""
          class="peer pr-10"
          role="combobox"
          autocomplete="off"
          aria-controls={"rubric-search-controls-#{@id}"}
          aria-expanded="false"
          phx-hook="Autocomplete"
          phx-change="search"
          phx-debounce="500"
          phx-target={@myself}
          phx-update="ignore"
        />
        <.icon
          name="hero-chevron-up-down"
          class="absolute top-2.5 right-2.5 text-ltrn-subtle peer-phx-change-loading:hidden"
        />
        <div class="hidden absolute top-3 right-3 peer-phx-change-loading:block">
          <.ping />
        </div>

        <ul
          class={[
            "absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm hidden",
            "peer-aria-expanded:block"
          ]}
          id={"rubric-search-controls-#{@id}"}
          role="listbox"
          phx-update="stream"
        >
          <li
            :for={{dom_id, rubric} <- @streams.rubrics}
            class={[
              "flex items-center cursor-default select-none py-2 px-3 text-ltrn-dark group",
              "data-[active=true]:bg-ltrn-primary"
            ]}
            id={dom_id}
            role="option"
            aria-selected={if @selected_id == rubric.id, do: "true", else: "false"}
            tabindex="-1"
            data-result-id={rubric.id}
            data-result-name={rubric.criteria}
          >
            <div class="flex-1 truncate group-aria-selected:font-bold" }>
              <span class="font-bold text-xs">
                #<%= rubric.id %>
              </span>
              <br /> Criteria: <%= rubric.criteria %>
              <.badge :if={rubric.is_differentiation} theme="cyan">Differentiation</.badge>
            </div>
            <.icon
              name="hero-check"
              class={[
                "shrink-0 ml-2 text-ltrn-primary hidden",
                "group-aria-selected:block group-data-[active=true]:text-white"
              ]}
            />
          </li>
        </ul>
      </form>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> stream(:rubrics, [])

    {:ok, socket}
  end

  def update(assigns, socket) do
    selected_id =
      case Map.get(assigns, :selected_id) do
        nil -> nil
        "" -> nil
        id when is_binary(id) -> String.to_integer(id)
        id -> id
      end

    search_opts = Map.get(assigns, :search_opts, [])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_id, selected_id)
     |> assign(:search_opts, search_opts)}
  end

  # event handlers

  def handle_event("search", %{"query" => query}, socket) do
    rubrics =
      cond do
        # search when looking for id
        query =~ ~r/#[0-9]+\z/ ->
          Rubrics.search_rubrics(query, socket.assigns.search_opts)

        # or when more than 3 characters were typed
        String.length(query) > 3 ->
          Rubrics.search_rubrics(query, socket.assigns.search_opts)

        true ->
          []
      end

    results_simplified = Enum.map(rubrics, fn r -> %{id: r.id} end)

    socket =
      socket
      |> stream(:rubrics, rubrics, reset: true)
      |> push_event("autocomplete_search_results:#{socket.assigns.id}", %{
        results: results_simplified
      })

    {:noreply, socket}
  end

  def handle_event("autocomplete_result_select", %{"id" => id}, socket) do
    selected_id = String.to_integer(id)
    send_update(socket.assigns.notify_component, action: {__MODULE__, {:selected, selected_id}})

    socket =
      socket
      |> stream(:rubrics, [], reset: true)
      |> assign(:selected_id, selected_id)

    {:noreply, socket}
  end
end
