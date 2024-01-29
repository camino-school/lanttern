defmodule LantternWeb.Curricula.CurriculumItemSearchComponent do
  use LantternWeb, :live_component

  alias Lanttern.Curricula

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.label :if={@label} for={@id}>
        <%= @label %>
      </.label>
      <p class="mb-2 text-sm">
        <%= gettext("You can search by id adding # before the id") %>
        <.inline_code>
          #123
        </.inline_code>
        <%= gettext("and search by code wrapping it in parenthesis") %>
        <.inline_code>
          (ABC123)
        </.inline_code>
      </p>
      <div class="relative">
        <.base_input
          id={@id}
          name="query"
          type="text"
          value=""
          class="peer pr-10"
          role="combobox"
          autocomplete="off"
          aria-controls="curriculum-item-search-controls"
          aria-expanded="false"
          phx-hook="Autocomplete"
          phx-change="search"
          phx-debounce="500"
          phx-target={@myself}
          phx-update="ignore"
          data-refocus-on-select={@refocus_on_select}
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
          id="curriculum-item-search-controls"
          role="listbox"
          phx-update="stream"
        >
          <li
            :for={{dom_id, result} <- @streams.results}
            class={[
              "flex items-center cursor-default select-none py-2 px-3 text-ltrn-dark group",
              "data-[active=true]:bg-ltrn-primary"
            ]}
            id={dom_id}
            role="option"
            aria-selected="false"
            tabindex="-1"
            data-result-id={result.id}
            data-result-name={result.name}
          >
            <div class="flex-1 truncate group-aria-selected:font-bold" }>
              <span class="font-bold text-xs">
                #<%= result.id %>
                <span :if={result.code}>(<%= result.code %>)</span>
              </span>
              <br />
              <%= result.name %>
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
      </div>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> assign(:label, nil)
      |> assign(:class, nil)
      |> assign(:refocus_on_select, "false")
      |> stream(:results, [])

    {:ok, socket}
  end

  # event handlers

  def handle_event("search", %{"query" => query}, socket) do
    results =
      cond do
        # search when looking for id
        query =~ ~r/#[0-9]+\z/ ->
          Curricula.search_curriculum_items(query)

        # or when more than 3 characters were typed
        String.length(query) > 3 ->
          Curricula.search_curriculum_items(query)

        true ->
          []
      end

    results_simplified = Enum.map(results, fn ci -> %{id: ci.id} end)

    socket =
      socket
      |> stream(:results, results, reset: true)
      |> push_event("autocomplete_search_results:#{socket.assigns.id}", %{
        results: results_simplified
      })

    {:noreply, socket}
  end

  def handle_event("autocomplete_result_select", %{"id" => id}, socket) do
    selected = Curricula.get_curriculum_item!(id, preloads: :curriculum_component)
    send_update(socket.assigns.notify_component, action: {__MODULE__, {:selected, selected}})

    socket =
      socket
      |> stream(:results, [], reset: true)

    {:noreply, socket}
  end
end
