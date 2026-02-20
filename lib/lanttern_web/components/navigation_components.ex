defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  @doc """
  Renders the page header with navigation items.
  """
  attr :current_user, Lanttern.Identity.User, required: true
  attr :menu_style, :string, default: "basic", doc: "basic | legacy"

  slot :title, required: true
  slot :inner_block

  slot :breadcrumb do
    attr :navigate, :string
    attr :title, :string

    attr :is_info, :boolean,
      doc: "use this attr to render an info icon before the item with hover interaction"
  end

  def header_nav(assigns) do
    has_breadcrumb = assigns.breadcrumb != []

    first_breadcrumb =
      case assigns.breadcrumb do
        [first | _] -> first
        _ -> nil
      end

    %{school_name: school_name, current_school_cycle: current_cycle} =
      assigns.current_user.current_profile

    assigns =
      assigns
      |> assign(:has_breadcrumb, has_breadcrumb)
      |> assign(:first_breadcrumb, first_breadcrumb)
      |> assign(:school_name, school_name)
      |> assign(:current_cycle, current_cycle)

    ~H"""
    <header class="sticky top-0 z-30 bg-white ltrn-bg-main shadow-lg">
      <div class="flex items-center gap-4 p-4">
        <%!-- min-w-0 to "fix" truncate (https://css-tricks.com/flexbox-truncated-text/) --%>
        <div class="flex-1 flex items-center gap-2 min-w-0">
          <%!-- back button for responsive only --%>
          <.link
            :if={@first_breadcrumb}
            navigate={@first_breadcrumb.navigate}
            class="sm:hidden text-ltrn-dark hover:text-ltrn-subtle"
            title={Map.get(@first_breadcrumb, :title)}
          >
            <.icon name="hero-chevron-left" />
          </.link>
          <%= for breadcrumb <- @breadcrumb do %>
            <%= if Map.get(breadcrumb, :is_info) do %>
              <.breadcrumb_floating_info>
                {render_slot(breadcrumb)}
              </.breadcrumb_floating_info>
            <% else %>
              <.link
                navigate={breadcrumb.navigate}
                class="hidden sm:block max-w-60 font-display font-black text-lg text-ltrn-subtle truncate hover:text-ltrn-dark"
                title={Map.get(breadcrumb, :title)}
              >
                {render_slot(breadcrumb)}
              </.link>
              <span class="hidden sm:block font-display font-black text-lg text-ltrn-subtle">/</span>
            <% end %>
          <% end %>
          <h1 class="font-display font-black text-lg truncate">{render_slot(@title)}</h1>
        </div>
        <.nav_menu_button :if={@menu_style == "legacy"} />
        <button
          :if={@menu_style != "legacy"}
          type="button"
          class="flex gap-2 items-center hover:text-ltrn-subtle"
          phx-click={JS.exec("data-show", to: "#menu")}
          aria-label="open menu"
        >
          <p class="font-display font-bold">
            {"#{@school_name}"} <span :if={@current_cycle}>{@current_cycle.name}</span>
          </p>
          <.icon name="hero-bars-3-mini" class="w-5 h-5" />
        </button>
      </div>
      {render_slot(@inner_block)}
    </header>
    """
  end

  defp breadcrumb_floating_info(assigns) do
    ~H"""
    <div class="group relative" tabindex="0">
      <.icon
        name="hero-information-circle-mini"
        class="text-ltrn-dark group-hover:text-ltrn-subtle group-focus:text-ltrn-subtle"
      />
      <div class="hidden absolute top-[calc(100%+0.5rem)] left-0 z-10 group-hover:block group-focus:block">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders navigation tabs.

  ## Examples

      <.nav_tabs>
        <:tab patch={~p"/home"}>Home</:tab>
        <:tab patch={~p"/page-1"} is_current="true">Page 1</:tab>
        <:tab patch={~p"/page-2"}>Page 2</:tab>
      </.nav_tabs>

  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  slot :tab, required: true do
    attr :patch, :string
    attr :navigate, :string
    attr :is_current, :boolean
    attr :icon_name, :string
  end

  def nav_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-10", @class]} id={@id}>
      <%= for tab
      <-
        @tab
        do %>
        <.link
          patch={Map.get(tab, :patch)}
          navigate={Map.get(tab, :navigate)}
          class={[
            "relative shrink-0 flex items-center gap-2 py-5 font-display text-base whitespace-nowrap",
            if(Map.get(tab, :is_current),
              do: "font-bold",
              else: "hover:text-ltrn-subtle"
            )
          ]}
        >
          {render_slot(tab)}
          <.icon :if={Map.get(tab, :icon_name)} name={Map.get(tab, :icon_name)} class="w-6 h-6" />
          <span
            :if={Map.get(tab, :is_current)}
            class="absolute h-2 bg-ltrn-primary inset-x-0 bottom-0"
          />
        </.link>
      <% end %>
    </nav>
    """
  end

  @doc """
  Renders a student or staff member tab.

  ## Examples

      <.person_tab person={student} />

  """
  attr :id, :string, default: nil
  attr :person, :map, required: true
  attr :container_selector, :string, required: true
  attr :theme, :string, default: "default", doc: "default | cyan | diff"
  attr :on_click, JS, default: %JS{}
  attr :rest, :global, doc: "aria-controls is required"

  def person_tab(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      role="tab"
      aria-selected="false"
      tabindex="-1"
      class={[
        "flex items-center gap-2 p-1 rounded-full focus:outline-ltrn-primary",
        "aria-selected:outline aria-selected:outline-2 aria-selected:outline-ltrn-dark",
        person_tab_theme(@theme)
      ]}
      phx-click={
        @on_click
        |> JS.hide(to: "#{@container_selector} div[role=tabpanel]")
        |> JS.set_attribute({"aria-selected", "false"},
          to: "#{@container_selector} button[role=tab]"
        )
        |> JS.show(to: "##{@rest[:"aria-controls"]}")
        |> JS.set_attribute({"aria-selected", "true"})
      }
      {@rest}
    >
      <.profile_icon profile_name={@person.name} size="xs" theme={@theme} />
      <span class="max-w-[7rem] pr-1 text-xs truncate">
        {@person.name}
      </span>
    </button>
    """
  end

  @person_tab_themes %{
    "default" => "text-ltrn-subtle bg-ltrn-lighter",
    "cyan" => "text-ltrn-dark bg-ltrn-mesh-cyan",
    "diff" => "text-ltrn-diff-accent bg-ltrn-diff-lightest"
  }

  defp person_tab_theme(theme),
    do: Map.get(@person_tab_themes, theme, @person_tab_themes["default"])

  @doc """
  Renders a breadcrumb.

  ## Examples

      <.person_tab person={student} />

  """
  attr :class, :any, default: nil
  attr :with_bg, :boolean, default: false
  attr :item_class, :any, default: nil

  slot :item, required: true do
    attr :link, :string
  end

  def breadcrumbs(assigns) do
    ~H"""
    <nav class={@class}>
      <ol class={[
        "flex items-center gap-2 font-display font-bold text-sm text-ltrn-subtle",
        if(@with_bg, do: "p-2 rounded-full bg-ltrn-dark/50")
      ]}>
        <li
          :for={{item, i} <- Enum.with_index(@item)}
          class={[
            @item_class,
            if(@with_bg, do: "text-white drop-shadow-xs"),
            if(Map.get(item, :link), do: "hidden sm:list-item")
          ]}
        >
          <span :if={i > 0} class="hidden sm:inline">/</span>
          <%= if Map.get(item, :link) do %>
            <.link navigate={item.link} class="underline">{render_slot(item)}</.link>
          <% else %>
            <span>{render_slot(item)}</span>
          <% end %>
        </li>
      </ol>
    </nav>
    """
  end

  @doc """
  Renders a expand/collapse button
  """

  attr :id, :string, required: true
  attr :target_selector, :string, required: true
  attr :initial_is_expanded, :boolean, default: true
  attr :class, :any, default: nil
  attr :theme, :string, default: "ghost"

  def toggle_expand_button(assigns) do
    ~H"""
    <div
      id={@id}
      class={@class}
      phx-mounted={
        if @initial_is_expanded,
          do: JS.hide(to: "##{@id} .toggle-expand"),
          else: JS.hide(to: "##{@id} .toggle-collapse")
      }
    >
      <.icon_button
        name="hero-arrows-pointing-in"
        class="toggle-collapse"
        theme={@theme}
        rounded
        sr_text={gettext("collapse")}
        phx-click={
          JS.toggle(to: @target_selector)
          |> JS.toggle(to: "##{@id} [data-toggle=true]")
        }
        data-toggle="true"
      />
      <.icon_button
        name="hero-arrows-pointing-out"
        class="toggle-expand"
        theme={@theme}
        rounded
        sr_text={gettext("expand")}
        phx-click={
          JS.toggle(to: @target_selector)
          |> JS.toggle(to: "##{@id} [data-toggle=true]")
        }
        data-toggle="true"
      />
    </div>
    """
  end

  @doc """
  Renders a collapsible section with a title and expandable content.

  ## Examples

      <.collapsible_section id="my-section" title="Section Title" initial_expanded={true}>
        <p>Content goes here</p>
      </.collapsible_section>

  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :initial_expanded, :boolean, default: true
  slot :inner_block, required: true

  def collapsible_section(assigns) do
    ~H"""
    <div class="border-b border-ltrn-lighter">
      <button
        type="button"
        class="flex items-center justify-between w-full p-4 hover:bg-ltrn-lightest transition-colors"
        aria-expanded={@initial_expanded |> to_string()}
        aria-controls={"#{@id}-content"}
        phx-click={
          JS.toggle(to: "##{@id}-content")
          |> JS.toggle(to: "##{@id}-icon-expanded")
          |> JS.toggle(to: "##{@id}-icon-collapsed")
          |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button-toggle")
        }
        id={"#{@id}-button-toggle"}
      >
        <h3 class="font-display font-bold text-lg">{@title}</h3>
        <div>
          <.icon
            id={"#{@id}-icon-expanded"}
            name="hero-arrows-pointing-in"
            class={["w-5 h-5", unless(@initial_expanded, do: "hidden")]}
          />
          <.icon
            id={"#{@id}-icon-collapsed"}
            name="hero-arrows-pointing-out"
            class={["w-5 h-5", if(@initial_expanded, do: "hidden")]}
          />
        </div>
      </button>
      <div
        id={"#{@id}-content"}
        class={unless @initial_expanded, do: "hidden"}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
