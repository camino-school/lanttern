defmodule LantternWeb.LearningContext.StrandSearchComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext

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
              "flex items-center gap-4 p-4 mt-4 rounded font-display",
              if(@selected_strands_ids && strand.id in @selected_strands_ids,
                do: "bg-ltrn-lighter",
                else: "bg-white shadow-lg"
              )
            ]}
            id={dom_id}
          >
            <div class="flex-1">
              <p class="font-black"><%= strand.name %></p>
              <p :if={strand.type} class="text-sm text-ltrn-subtle"><%= strand.type %></p>
              <div class="flex flex-wrap gap-1 mt-4">
                <.badge :for={subject <- strand.subjects}><%= subject.name %></.badge>
                <.badge :for={year <- strand.years}><%= year.name %></.badge>
              </div>
            </div>
            <%= if @selected_strands_ids && strand.id in @selected_strands_ids do %>
              <div class="shrink-0 group relative block text-ltrn-subtle">
                <.icon name="hero-check-circle" class="w-10 h-10" />
                <.tooltip h_pos="right"><%= gettext("Already selected") %></.tooltip>
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
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def wrapper(%{render_form: true} = assigns) do
    ~H"""
    <form>
      <%= render_slot(@inner_block) %>
    </form>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:render_form, false)
      |> assign(:selected_strands_ids, nil)
      |> stream(:results, [])

    {:ok, socket}
  end

  # event handlers

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

  def handle_event("select", %{"id" => id}, socket) do
    notify_component(
      __MODULE__,
      {:strand_selected, id},
      socket.assigns
    )

    {:noreply, socket}
  end
end
