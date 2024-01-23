defmodule LantternWeb.RubricsComponents do
  use Phoenix.Component

  import LantternWeb.CoreComponents

  alias Lanttern.Rubrics.Rubric

  @doc """
  Renders rubric descriptors.
  """
  attr :rubric, Rubric, required: true, doc: "Requires descriptors + ordinal_value preloads"
  attr :direction, :string, default: "horizontal", doc: "horizontal | vertical"
  attr :class, :any, default: nil

  def rubric_descriptors(%{direction: "vertical"} = assigns) do
    ~H"""
    <div class={["flex flex-col gap-8", @class]}>
      <div :for={descriptor <- @rubric.descriptors}>
        <%= if descriptor.scale_type == "ordinal" do %>
          <.badge style_from_ordinal_value={descriptor.ordinal_value}>
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
      <div :for={descriptor <- @rubric.descriptors} class="flex-[1_0] flex flex-col items-start gap-2">
        <%= if descriptor.scale_type == "numeric" do %>
          <.badge theme="dark"><%= descriptor.score %></.badge>
        <% else %>
          <.badge style_from_ordinal_value={descriptor.ordinal_value}>
            <%= descriptor.ordinal_value.name %>
          </.badge>
        <% end %>
        <.markdown
          text={descriptor.descriptor}
          class="prose-sm flex-1 w-full p-2 border border-ltrn-lighter rounded-sm bg-ltrn-lightest"
        />
      </div>
    </div>
    """
  end
end