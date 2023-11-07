defmodule LantternWeb.NavigationComponents do
  @moduledoc """
  Provides core navigation components.
  """
  use Phoenix.Component

  # alias Phoenix.LiveView.JS
  import LantternWeb.CoreComponents

  @doc """
  Renders a student or teacher tab.

  ## Examples

      <.person_tab person={student} />

  """
  attr :id, :string, default: nil
  attr :person, :map, required: true
  attr :theme, :string, default: "subtle", doc: "subtle | cyan"
  attr :is_current, :boolean, default: false
  attr :rest, :global

  def person_tab(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      role="tab"
      aria-selected={if @is_current, do: "true", else: "false"}
      tabindex={if @is_current, do: "0", else: "-1"}
      class={[
        "flex items-center gap-2 p-1 rounded-full focus:outline-ltrn-primary",
        person_tab_theme_style(@theme),
        if(@is_current, do: "outline outline-2 outline-ltrn-dark")
      ]}
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
