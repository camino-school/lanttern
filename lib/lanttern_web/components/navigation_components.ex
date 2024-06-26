defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.Gettext

  import LantternWeb.CoreComponents

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
    attr :patch, :string, required: true
    attr :is_current, :string
    attr :icon_name, :string
  end

  def nav_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-10", @class]} id={@id}>
      <%= for tab <- @tab do %>
        <.link
          patch={tab.patch}
          class={[
            "relative shrink-0 flex items-center gap-2 py-5 font-display text-base whitespace-nowrap",
            if(Map.get(tab, :is_current) == "true",
              do: "font-bold",
              else: "hover:text-ltrn-subtle"
            )
          ]}
        >
          <%= render_slot(tab) %>
          <.icon :if={Map.get(tab, :icon_name)} name={Map.get(tab, :icon_name)} class="w-6 h-6" />
          <span
            :if={Map.get(tab, :is_current) == "true"}
            class="absolute h-2 bg-ltrn-primary inset-x-0 bottom-0"
          />
        </.link>
      <% end %>
    </nav>
    """
  end

  @doc """
  Renders a student or teacher tab.

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
        <%= @person.name %>
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
            if(@with_bg, do: "text-white drop-shadow-sm"),
            if(Map.get(item, :link), do: "hidden sm:list-item")
          ]}
        >
          <span :if={i > 0} class="hidden sm:inline">/</span>
          <%= if Map.get(item, :link) do %>
            <.link navigate={item.link} class="underline"><%= render_slot(item) %></.link>
          <% else %>
            <span><%= render_slot(item) %></span>
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
    <div id={@id} class={@class}>
      <.icon_button
        name="hero-arrows-pointing-in"
        class={if !@initial_is_expanded, do: "hidden"}
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
        class={if @initial_is_expanded, do: "hidden"}
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
end
