defmodule LantternWeb.Schools.StaffMemberSearchComponent do
  @moduledoc """
  Renders a `StaffMember` search component
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
          name={"#{@id}-query"}
          type="text"
          value=""
          class="peer pr-10"
          role="combobox"
          autocomplete="off"
          aria-controls="staff-member-search-controls"
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
          id="staff-member-search-controls"
          role="listbox"
          phx-update="stream"
        >
          <li
            :for={{dom_id, result} <- @streams.results}
            class={[
              "flex items-center cursor-default select-none py-2 px-3 text-ltrn-dark group",
              "data-[active=true]:bg-ltrn-lightest"
            ]}
            id={dom_id}
            role="option"
            aria-selected="false"
            tabindex="-1"
            data-result-id={result.id}
            data-result-name={result.name}
          >
            <div class="flex-1 truncate group-aria-selected:font-bold" }>
              {result.name}
            </div>
            <.icon
              name="hero-check"
              class={[
                "shrink-0 ml-2 text-ltrn-primary hidden",
                "group-aria-selected:block group-data-[active=true]:text-ltrn-subtle"
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
      |> stream(:results, [])

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("search", params, socket) do
    query = Map.get(params, "#{socket.assigns.id}-query", "")
    search_opts = if socket.assigns.school_id, do: [school_id: socket.assigns.school_id], else: []
    # search when 3 or more characters were typed
    results =
      if String.length(query) >= 3,
        do: Schools.search_staff_members(query, search_opts),
        else: []

    results_simplified = Enum.map(results, fn s -> %{id: s.id} end)

    socket =
      socket
      |> stream(:results, results, reset: true)
      |> push_event("autocomplete_search_results:#{socket.assigns.id}", %{
        results: results_simplified
      })

    {:noreply, socket}
  end

  def handle_event("autocomplete_result_select", %{"id" => id}, socket) do
    selected = Schools.get_staff_member!(id)

    notify(
      __MODULE__,
      {:selected, selected},
      socket.assigns
    )

    socket =
      socket
      |> stream(:results, [], reset: true)

    {:noreply, socket}
  end
end
