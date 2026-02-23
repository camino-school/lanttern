defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents

  @doc """
  Renders a basic page header.
  """
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def header_base(assigns) do
    ~H"""
    <header class={["sticky top-0 z-30 bg-white/80 backdrop-blur-sm", @class]}>
      {render_slot(@inner_block)}
    </header>
    """
  end

  @doc """
  Renders the page header with navigation items.
  """
  attr :current_user, Lanttern.Identity.User, required: true
  attr :menu_style, :string, default: "basic", doc: "basic | legacy"

  slot :title, required: true
  slot :action
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
    <.header_base>
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
          {render_slot(@action)}
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
    </.header_base>
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
        "aria-selected:outline-2 aria-selected:outline-ltrn-dark",
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
      <span class="max-w-28 pr-1 text-xs truncate">
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
  Renders a side navigation panel.

  ## Examples

      <.side_nav title="Some page">
        Custom content
      </.settings_side_nav>

  """
  attr :id, :string, default: nil
  attr :menu_title, :string, default: nil
  attr :collapsible, :boolean, default: false

  slot :inner_block, required: true

  def side_nav(assigns) do
    ~H"""
    <nav
      id={@id}
      class="fixed top-0 left-0 w-70 h-screen overflow-y-auto bg-white ltrn-bg-side transition-transform duration-300"
    >
      <button
        :if={@menu_title}
        type="button"
        class="flex gap-2.5 items-center ml-2.5 my-10 hover:text-ltrn-subtle"
        phx-click={JS.exec("data-show", to: "#menu")}
        aria-label="open menu"
      >
        <.icon name="hero-bars-3-mini" class="w-5 h-5" />
        <p class="font-display font-bold">{@menu_title}</p>
      </button>
      {render_slot(@inner_block)}
    </nav>
    <button
      :if={@collapsible}
      id={"#{@id}-toggle"}
      type="button"
      class="fixed top-1/2 -translate-y-1/2 left-70 z-40 flex items-center justify-center w-8 h-14 rounded-r-full bg-white shadow-xl hover:bg-ltrn-lighter transition-[left] duration-300"
      phx-click={toggle_side_nav(@id)}
      aria-label={gettext("toggle side navigation")}
    >
      <.icon name="hero-chevron-left-mini" class="-translate-x-1 toggle-collapse" />
      <.icon name="hero-chevron-right-mini" class="-translate-x-1 toggle-expand hidden" />
    </button>
    """
  end

  defp toggle_side_nav(id) do
    JS.toggle_class("-translate-x-full", to: "##{id}")
    |> JS.toggle_attribute({"inert", "true"}, to: "##{id}")
    |> JS.toggle_class("pl-70", to: "##{id}-layout")
    |> JS.toggle_class("left-70", to: "##{id}-toggle")
    |> JS.toggle_class("left-0", to: "##{id}-toggle")
    |> JS.toggle(to: "##{id}-toggle .toggle-collapse")
    |> JS.toggle(to: "##{id}-toggle .toggle-expand")
  end

  @doc """
  Renders a settings side navigation with grouped links.

  ## Examples

      <.settings_side_nav current_path={@current_path}>
        <:group title="AI Settings">
          <:link navigate={~p"/settings/agents"}>AI Agents</:link>
        </:group>
        <:group title="Content Settings">
          <:link navigate={~p"/settings/lesson_templates"}>Lesson Templates</:link>
        </:group>
      </.settings_side_nav>

  """
  attr :id, :string, default: nil
  attr :current_path, :string, required: true
  attr :collapsible, :boolean, default: false

  slot :group, required: true do
    attr :title, :string, required: true
    attr :icon_name, :string
  end

  slot :link do
    attr :navigate, :string, required: true
    attr :icon_name, :string
  end

  def settings_side_nav(assigns) do
    ~H"""
    <.side_nav id={@id} menu_title={gettext("Settings")} collapsible={@collapsible}>
      <div :for={group <- @group} class="mb-10">
        <h5 class="flex items-center gap-2 px-10 font-sans text-sm text-ltrn-subtle">
          <.icon :if={Map.get(group, :icon_name)} name={group.icon_name} class="w-4 h-4" />
          {group.title}
        </h5>
        <ul class="space-y-2 mt-4">
          {render_slot(group, @current_path)}
        </ul>
      </div>
    </.side_nav>
    """
  end

  @doc """
  Renders a settings side navigation link item.

  This component is used inside a `settings_side_nav` group.

  ## Examples

      <.settings_nav_link navigate={~p"/settings/agents"} current_path={@current_path}>
        AI Agents
      </.settings_nav_link>

  """
  attr :navigate, :string, required: true
  attr :current_path, :string, required: true
  attr :icon_name, :string, default: nil

  slot :inner_block, required: true

  def settings_nav_link(assigns) do
    is_current = String.starts_with?(assigns.current_path, assigns.navigate)
    assigns = assign(assigns, :is_current, is_current)

    ~H"""
    <li class={[
      "flex items-center gap-8"
    ]}>
      <div class={["w-2 self-stretch", if(@is_current, do: "bg-ltrn-darkest")]} />
      <.link
        navigate={@navigate}
        class={[
          "flex items-center gap-2",
          if(@is_current,
            do: "text-ltrn-darkest font-bold",
            else: "text-ltrn-subtle hover:text-ltrn-darkest"
          )
        ]}
      >
        <.icon :if={@icon_name} name={@icon_name} />
        {render_slot(@inner_block)}
      </.link>
    </li>
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
    <div id={@id} class="border-b border-ltrn-lighter">
      <button
        type="button"
        class="flex items-center justify-between w-full p-4 hover:bg-ltrn-lightest transition-colors"
        aria-expanded={@initial_expanded |> to_string()}
        aria-controls={"#{@id}-content"}
        phx-click={
          JS.toggle(to: "##{@id}-content")
          |> JS.toggle(to: "##{@id}-icon-expanded")
          |> JS.toggle(to: "##{@id}-icon-collapsed")
          |> JS.toggle_attribute({"aria-expanded", "true", "false"},
            to: "##{@id}-button-toggle"
          )
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
