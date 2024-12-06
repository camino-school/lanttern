defmodule LantternWeb.NeoComponents do
  @moduledoc """
  Provides neo core components.

  We might replace core components in the future with this module.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  alias Lanttern.Identity.User

  import LantternWeb.CoreComponents, only: [icon: 1]

  @doc """
  Renders the page header.
  """
  attr :current_user, User, required: true

  slot :title, required: true
  slot :inner_block

  slot :breadcrumb do
    attr :navigate, :string
  end

  def neo_header(assigns) do
    has_breadcrumb = assigns.breadcrumb != []

    %{school_name: school_name, current_school_cycle: current_cycle} =
      assigns.current_user.current_profile

    assigns =
      assigns
      |> assign(:has_breadcrumb, has_breadcrumb)
      |> assign(:school_name, school_name)
      |> assign(:current_cycle, current_cycle)

    ~H"""
    <header class="sticky top-0 z-20 bg-white ltrn-bg-main shadow-lg">
      <div class="flex items-center gap-4 p-4">
        <%!-- min-w-0 to "fix" truncate (https://css-tricks.com/flexbox-truncated-text/) --%>
        <div class="flex-1 flex gap-2 min-w-0 font-display font-black text-lg">
          <%= for breadcrumb <- @breadcrumb do %>
            <.link
              navigate={breadcrumb.navigate}
              class="text-ltrn-subtle truncate hover:text-ltrn-dark"
            >
              <%= render_slot(breadcrumb) %>
            </.link>
            <span class="text-ltrn-subtle">/</span>
          <% end %>
          <h1 class="truncate"><%= render_slot(@title) %></h1>
        </div>
        <button
          type="button"
          class="flex gap-2 items-center hover:text-ltrn-subtle"
          phx-click={JS.exec("data-show", to: "#menu")}
          aria-label="open menu"
        >
          <p class="font-display font-bold">
            <%= "#{@school_name}" %>
            <span :if={@current_cycle}><%= @current_cycle.name %></span>
          </p>
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
  attr :theme, :string, default: "default"
  attr :type, :string, required: true, doc: "link | button"
  attr :icon_name, :string, default: nil
  attr :patch, :string, default: nil, doc: "use with type=\"link\""
  attr :navigate, :string, default: nil, doc: "use with type=\"link\""
  attr :is_active, :boolean, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def neo_action(%{type: "button"} = assigns) do
    ~H"""
    <button type="button" class={[neo_action_styles(assigns), @class]} {@rest}>
      <div class={neo_action_bar_styles(@theme)}></div>
      <span class="relative truncate"><%= render_slot(@inner_block) %></span>
      <.icon :if={@icon_name} name={@icon_name} class="relative shrink-0 w-5 h-5" />
    </button>
    """
  end

  def neo_action(%{type: "link"} = assigns) do
    ~H"""
    <.link patch={@patch} navigate={@navigate} class={[neo_action_styles(assigns), @class]}>
      <div class={neo_action_bar_styles(@theme)}></div>
      <span class="relative truncate"><%= render_slot(@inner_block) %></span>
      <.icon :if={@icon_name} name={@icon_name} class="relative shrink-0 w-5 h-5" />
    </.link>
    """
  end

  @action_themes %{
    "default" => "text-ltrn-dark hover:text-ltrn-subtle",
    "student" => "text-ltrn-student-dark hover:text-ltrn-student-dark/80",
    "teacher" => "text-ltrn-teacher-dark hover:text-ltrn-teacher-dark/80"
  }

  @action_bar_themes %{
    "default" => nil,
    "student" => "bg-ltrn-student-lightest",
    "teacher" => "bg-ltrn-teacher-lightest"
  }

  defp neo_action_styles(assigns) do
    other_classes =
      case assigns.is_active do
        true -> "text-ltrn-primary hover:text-ltrn-subtle"
        false -> "text-ltrn-subtle hover:text-ltrn-dark"
        _ -> Map.get(@action_themes, assigns.theme)
      end

    "relative flex items-center gap-2 min-w-0 #{other_classes}"
  end

  defp neo_action_bar_styles(theme),
    do: "absolute inset-x-0 bottom-0 h-2 #{Map.get(@action_bar_themes, theme)}"

  @doc """
  Util function to help with action item text formating
  """

  def format_neo_action_items_text(items, default_text, key \\ :name, separator \\ ", ")

  def format_neo_action_items_text([] = _items, default_text, _, _), do: default_text

  def format_neo_action_items_text(items, _, key, separator),
    do: Enum.map_join(items, separator, &Map.get(&1, key))
end
