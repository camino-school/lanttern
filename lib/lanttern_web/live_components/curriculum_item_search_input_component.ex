defmodule LantternWeb.CurriculumItemSearchInputComponent do
  alias LantternWeb.CoreComponents
  use LantternWeb, :live_component

  # attr :field, Phoenix.HTML.FormField, required: true

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.label for="curriculum-item-search-input">Curriculum item</.label>
      <div phx-feedback-for={@field.name} class="relative">
        <.base_input
          id="curriculum-item-search-input"
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
          phx-debounce="200"
          phx-target={@myself}
          phx-update="ignore"
          errors={@errors}
        />
        <.icon name="hero-chevron-up-down" class="absolute top-2.5 right-2.5 text-ltrn-subtle" />
        <.badge
          :if={@selected}
          class="mt-2"
          theme="cyan"
          show_remove
          phx-click="remove_curriculum_item"
          phx-target={@myself}
        >
          <%= @selected %>
        </.badge>
        <.error :for={msg <- @errors}><%= msg %></.error>

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
              "flex items-center cursor-default select-none py-2 px-3 text-ltrn-text group",
              "data-[active=true]:bg-ltrn-primary"
            ]}
            id={dom_id}
            role="option"
            aria-selected={if @field.value == "#{result.id}", do: "true", else: "false"}
            tabindex="-1"
            data-result-id={result.id}
            data-result-name={result.name}
          >
            <span class="flex-1 truncate group-aria-selected:font-bold" }>
              <%= result.name %>
            </span>
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
      <input name={@field.name} type="hidden" value={@field.value} />
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> stream(:results, [])
      |> assign(:selected, nil)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(:class, Map.get(assigns, :class, ""))
      |> assign(:field, assigns.field)
      |> assign(:errors, Enum.map(assigns.field.errors, &CoreComponents.translate_error/1))

    {:ok, socket}
  end

  # event handlers

  def handle_event("search", %{"query" => query}, socket) do
    results =
      [
        %{id: 1, name: "lorem ipsum"},
        %{id: 2, name: "lorem ipsum dolor sit amet"},
        %{
          id: 3,
          name: "lorem ipsum consectur blah lorem ipsum consectur blah lorem ipsum consectur blah"
        },
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
    socket =
      socket
      |> stream(:results, [], reset: true)
      |> assign(:selected, name)
      |> update(:field, fn field ->
        Map.put(field, :value, id)
      end)

    {:noreply, socket}
  end

  def handle_event("remove_curriculum_item", _params, socket) do
    socket =
      socket
      |> assign(:selected, nil)
      |> update(:field, fn field ->
        Map.put(field, :value, nil)
      end)

    {:noreply, socket}
  end
end
