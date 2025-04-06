defmodule LantternWeb.LearningContextComponents do
  @moduledoc """
  Shared function components related to `LearningContext` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  alias Phoenix.LiveView.JS
  alias Lanttern.LearningContext.Strand

  @doc """
  Renders strand cards.
  """
  attr :strand, Strand, required: true, doc: "Requires subjects + years preloads"
  attr :on_star_click, JS, default: nil
  attr :on_edit, JS, default: nil
  attr :navigate, :string, default: nil
  attr :open_in_new, :boolean, default: false
  attr :hide_description, :boolean, default: false
  attr :strand_report_cover_image_url, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  slot :bottom_content, doc: "optional block to render content in the bottom of the card"

  def strand_card(assigns) do
    cover_image_url =
      assigns.strand.cover_image_url
      |> object_url_to_render_url(width: 400, height: 200)

    strand_report_cover_image_url =
      assigns.strand_report_cover_image_url
      |> object_url_to_render_url(width: 400, height: 200)

    has_multiple_images =
      !!cover_image_url && !!strand_report_cover_image_url

    assigns =
      assigns
      |> assign(:cover_image_url, cover_image_url)
      |> assign(:strand_report_cover_image_url, strand_report_cover_image_url)
      |> assign(:has_multiple_images, has_multiple_images)

    ~H"""
    <.card_base
      class={[
        "relative flex flex-col overflow-hidden",
        @class
      ]}
      id={@id}
    >
      <div
        class="relative shrink-0 w-full h-40"
        id={"#{@id}-report-card-slider"}
        {if @has_multiple_images, do: %{
          "phx-hook" => "Slider",
          "phx-update" => "ignore"
        }, else: %{}}
      >
        <div class="slider flex w-full h-full">
          <div
            :if={@strand_report_cover_image_url}
            class="w-full h-full bg-center bg-cover"
            style={"background-image: url('#{@strand_report_cover_image_url}')"}
          />
          <div
            :if={@cover_image_url || !@strand_report_cover_image_url}
            class="w-full h-full bg-center bg-cover"
            style={"background-image: url('#{@cover_image_url || "/images/cover-placeholder-sm.jpg"}')"}
          />
        </div>
        <div :if={@has_multiple_images} class="absolute bottom-2 flex justify-center w-full">
          <div class="slider-dots px-1 rounded-full bg-white" />
        </div>
        <div :if={@on_star_click || @on_edit} class="absolute top-2 right-2 flex items-center gap-2">
          <.button :if={@on_edit} type="button" theme="ghost" size="sm" phx-click={@on_edit}>
            <%= gettext("Edit") %>
          </.button>
          <button
            :if={@on_star_click}
            type="button"
            aria-label={gettext("Star strand")}
            class="flex items-center justify-center w-8 h-8 rounded-full hover:bg-white hover:shadow-md"
            phx-click={@on_star_click}
          >
            <.icon
              name="hero-star-mini"
              class={if(@strand.is_starred, do: "text-ltrn-primary", else: "text-ltrn-lighter")}
            />
          </button>
        </div>
      </div>
      <div class={[
        "flex flex-col gap-6 p-6",
        if(@bottom_content == [], do: "shrink-0", else: "flex-[1_0]")
      ]}>
        <div>
          <h5 class={[
            "font-display font-black text-xl line-clamp-3",
            "md:text-2xl md:leading-tight"
          ]}>
            <%= if @navigate do %>
              <.link
                navigate={@navigate}
                class="hover:text-ltrn-subtle"
                target={if @open_in_new, do: "_blank"}
              >
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
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
          </.badge>
          <.badge :for={year <- @strand.years}>
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name) %>
          </.badge>
        </div>
        <div :if={!@hide_description} class="line-clamp-3">
          <.markdown text={@strand.description} />
        </div>
      </div>
      <%= render_slot(@bottom_content) %>
    </.card_base>
    """
  end

  @doc """
  Renders a mini strand card.
  """
  attr :strand, Strand, required: true, doc: "Requires subjects + years preloads"
  attr :id, :string, default: nil
  attr :class, :any, default: nil

  def mini_strand_card(assigns) do
    cover_image_url =
      assigns.strand.cover_image_url
      |> object_url_to_render_url(width: 400, height: 200)

    assigns = assign(assigns, :cover_image_url, cover_image_url)

    ~H"""
    <.card_base class={["overflow-hidden", @class]} id={@id}>
      <div
        class="w-full h-32 bg-center bg-cover"
        style={"background-image: url('#{@cover_image_url || "/images/cover-placeholder-sm.jpg"}')"}
      >
        <span class="sr-only"><%= gettext("Cover image") %></span>
      </div>
      <div class="p-4">
        <h6 class="font-display font-black text-base leading-tight">
          <%= @strand.name %>
        </h6>
        <p :if={@strand.type} class="mt-2 font-display font-black text-sm text-ltrn-subtle">
          <%= @strand.type %>
        </p>
        <div class="flex flex-wrap gap-2 mt-4">
          <.badge :for={subject <- @strand.subjects}>
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
          </.badge>
          <.badge :for={year <- @strand.years}>
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name) %>
          </.badge>
        </div>
      </div>
    </.card_base>
    """
  end
end
