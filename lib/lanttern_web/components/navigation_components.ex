defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
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
  end

  def nav_tabs(assigns) do
    ~H"""
    <nav class={["flex gap-10", @class]} id={@id}>
      <%= for tab <- @tab do %>
        <.link
          patch={tab.patch}
          class={[
            "relative shrink-0 py-5 font-display text-base whitespace-nowrap",
            if(Map.get(tab, :is_current) == "true",
              do: "font-bold",
              else: "hover:text-ltrn-subtle"
            )
          ]}
        >
          <%= render_slot(tab) %>
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
  attr :theme, :string, default: "subtle", doc: "subtle | cyan"
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
        person_tab_theme_style(@theme)
      ]}
      phx-click={
        JS.hide(to: "#{@container_selector} div[role=tabpanel]")
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

  defp person_tab_theme_style("cyan"), do: "text-ltrn-dark bg-ltrn-mesh-cyan"
  defp person_tab_theme_style(_subtle), do: "text-ltrn-subtle bg-ltrn-lighter"

  @doc """
  Renders a breadcrumb.

  ## Examples

      <.person_tab person={student} />

  """
  attr :class, :any, default: nil
  attr :item_class, :any, default: nil

  slot :item, required: true do
    attr :link, :string
  end

  def breadcrumbs(assigns) do
    ~H"""
    <nav class={@class}>
      <ol class="flex items-center gap-2 font-display font-bold text-sm text-ltrn-subtle">
        <li :for={{item, i} <- Enum.with_index(@item)} class={@item_class}>
          <span :if={i > 0}>/</span>
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
end
