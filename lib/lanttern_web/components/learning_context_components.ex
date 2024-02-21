defmodule LantternWeb.LearningContextComponents do
  use Phoenix.Component

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents

  alias Phoenix.LiveView.JS
  alias Lanttern.LearningContext.Strand

  @doc """
  Renders strand cards.
  """
  attr :strand, Strand, required: true, doc: "Requires subjects + years preloads"
  attr :on_star_click, JS, default: nil
  attr :navigate, :string, default: nil
  attr :hide_description, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  slot :inner_block, doc: "optional inner block to render content in the card"

  def strand_card(assigns) do
    ~H"""
    <div
      class={[
        "rounded shadow-xl bg-white overflow-hidden",
        @class
      ]}
      id={@id}
    >
      <div
        class="relative w-full h-40 bg-center bg-cover"
        style={"background-image: url(#{@strand.cover_image_url || "/images/cover-placeholder-sm.jpg"}?width=400&height=200)"}
      >
        <button
          :if={@on_star_click}
          type="button"
          aria-label={gettext("Star strand")}
          class="absolute top-2 right-2 flex items-center justify-center w-8 h-8 rounded-full hover:bg-white hover:shadow-md"
          phx-click={@on_star_click}
        >
          <.icon
            name="hero-star-mini"
            class={if(@strand.is_starred, do: "text-ltrn-primary", else: "text-ltrn-lighter")}
          />
        </button>
      </div>
      <div class="flex flex-col gap-6 p-6">
        <div>
          <h5 class="font-display font-black text-3xl line-clamp-3">
            <%= if @navigate do %>
              <.link navigate={@navigate} class="underline hover:text-ltrn-subtle">
                <%= @strand.name %>
              </.link>
            <% else %>
              <%= @strand.name %>
            <% end %>
          </h5>
          <p :if={@strand.type} class="mt-2 font-display font-black text-base text-ltrn-primary">
            <%= @strand.type %>
          </p>
        </div>
        <div class="flex flex-wrap gap-2">
          <.badge :for={subject <- @strand.subjects}>
            <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", subject.name) %>
          </.badge>
          <.badge :for={year <- @strand.years}>
            <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", year.name) %>
          </.badge>
        </div>
        <div :if={!@hide_description} class="line-clamp-3">
          <.markdown text={@strand.description} size="sm" />
        </div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end