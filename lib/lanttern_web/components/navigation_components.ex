defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents

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
      <span class="pr-1 text-xs">
        <%= @person.name %>
      </span>
    </button>
    """
  end

  defp person_tab_theme_style("cyan"), do: "text-ltrn-dark bg-ltrn-mesh-cyan"
  defp person_tab_theme_style(_subtle), do: "text-ltrn-subtle bg-ltrn-lighter"
end
