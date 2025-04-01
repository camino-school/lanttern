defmodule LantternWeb.RubricsComponents do
  @moduledoc """
  Shared function components related to `Rubrics` context
  """

  use Phoenix.Component

  import LantternWeb.CoreComponents

  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Rubrics.RubricDescriptor

  @doc """
  Renders rubric descriptors.
  """
  attr :rubric, Rubric, required: true, doc: "Requires descriptors + ordinal_value preloads"
  attr :highlight_level_for_entry, :any, default: nil
  attr :direction, :string, default: "horizontal", doc: "horizontal | vertical"
  attr :class, :any, default: nil

  def rubric_descriptors(%{direction: "vertical"} = assigns) do
    ~H"""
    <div class={["flex flex-col gap-8", @class]}>
      <div :for={descriptor <- @rubric.descriptors}>
        <%= if descriptor.scale_type == "ordinal" do %>
          <.badge color_map={descriptor.ordinal_value}>
            <%= descriptor.ordinal_value.name %>
          </.badge>
        <% else %>
          <.badge>
            <%= descriptor.score %>
          </.badge>
        <% end %>
        <.markdown class="mt-2" text={descriptor.descriptor} />
      </div>
    </div>
    """
  end

  def rubric_descriptors(assigns) do
    ~H"""
    <div class={["flex items-stretch gap-2", @class]}>
      <.rubric_descriptor
        :for={descriptor <- @rubric.descriptors}
        descriptor={descriptor}
        highlight_level_for_entry={@highlight_level_for_entry}
      />
    </div>
    """
  end

  attr :descriptor, RubricDescriptor, required: true
  attr :highlight_level_for_entry, :any, required: true

  defp rubric_descriptor(assigns) do
    entry = assigns.highlight_level_for_entry
    desc_ordinal_value = assigns.descriptor.ordinal_value

    is_active = entry && entry.ordinal_value_id == desc_ordinal_value.id
    active_style = if is_active, do: create_color_map_style(desc_ordinal_value)
    active_text_style = if is_active, do: create_color_map_text_style(desc_ordinal_value)

    assigns =
      assigns
      |> assign(active_style: active_style)
      |> assign(active_text_style: active_text_style)

    ~H"""
    <div
      class="flex-[1_0] flex flex-col items-start gap-2 min-w-[12rem] p-2 border border-ltrn-lighter rounded-sm bg-ltrn-lightest"
      style={@active_style}
    >
      <%= if @descriptor.scale_type == "numeric" do %>
        <.badge theme="dark" class="shadow-lg"><%= @descriptor.score %></.badge>
      <% else %>
        <.badge color_map={@descriptor.ordinal_value} class="shadow-lg">
          <%= @descriptor.ordinal_value.name %>
        </.badge>
      <% end %>
      <.markdown text={@descriptor.descriptor} class="flex-1 w-full" style={@active_text_style} />
    </div>
    """
  end
end
