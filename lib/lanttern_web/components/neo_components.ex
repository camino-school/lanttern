defmodule LantternWeb.NeoComponents do
  @moduledoc """
  Provides neo core components.

  We might replace core components in the future with this module.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import LantternWeb.CoreComponents, only: [icon: 1]

  # @doc """
  # Renders a breadcrumb.

  # ## Examples

  #     <.person_tab person={student} />

  # """
  # attr :class, :any, default: nil
  # attr :with_bg, :boolean, default: false
  # attr :item_class, :any, default: nil

  # slot :item, required: true do
  #   attr :link, :string
  # end

  # def breadcrumbs(assigns) do
  #   ~H"""
  #   <nav class={@class}>
  #     <ol class={[
  #       "flex items-center gap-2 font-display font-bold text-sm text-ltrn-subtle",
  #       if(@with_bg, do: "p-2 rounded-full bg-ltrn-dark/50")
  #     ]}>
  #       <li
  #         :for={{item, i} <- Enum.with_index(@item)}
  #         class={[
  #           @item_class,
  #           if(@with_bg, do: "text-white drop-shadow-sm"),
  #           if(Map.get(item, :link), do: "hidden sm:list-item")
  #         ]}
  #       >
  #         <span :if={i > 0} class="hidden sm:inline">/</span>
  #         <%= if Map.get(item, :link) do %>
  #           <.link navigate={item.link} class="underline"><%= render_slot(item) %></.link>
  #         <% else %>
  #           <span><%= render_slot(item) %></span>
  #         <% end %>
  #       </li>
  #     </ol>
  #   </nav>
  #   """
  # end

  @doc """
  Renders the page header.
  """
  attr :school_name, :string, required: true

  slot :title, required: true
  slot :inner_block

  slot :breadcrumb do
    attr :link, :string
  end

  def neo_header(assigns) do
    has_breadcrumb = assigns.breadcrumb != []

    assigns =
      assigns
      |> assign(:has_breadcrumb, has_breadcrumb)

    ~H"""
    <header class="sticky top-0 z-20 bg-white ltrn-bg-main shadow-lg">
      <div class="flex items-center gap-2 p-4">
        <h1 class="flex-1 font-display font-black text-lg"><%= render_slot(@title) %></h1>

        <button
          type="button"
          class="flex gap-2 items-center hover:text-ltrn-subtle"
          phx-click={JS.exec("data-show", to: "#menu")}
          aria-label="open menu"
        >
          <p class="font-display font-bold"><%= "#{@school_name} 2024" %></p>
          <.icon name="hero-bars-3-mini" class="w-5 h-5" />
        </button>
      </div>
      <%= render_slot(@inner_block) %>
    </header>
    """
  end

  @doc """
  Renders navigation tabs.

  ## Examples

      <.neo_tabs>
        <:tab patch={~p"/home"}>Home</:tab>
        <:tab patch={~p"/page-1"} is_current="true">Page 1</:tab>
        <:tab patch={~p"/page-2"}>Page 2</:tab>
      </.neo_tabs>

  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  slot :tab, required: true do
    attr :patch, :string
    attr :navigate, :string
    attr :is_current, :boolean
  end

  def neo_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-6", @class]} id={@id}>
      <.link
        :for={tab <- @tab}
        patch={Map.get(tab, :patch)}
        navigate={Map.get(tab, :navigate)}
        class={[
          "relative shrink-0 py-4 font-display font-bold whitespace-nowrap",
          if(Map.get(tab, :is_current),
            do: "text-ltrn-dark",
            else: "text-ltrn-subtle hover:text-ltrn-dark"
          )
        ]}
      >
        <%= render_slot(tab) %>
        <span :if={Map.get(tab, :is_current)} class="absolute h-1 bg-ltrn-dark inset-x-0 bottom-0" />
      </.link>
    </nav>
    """
  end

  @doc """
  Renders a `<button>` or `<.link>` with icon.

  Usually used in the context of a collection (e.g. to add a new item to a list).
  """

  attr :class, :any, default: nil
  attr :type, :string, required: true, doc: "link | button"
  attr :icon_name, :string, default: nil
  attr :patch, :string, default: nil, doc: "use with type=\"link\""
  attr :navigate, :string, default: nil, doc: "use with type=\"link\""
  attr :rest, :global

  slot :inner_block, required: true

  def neo_action(%{type: "button"} = assigns) do
    ~H"""
    <button type="button" class={[neo_action_styles(), @class]} {@rest}>
      <span class="truncate"><%= render_slot(@inner_block) %></span>
      <.icon :if={@icon_name} name={@icon_name} class="shrink-0 w-5 h-5" />
    </button>
    """
  end

  def neo_action(%{type: "link"} = assigns) do
    ~H"""
    <.link patch={@patch} navigate={@navigate} class={[neo_action_styles(), @class]}>
      <span class="truncate"><%= render_slot(@inner_block) %></span>
      <.icon :if={@icon_name} name={@icon_name} class="shrink-0 w-5 h-5" />
    </.link>
    """
  end

  defp neo_action_styles(),
    do: "flex items-center gap-2 min-w-0 text-ltrn-dark hover:text-ltrn-subtle"

  def format_neo_action_items_text(items, default_text, key \\ :name, separator \\ ", ")

  def format_neo_action_items_text(_items = [], default_text, _, _), do: default_text

  def format_neo_action_items_text(items, _, key, separator),
    do: Enum.map_join(items, separator, &Map.get(&1, key))
end
