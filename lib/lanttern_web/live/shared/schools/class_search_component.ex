defmodule LantternWeb.Schools.ClassSearchComponent do
  @moduledoc """
  Renders a `Class` search component.

  ### Supported attrs

  - `label` - string
  - `notify_component`/`notify_parent`
  - `school_id` - filter search results by school
  - `class` - any
  - `refocus_on_select` - string. `"false"` (default) or `"true"`
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.label :if={@label} for={@id}>
        {@label}
      </.label>
      <div class="relative">
        <.base_input
          id={@id}
          name="query"
          type="text"
          value=""
          class="peer pr-10"
          role="combobox"
          autocomplete="off"
          aria-controls="class-search-controls"
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
            "absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-hidden sm:text-sm hidden",
            "peer-aria-expanded:block"
          ]}
          id="class-search-controls"
          role="listbox"
          phx-update="stream"
        >
          <li
            :for={{dom_id, class} <- @streams.classes}
            class={[
              "flex items-center cursor-default select-none py-2 px-3 text-ltrn-dark group",
              "data-[active=true]:bg-ltrn-primary"
            ]}
            id={dom_id}
            role="option"
            aria-selected="false"
            tabindex="-1"
            data-result-id={class.id}
            data-result-name={class.name}
          >
            <div class="flex-1 truncate group-aria-selected:font-bold" }>
              {class.name} ({class.cycle.name})
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

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:label, nil)
      |> assign(:class, nil)
      |> assign(:school_id, nil)
      |> assign(:refocus_on_select, "false")
      |> stream(:classes, [])

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    opts =
      if socket.assigns.school_id do
        [schools_ids: [socket.assigns.school_id]]
      else
        []
      end

    # search when more than 3 characters were typed
    classes =
      if String.length(query) > 3,
        do: Schools.search_classes(query, opts),
        else: []

    results_simplified = Enum.map(classes, &%{id: &1.id})

    socket =
      socket
      |> stream(:classes, classes, reset: true)
      |> push_event("autocomplete_search_results:#{socket.assigns.id}", %{
        results: results_simplified
      })

    {:noreply, socket}
  end

  def handle_event("autocomplete_result_select", %{"id" => id}, socket) do
    selected = Schools.get_class!(id, preloads: [:years, :cycle])

    notify(
      __MODULE__,
      {:selected, selected},
      socket.assigns
    )

    socket =
      socket
      |> stream(:classes, [], reset: true)

    {:noreply, socket}
  end
end
