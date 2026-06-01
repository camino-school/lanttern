defmodule LantternWeb.LearningContext.StrandSearchComponent do
  @moduledoc """
  Renders a `Strand` search component.

  Two presentations are supported:

    * default — a persistent results list (used to pick strands into a list, with
      `selected_strands_ids` highlighting already-picked ones)
    * combobox (`is_combobox`) — a single-select input with a floating dropdown;
      once a strand is picked it collapses to the chosen name with a clear button

  Selection is delivered through `notify/3`, so it reaches either a parent
  `LiveComponent` (`notify_component`) or a parent `LiveView` (`notify_parent`).
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  def render(%{is_combobox: true} = assigns) do
    ~H"""
    <div class={@class}>
      <div :if={@selected_strand} class="flex items-center gap-4 p-4 rounded-sm bg-ltrn-lighter">
        <div class="flex-1 font-display">
          <p class="font-black">{@selected_strand.name}</p>
          <p :if={@selected_strand.type} class="text-sm text-ltrn-subtle">{@selected_strand.type}</p>
        </div>
        <button
          type="button"
          class="shrink-0 block text-ltrn-subtle hover:text-ltrn-primary"
          phx-click={JS.push("clear", target: @myself)}
          aria-label={gettext("Clear selected strand")}
        >
          <.icon name="hero-x-mark" class="w-6 h-6" />
        </button>
      </div>
      <form
        :if={is_nil(@selected_strand)}
        id={"#{@id}-form"}
        class="relative"
        phx-change="search"
        phx-target={@myself}
      >
        <.base_input
          id={@id}
          name="query"
          type="text"
          value=""
          class="peer pr-10"
          role="combobox"
          autocomplete="off"
          placeholder={gettext("Search strands by name...")}
          aria-controls={"#{@id}-results"}
          aria-expanded="false"
          phx-hook="Autocomplete"
          phx-target={@myself}
          phx-debounce="500"
          phx-update="ignore"
          data-refocus-on-select="false"
        />
        <.icon
          name="hero-magnifying-glass"
          class="absolute top-2.5 right-2.5 text-ltrn-subtle peer-phx-change-loading:hidden"
        />
        <div class="hidden absolute top-3 right-3 peer-phx-change-loading:block">
          <.ping />
        </div>
        <ul
          id={"#{@id}-results"}
          role="listbox"
          phx-update="stream"
          class={[
            "absolute z-10 left-0 right-0 mt-2 max-h-80 overflow-y-auto rounded-sm bg-white shadow-lg",
            "hidden peer-aria-expanded:block"
          ]}
        >
          <li
            :for={{dom_id, strand} <- @streams.results}
            id={dom_id}
            role="option"
            aria-selected="false"
            tabindex="-1"
            data-result-id={strand.id}
            data-result-name={strand.name}
            class={[
              "flex items-center gap-4 p-4 font-display cursor-default select-none",
              "border-b border-ltrn-lighter last:border-b-0 data-[active=true]:bg-ltrn-lighter"
            ]}
          >
            <div class="flex-1">
              <p class="font-black">{strand.name}</p>
              <p :if={strand.type} class="text-sm text-ltrn-subtle">{strand.type}</p>
              <div class="flex flex-wrap gap-1 mt-4">
                <.badge :for={subject <- strand.subjects}>{subject.name}</.badge>
                <.badge :for={year <- strand.years}>{year.name}</.badge>
              </div>
            </div>
          </li>
        </ul>
      </form>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.wrapper render_form={@render_form}>
        <div class="relative">
          <.base_input
            id={@id}
            name="query"
            type="text"
            value=""
            class="peer pr-10"
            autocomplete="off"
            phx-change="search"
            phx-debounce="500"
            phx-target={@myself}
            phx-update="ignore"
          />
          <.icon
            name="hero-magnifying-glass"
            class="absolute top-2.5 right-2.5 text-ltrn-subtle peer-phx-change-loading:hidden"
          />
          <div class="hidden absolute top-3 right-3 peer-phx-change-loading:block">
            <.ping />
          </div>
        </div>
        <ul>
          <li
            :for={{dom_id, strand} <- @streams.results}
            class={[
              "flex items-center gap-4 p-4 mt-4 rounded-sm font-display",
              if(@selected_strands_ids && strand.id in @selected_strands_ids,
                do: "bg-ltrn-lighter",
                else: "bg-white shadow-lg"
              )
            ]}
            id={dom_id}
          >
            <div class="flex-1">
              <p class="font-black">{strand.name}</p>
              <p :if={strand.type} class="text-sm text-ltrn-subtle">{strand.type}</p>
              <div class="flex flex-wrap gap-1 mt-4">
                <.badge :for={subject <- strand.subjects}>{subject.name}</.badge>
                <.badge :for={year <- strand.years}>{year.name}</.badge>
              </div>
            </div>
            <%= if @selected_strands_ids && strand.id in @selected_strands_ids do %>
              <div class="shrink-0 block text-ltrn-subtle">
                <.icon name="hero-check-circle" class="w-10 h-10" />
                <.tooltip id={"#{dom_id}-selected-tooltip"}>{gettext("Already selected")}</.tooltip>
              </div>
            <% else %>
              <button
                type="button"
                class="shrink-0 block text-ltrn-subtle hover:text-ltrn-primary"
                phx-click={JS.push("select", value: %{id: strand.id}, target: @myself)}
              >
                <.icon name="hero-check-circle" class="w-10 h-10" />
              </button>
            <% end %>
          </li>
        </ul>
      </.wrapper>
    </div>
    """
  end

  # function components

  attr :render_form, :boolean, required: true
  slot :inner_block, required: true

  def wrapper(%{render_form: false} = assigns) do
    ~H"""
    <div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def wrapper(%{render_form: true} = assigns) do
    ~H"""
    <form>
      {render_slot(@inner_block)}
    </form>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:render_form, false)
      |> assign(:is_combobox, false)
      |> assign(:selected_strand, nil)
      |> assign(:selected_strands_ids, nil)
      |> stream(:results, [])

    {:ok, socket}
  end

  # event handlers

  # combobox keeps the client-side `Autocomplete` hook in sync with the ordered
  # result ids so keyboard navigation knows what's on screen
  def handle_event("search", %{"query" => query}, %{assigns: %{is_combobox: true}} = socket) do
    results =
      if String.length(query) > 3,
        do: LearningContext.search_strands(query, preloads: [:subjects, :years]),
        else: []

    socket =
      socket
      |> stream(:results, results, reset: true)
      |> push_event("autocomplete_search_results:#{socket.assigns.id}", %{
        results: Enum.map(results, &%{id: &1.id})
      })

    {:noreply, socket}
  end

  def handle_event("search", %{"query" => query}, socket) do
    socket =
      case String.length(query) > 3 do
        true ->
          results = LearningContext.search_strands(query, preloads: [:subjects, :years])

          socket
          |> stream(:results, results, reset: true)

        false ->
          socket
      end

    {:noreply, socket}
  end

  # combobox selection comes from the `Autocomplete` hook (mouse or keyboard)
  def handle_event("autocomplete_result_select", %{"id" => id}, socket) do
    strand_id = ensure_integer(id)
    notify(__MODULE__, {:strand_selected, strand_id}, socket.assigns)

    socket =
      socket
      |> assign(:selected_strand, LearningContext.get_strand(strand_id))
      |> stream(:results, [], reset: true)

    {:noreply, socket}
  end

  # default (non-combobox) selection comes from the per-result button
  def handle_event("select", %{"id" => id}, socket) do
    notify(__MODULE__, {:strand_selected, id}, socket.assigns)

    {:noreply, socket}
  end

  def handle_event("clear", _params, socket) do
    notify(__MODULE__, {:strand_selected, nil}, socket.assigns)

    socket =
      socket
      |> assign(:selected_strand, nil)
      |> stream(:results, [], reset: true)

    {:noreply, socket}
  end

  defp ensure_integer(id) when is_integer(id), do: id
  defp ensure_integer(id) when is_binary(id), do: String.to_integer(id)
end
