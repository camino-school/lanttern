defmodule LantternWeb.CurriculumItemSearchInputComponent do
  use LantternWeb, :live_component

  # attr :field, Phoenix.HTML.FormField, required: true

  def render(assigns) do
    ~H"""
    <div>
      <label for="combobox" class="block text-sm font-medium leading-6 text-gray-900">
        Assigned to
      </label>
      <div class="relative mt-2">
        <input
          id="curriculum-item-search-input"
          name="query"
          type="text"
          class="peer w-full rounded-md border-0 bg-white py-1.5 pl-3 pr-12 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
          role="combobox"
          autocomplete="off"
          aria-controls="curriculum-item-search-controls"
          aria-expanded="false"
          phx-hook="Autocomplete"
          phx-change="search"
          phx-debounce="200"
          phx-target={@myself}
          phx-update="ignore"
          data-reset-value-input="selected-curriculum-item-name"
        />
        <button
          type="button"
          class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none"
        >
          <.icon name="hero-chevron-up-down" class="text-ltrn-subtle" />
        </button>

        <ul
          class={[
            "absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm invisible",
            "peer-aria-expanded:visible"
          ]}
          id="curriculum-item-search-controls"
          role="listbox"
          phx-update="stream"
        >
          <li
            :for={{dom_id, result} <- @streams.results}
            class={[
              "relative cursor-default select-none py-2 pl-3 pr-9 text-gray-900 group",
              "data-[active=true]:bg-cyan-400"
            ]}
            id={dom_id}
            role="option"
            aria-selected={if @field.value == "#{result.id}", do: "true", else: "false"}
            tabindex="-1"
            data-result-id={result.id}
            data-result-name={result.name}
          >
            <span class="block truncate group-aria-selected:font-bold" }>
              <%= result.name %>
            </span>
            <span class={[
              "absolute inset-y-0 right-0 flex items-center pr-4 text-ltrn-primary invisible",
              "group-aria-selected:visible group-data-[active=true]:text-white"
            ]}>
              <.icon name="hero-check" />
            </span>
          </li>
        </ul>
      </div>
      <input name={@field.name} type="text" value={@field.value} readonly />
      <input id="selected-curriculum-item-name" type="hidden" phx-update="ignore" />
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> stream(:results, [])

    {:ok, socket}
  end

  # event handlers

  def handle_event("search", %{"query" => query}, socket) do
    results =
      [
        %{id: 1, name: "lorem ipsum"},
        %{id: 2, name: "lorem ipsum dolor sit amet"},
        %{id: 3, name: "lorem ipsum consectur blah"},
        %{id: 4, name: "dolor sit amet"},
        %{id: 5, name: "zzz"}
      ]
      |> Enum.filter(&(query != "" and &1.name =~ query))

    socket =
      socket
      |> stream(:results, results, reset: true)
      |> push_event("autocomplete_search_results", %{results: results})

    {:noreply, socket}
  end

  def handle_event("autocomplete_result_select", %{"id" => id, "name" => name}, socket) do
    IO.inspect("autocomplete_result_select")

    socket =
      socket
      |> stream(:results, [%{id: id, name: name}], reset: true)
      |> update(:field, fn field ->
        Map.put(field, :value, id)
      end)

    {:noreply, socket}
  end
end
