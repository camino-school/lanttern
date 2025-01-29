defmodule LantternWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such as modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import Phoenix.HTML, only: [raw: 1]
  use Gettext, backend: Lanttern.Gettext

  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  @doc """
  Renders a `<button>` or `<.link>` with icon.

  Usually used in the context of a collection (e.g. to add a new item to a list, or filter results).
  """

  attr :class, :any, default: nil
  attr :theme, :string, default: "default"
  attr :size, :string, default: "sm", doc: "sm | md"
  attr :type, :string, required: true, doc: "link | button | submit"
  attr :icon_name, :string, default: nil
  attr :patch, :string, default: nil, doc: "use with type=\"link\""
  attr :navigate, :string, default: nil, doc: "use with type=\"link\""
  attr :rest, :global, include: ~w(disabled form)

  slot :inner_block, required: true

  def action(%{type: "link"} = assigns) do
    ~H"""
    <.link patch={@patch} navigate={@navigate} class={[action_styles(@theme, @size), @class]}>
      <div class={action_bg_styles(@theme, @size)}></div>
      <span class="relative truncate"><%= render_slot(@inner_block) %></span>
      <.icon :if={@icon_name} name={@icon_name} class={action_icon_styles(@size)} />
    </.link>
    """
  end

  def action(%{type: type} = assigns) when type in ["button", "submit"] do
    ~H"""
    <button type={@type} class={[action_styles(@theme, @size), @class]} {@rest}>
      <div class={action_bg_styles(@theme, @size)}></div>
      <span class="relative truncate"><%= render_slot(@inner_block) %></span>
      <.icon
        :if={@icon_name}
        name={@icon_name}
        class={[
          "group-phx-submit-loading:hidden group-phx-click-loading:hidden",
          action_icon_styles(@size)
        ]}
      />
      <.spinner class="hidden group-phx-submit-loading:block group-phx-click-loading:block" />
    </button>
    """
  end

  @action_themes %{
    "default" => "text-ltrn-dark hover:text-ltrn-subtle",
    "subtle" => "text-ltrn-subtle hover:text-ltrn-dark",
    "primary" => "text-ltrn-dark hover:text-ltrn-subtle",
    "student" => "text-ltrn-student-dark hover:text-ltrn-student-dark/80",
    "staff" => "text-ltrn-staff-dark hover:text-ltrn-staff-dark/80",
    "alert" => "text-ltrn-subtle hover:text-ltrn-alert-accent"
  }

  @action_bg_themes %{
    "default" => nil,
    "subtle" => nil,
    "primary" => "bg-ltrn-mesh-primary",
    "student" => "bg-ltrn-student-lightest",
    "staff" => "bg-ltrn-staff-lightest",
    "alert" => "bg-ltrn-alert-lighter"
  }

  @action_sizes %{
    "sm" => "text-sm",
    "md" => "text-base"
  }

  @action_bg_sizes %{
    "sm" => "h-2",
    "md" => "h-3"
  }

  @action_icon_sizes %{
    "sm" => "w-5 h-5",
    "md" => "w-6 h-6"
  }

  defp action_styles(theme, size),
    do:
      "group relative flex items-center gap-2 min-w-0 #{Map.get(@action_themes, theme)} #{Map.get(@action_sizes, size)}"

  defp action_bg_styles(theme, size),
    do:
      "absolute inset-x-0 bottom-0 #{Map.get(@action_bg_themes, theme)} #{Map.get(@action_bg_sizes, size)}"

  defp action_icon_styles(size), do: "relative shrink-0 #{Map.get(@action_icon_sizes, size)}"

  @doc """
  Util function to help with action item text formating
  """

  def format_action_items_text(items, default_text, key \\ :name, separator \\ ", ")

  def format_action_items_text([] = _items, default_text, _, _), do: default_text

  def format_action_items_text(items, _, key, separator),
    do: Enum.map_join(items, separator, &Map.get(&1, key))

  @doc """
  Renders an action bar.

  ## Examples

      <.action_bar>
        some actions
      </.action_bar>
  """
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def action_bar(assigns) do
    ~H"""
    <div class={["p-4 bg-white/20 shadow-xl", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a badge.
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :theme, :string, default: "default"
  attr :icon_name, :string, default: nil

  attr :color_map, :map,
    default: nil,
    doc: "any map with `bg_color` and `text_color` attrs (e.g. ordinal value)"

  attr :on_remove, JS, default: nil
  attr :on_click, JS, default: nil, doc: "will trigger on inner_block click"
  attr :rest, :global
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span
      id={@id}
      class={[
        "inline-flex items-center rounded-sm px-1 py-1 font-mono font-normal text-xs truncate",
        badge_theme(@theme),
        @class
      ]}
      style={create_color_map_style(@color_map)}
      {@rest}
    >
      <.icon :if={@icon_name} class={["mr-2", badge_icon_theme(@theme)]} name={@icon_name} />
      <%= if @on_click do %>
        <button type="button" phx-click={@on_click}><%= render_slot(@inner_block) %></button>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
      <button
        :if={@on_remove}
        type="button"
        class="group relative ml-1 h-3.5 w-3.5 rounded-[1px] hover:bg-ltrn-dark/10"
        phx-click={@on_remove}
      >
        <span class="sr-only"><%= gettext("Remove") %></span>
        <.icon
          name="hero-x-mark-mini"
          class="w-3.5 text-ltrn-dark"
          style={create_color_map_text_style(@color_map)}
        />
        <span class="absolute -inset-1"></span>
      </button>
    </span>
    """
  end

  @badge_themes %{
    "default" => "bg-ltrn-lightest text-ltrn-dark",
    "primary" => "bg-ltrn-primary text-ltrn-dark",
    "secondary" => "bg-ltrn-secondary text-white",
    "cyan" => "bg-ltrn-mesh-cyan text-ltrn-dark",
    "dark" => "bg-ltrn-dark text-ltrn-lighter",
    "diff" => "bg-ltrn-diff-lighter text-ltrn-diff-dark",
    "student" => "bg-ltrn-student-lighter text-ltrn-student-dark",
    "staff" => "bg-ltrn-staff-lighter text-ltrn-staff-dark",
    "empty" => "bg-transparent border border-dashed border-ltrn-light text-ltrn-subtle"
  }

  @badge_themes_hover %{
    "default" => "hover:bg-ltrn-lightest/50",
    "primary" => "hover:bg-ltrn-primary/50",
    "secondary" => "hover:bg-ltrn-secondary/50",
    "cyan" => "hover:bg-ltrn-mesh-cyan/50",
    "dark" => "hover:bg-ltrn-dark/50",
    "diff" => "hover:bg-ltrn-diff-lightest",
    "student" => "hover:bg-ltrn-student-lightest",
    "staff" => "hover:bg-ltrn-staff-lightest"
  }

  defp badge_theme(theme, with_hover \\ false) do
    "#{Map.get(@badge_themes, theme, @badge_themes["default"])} #{if with_hover, do: Map.get(@badge_themes_hover, theme, @badge_themes_hover["default"])}"
  end

  @badge_icon_themes %{
    "default" => "text-ltrn-subtle",
    "primary" => "text-ltrn-dark",
    "secondary" => "text-white",
    "cyan" => "text-ltrn-subtle",
    "dark" => "text-ltrn-lighter",
    "diff" => "text-ltrn-diff-dark",
    "student" => "text-ltrn-student-dark",
    "staff" => "text-ltrn-staff-dark"
  }

  defp badge_icon_theme(theme),
    do: Map.get(@badge_icon_themes, theme, @badge_icon_themes["default"])

  defp badge_check_icon_theme(false), do: "text-ltrn-light"
  defp badge_check_icon_theme(true), do: "text-ltrn-primary"

  @doc """
  Returns a list of badge button styles.

  Meant to be used while styling links as badge buttons.

  ## Examples

      <.link patch={~p"/somepath"} class={[get_badge_button_styles()]}>Link</.link>
  """
  def get_badge_button_styles(theme \\ "default") do
    [
      "inline-flex items-center gap-1 rounded-full px-2 py-1 font-mono text-xs shadow",
      badge_theme(theme, true)
    ]
  end

  @doc """
  Returns a list of badge icon styles.

  Meant to be used with `get_badge_button_styles/1`.

  ## Examples

      <.link patch={~p"/somepath"} class={get_badge_button_styles()}>
        Link
        <.icon name="hero-plus-mini" class={get_badge_icon_styles()} />
      </.link>
  """
  def get_badge_icon_styles(theme \\ "default"),
    do: ["w-3.5 h-3.5", badge_icon_theme(theme)]

  @doc """
  Renders a badge button.

  ## Examples

      <.badge_button>Send!</.badge_button>
      <.badge_button phx-click="go" class="ml-2">Send!</.badge_button>
  """
  attr :id, :string, default: nil
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :theme, :string, default: "default", doc: "default | ghost"
  attr :icon_name, :string, default: nil
  attr :is_checked, :boolean, doc: "will render a check icon on the left side. impacts styling"

  attr :color_map, :map,
    default: nil,
    doc: "any map with `bg_color` and `text_color` attrs (e.g. ordinal value)"

  attr :rest, :global

  slot :inner_block, required: true

  def badge_button(assigns) do
    has_check_icon = Map.has_key?(assigns, :is_checked)

    # when is_checked, use cyan theme
    theme = if has_check_icon && assigns.is_checked, do: "cyan", else: assigns.theme

    assigns =
      assigns
      |> assign(:has_check_icon, has_check_icon)
      |> assign(:theme, theme)

    ~H"""
    <button
      id={@id}
      type={@type}
      class={[
        get_badge_button_styles(@theme),
        @class
      ]}
      style={create_color_map_style(@color_map)}
      {@rest}
    >
      <.icon
        :if={@has_check_icon}
        name="hero-check-circle-mini"
        class={["w-3.5 h-3.5", badge_check_icon_theme(@is_checked)]}
        style={create_color_map_text_style(@color_map)}
      />
      <%= render_slot(@inner_block) %>
      <%= if @icon_name do %>
        <.icon
          name={@icon_name}
          class={["w-3.5 h-3.5", badge_icon_theme(@theme)]}
          style={create_color_map_text_style(@color_map)}
        />
      <% end %>
    </button>
    """
  end

  @doc """
  Wrapper around `<.badge_button>` to render a list of badge buttons
  with selected state management.

  ## Examples

      <.badge_button_picker
        on_select={%JS{}}
        items={items}
        selected_ids={selected_ids}
      />
  """
  attr :items, :list, required: true
  attr :selected_ids, :list, required: true

  attr :label_setter, :string,
    default: nil,
    doc: "supports \"class_with_cycle\" opt, which will render the class + cycle name"

  attr :current_user_or_cycle, :any,
    default: nil,
    doc: "used when `label_setter` is \"class_with_cycle\""

  attr :on_select, :any,
    required: true,
    doc: "expects a function with arity 1. will receive the `item.id` as arg"

  attr :use_color_map_as_active, :boolean,
    default: false,
    doc:
      "instead of using primary theme when active, will set `color_map` attr using item when active"

  attr :class, :any, default: nil
  attr :id, :string, default: nil

  def badge_button_picker(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]} id={@id}>
      <.badge_button
        :for={item <- @items}
        theme={if item.id in @selected_ids, do: "primary", else: "default"}
        color_map={if item.id in @selected_ids && @use_color_map_as_active, do: item}
        icon_name={if item.id in @selected_ids, do: "hero-check-mini", else: "hero-plus-mini"}
        phx-click={@on_select.(item.id)}
      >
        <%= case @label_setter do
          "class_with_cycle" -> class_with_cycle(item, @current_user_or_cycle)
          _ -> item.name
        end %>
      </.badge_button>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string,
    default: nil,
    doc: "if `link` is used, will render a `<.link>` component instead of `<button>`"

  attr :class, :any, default: nil
  attr :theme, :string, default: "default", doc: "default | ghost"
  attr :size, :string, default: "normal", doc: "sm | normal"
  attr :rounded, :boolean, default: false
  attr :icon_name, :string, default: nil
  attr :sr_text, :string, doc: "screen reader text. required when rendering an icon only button"
  # `<.button type="link">` (`<.link>`) attrs
  attr :navigate, :string, default: nil
  attr :patch, :string, default: nil
  attr :href, :any, default: nil
  attr :replace, :boolean, default: nil
  attr :method, :string, default: nil
  attr :csrf_token, :any, default: nil
  # include `<.link>` attrs
  attr :rest, :global,
    include: ~w(disabled form name value download hreflang referrerpolicy rel target)

  slot :inner_block, doc: "not required when rendering icon only"

  def button(%{type: "link"} = assigns) do
    ~H"""
    <.link
      class={[
        "group",
        get_button_styles(@theme, @size, @rounded),
        @class
      ]}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      replace={@replace}
      method={@method}
      csrf_token={@csrf_token}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
      <%= if @icon_name do %>
        <span :if={@inner_block == []} class="sr-only"><%= @sr_text %></span>
        <.icon
          name={@icon_name}
          class="w-5 h-5 group-phx-submit-loading:hidden group-phx-click-loading:hidden"
        />
      <% end %>
      <.spinner class="hidden group-phx-submit-loading:block group-phx-click-loading:block" />
    </.link>
    """
  end

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "group",
        get_button_styles(@theme, @size, @rounded),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
      <%= if @icon_name do %>
        <.icon
          name={@icon_name}
          class="w-5 h-5 group-phx-submit-loading:hidden group-phx-click-loading:hidden"
        />
      <% end %>
      <.spinner class="hidden group-phx-submit-loading:block group-phx-click-loading:block" />
    </button>
    """
  end

  @doc """
  Returns a list of button styles.

  Meant to be used while styling links as buttons.

  ## Examples

      <.link patch={~p"/somepath"} class={[get_button_styles()]}>Link</.link>
  """
  def get_button_styles(theme \\ "default", size \\ "normal", rounded \\ false) do
    [
      "inline-flex items-center justify-center font-display text-sm font-bold disabled:cursor-not-allowed shadow",
      "disabled:shadow-none",
      if(size == "sm", do: "gap-1 p-1", else: "gap-2 p-2"),
      if(rounded, do: "rounded-full", else: "rounded-sm"),
      "phx-submit-loading:opacity-50 phx-click-loading:opacity-50 phx-click-loading:pointer-events-none",
      button_theme(theme)
    ]
  end

  @button_themes %{
    "default" => [
      "bg-ltrn-primary hover:bg-cyan-300",
      "disabled:text-ltrn-subtle disabled:bg-ltrn-mesh-cyan"
    ],
    "primary_light" => "bg-ltrn-mesh-cyan hover:bg-white text-ltrn-primary",
    "diff_light" => [
      "bg-ltrn-diff-lightest hover:bg-ltrn-diff-lighter text-ltrn-diff-dark",
      "disabled:opacity-40"
    ],
    "staff" => [
      "bg-ltrn-staff-lighter text-ltrn-staff-dark hover:opacity-80",
      "disabled:opacity-40"
    ],
    "student" => [
      "bg-ltrn-student-lighter text-ltrn-student-dark hover:opacity-80",
      "disabled:opacity-40"
    ],
    "white" => "text-ltrn-dark bg-white hover:bg-ltrn-lightest",
    "ghost" => [
      "text-ltrn-subtle bg-white/10 shadow-none hover:bg-slate-100",
      "disabled:text-ltrn-lighter"
    ]
  }

  defp button_theme(theme) do
    @button_themes
    |> Map.get(theme, @button_themes["default"])
  end

  @doc """
  Renders a simple card.
  """

  attr :class, :any, default: nil

  attr :bg_class, :any,
    default: "bg-white",
    doc: "we use a separate attr for bg class to prevent clashing with default bg"

  attr :id, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def card_base(assigns) do
    ~H"""
    <div id={@id} class={["rounded shadow-xl", @bg_class, @class]} {@rest}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a page cover.
  """
  attr :rest, :global
  attr :size, :string, default: "lg", doc: "sm | lg"
  attr :theme, :string, default: "primary"
  slot :inner_block, required: true
  slot :top, required: true

  def cover(assigns) do
    ~H"""
    <div
      class={[
        "relative flex flex-col justify-between bg-cover bg-center bg-ltrn-lighter",
        if(@size == "sm", do: "min-h-96", else: "min-h-[40rem]")
      ]}
      {@rest}
    >
      <div class={[
        "absolute inset-x-0 bottom-0 bg-gradient-to-b",
        cover_overlay(@theme),
        if(@size == "sm", do: "top-0", else: "top-1/4")
      ]} />
      <.responsive_container class="relative py-6 sm:pt-10">
        <%= render_slot(@top) %>
      </.responsive_container>
      <.responsive_container class="relative py-6 sm:pb-10 mt-14">
        <%= render_slot(@inner_block) %>
      </.responsive_container>
    </div>
    """
  end

  defp cover_overlay("lime"),
    do: "from-ltrn-mesh-lime/0 to-ltrn-mesh-lime"

  defp cover_overlay(_),
    do: "from-ltrn-mesh-primary/0 to-ltrn-mesh-primary"

  attr :image_url, :string, default: nil
  attr :alt_text, :string, required: true
  attr :empty_state_text, :string, default: nil
  attr :theme, :string, default: "primary"
  attr :size, :string, default: "lg", doc: "lg | sm"
  attr :class, :any, default: nil

  def cover_image(%{image_url: image_url} = assigns)
      when is_binary(image_url) and image_url != "" do
    ~H"""
    <div
      class={[cover_image_base_classes(@size), @class]}
      style={"background-image: url('#{@image_url || "/images/cover-placeholder.jpg"}')"}
    >
      <p class="sr-only"><%= @alt_text %></p>
      <div class={[
        "absolute inset-0 bg-gradient-to-b",
        cover_overlay(@theme)
      ]} />
    </div>
    """
  end

  def cover_image(assigns) do
    ~H"""
    <div
      class={[
        cover_image_base_classes(@size),
        "flex items-center justify-center border border-dashed border-ltrn-light",
        @class
      ]}
      style="background-image: url('/images/cover-placeholder.jpg')"
    >
      <p :if={@empty_state_text} class="font-display font-black text-2xl text-ltrn-subtle">
        <%= @empty_state_text %>
      </p>
      <div class={[
        "absolute inset-0 bg-gradient-to-b",
        cover_overlay(@theme)
      ]} />
    </div>
    """
  end

  defp cover_image_base_classes(size) do
    height_classes =
      case size do
        "sm" -> "h-[20rem] min-h-[40vh] max-h-[60vh]"
        _ -> "h-[30rem] min-h-[60vh] max-h-[80vh]"
      end

    "relative w-full #{height_classes} rounded bg-cover bg-center shadow-xl overflow-hidden"
  end

  @doc """
  Returns a string with background and text styles to be
  used in a `style` attribute.
  """

  def create_color_map_style(%{bg_color: bg_color, text_color: text_color}),
    do: "background-color: #{bg_color}; color: #{text_color}"

  def create_color_map_style(_), do: nil

  @doc """
  Returns a string with text style to be
  used in a `style` attribute.
  """

  def create_color_map_text_style(%{text_color: text_color}),
    do: "color: #{text_color}"

  def create_color_map_text_style(_), do: nil

  @doc """
  Returns a string with background gradient style
  to be used in a `style` attribute.
  """
  def create_color_map_gradient_bg_style(%{
        start_bg_color: start_bg_color,
        stop_bg_color: stop_bg_color
      })
      when is_binary(start_bg_color) and is_binary(stop_bg_color),
      do: "background-image: linear-gradient(to right, #{start_bg_color}, #{stop_bg_color})"

  def create_color_map_gradient_bg_style(_), do: %{}

  @doc """
  Renders a data grid.

  ## Examples

      <.data_grid id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.data_grid>
  """
  attr :id, :string, required: true
  attr :stream, :any, required: true
  attr :class, :any, default: nil
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  # this approach looks weird... but we need something apart from stream to identify empty streams
  attr :show_empty_state_message, :string, default: nil, doc: "Use this field to show empty state"

  attr :sticky_header_offset, :string,
    default: "0",
    doc: "Use it to adjust where the grid header will stick"

  slot :col, required: true do
    attr :label, :string, required: true
    attr :on_filter, JS
    attr :filter_is_active, :boolean
    attr :template_col, :string, doc: "use to define grid template. minmax(0, 1fr) by default"
    attr :class, :any
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def data_grid(assigns) do
    cols_style =
      assigns.col
      |> Enum.map_join(" ", &Map.get(&1, :template_col, "minmax(0, 1fr)"))

    has_action = assigns.action != []

    grid_template_cols_style = "grid-template-columns: #{cols_style}"

    grid_template_cols_style =
      if has_action,
        do: grid_template_cols_style <> " max-content",
        else: grid_template_cols_style

    cols_count = length(assigns.col)
    cols_count = if has_action, do: cols_count + 1, else: cols_count

    grid_col_span_style = "grid-column: span #{cols_count} / span #{cols_count}"

    assigns =
      assigns
      |> assign(:grid_template_cols_style, grid_template_cols_style)
      |> assign(:grid_col_span_style, grid_col_span_style)

    ~H"""
    <div class={["bg-white shadow-xl", @class]}>
      <div class="grid" style={@grid_template_cols_style}>
        <div
          class="sticky z-10 grid grid-cols-subgrid font-display font-bold text-sm bg-white shadow"
          style={["top: #{@sticky_header_offset};", @grid_col_span_style]}
        >
          <div :for={col <- @col} class="flex gap-2 p-4">
            <%= col[:label] %>
            <button
              :if={col[:on_filter]}
              type="button"
              class="hover:opacity-50"
              phx-click={col[:on_filter]}
            >
              <%= if col[:filter_is_active] do %>
                <.icon name="hero-funnel-mini" class="text-ltrn-primary" />
              <% else %>
                <.icon name="hero-funnel" class="text-ltrn-subtle" />
              <% end %>
            </button>
          </div>
          <div :if={@action != []} class="relative p-2 pb-4">
            <span class="sr-only"><%= gettext("Actions") %></span>
          </div>
        </div>
        <ul id={@id} phx-update="stream" class="grid grid-cols-subgrid" style={@grid_col_span_style}>
          <li
            :for={{row_id, row} <- @stream}
            id={row_id}
            class={[
              "grid grid-cols-subgrid items-center hover:bg-ltrn-mesh-cyan",
              @row_click && "hover:cursor-pointer"
            ]}
            style={@grid_col_span_style}
            phx-click={@row_click && @row_click.(row)}
          >
            <div :for={col <- @col} class={["p-4", col[:class]]}>
              <%= render_slot(col, row) %>
            </div>
            <div :if={@action != []} class="flex items-center gap-2 p-4">
              <%= for action <- @action do %>
                <%= render_slot(action, row) %>
              <% end %>
            </div>
          </li>
        </ul>
      </div>
      <div :if={@show_empty_state_message} class="p-6">
        <.empty_state><%= @show_empty_state_message %></.empty_state>
      </div>
    </div>
    """
  end

  @doc """
  Renders an empty state block with a pulsating visual element
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class={["text-center", @class]}>
      <div class="relative p-6">
        <div class="animate-pulse h-24 w-24 rounded-full mx-auto bg-ltrn-lighter blur-md"></div>
        <div class="absolute top-1/2 left-1/2 h-20 w-20 -mt-10 -ml-10 rounded-full border border-dashed border-ltrn-light">
        </div>
      </div>
      <%!-- <div class="relative flex h-16 w-16 mx-auto">
        <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-ltrn-primary opacity-75 blur-[2px]">
        </span>
        <span class="relative inline-flex rounded-full h-16 w-16 bg-ltrn-primary blur-sm"></span>
      </div> --%>
      <p class="font-display text-ltrn-subtle"><%= render_slot(@inner_block) %></p>
    </div>
    """
  end

  @doc """
  Renders a simple empty state component
  """
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  slot :inner_block, required: true

  def empty_state_simple(assigns) do
    ~H"""
    <div class={["p-4 border border-dashed border-ltrn-light rounded", @class]} id={@id}>
      <p class="text-sm text-ltrn-subtle text-center"><%= render_slot(@inner_block) %></p>
    </div>
    """
  end

  @doc """
  Renders a fixed bar at the bottom of the page.
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def fixed_bar(assigns) do
    ~H"""
    <div class={["z-20 fixed bottom-0 inset-x-0 p-4 sm:p-6 bg-ltrn-dark", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide_alert("##{@id}")}
      role="alert"
      class={[
        "pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg bg-white shadow-lg ring-1",
        @kind == :info && "ring-green-500/50",
        @kind == :error && "bg-rose-50 ring-ltrn-secondary/50"
      ]}
      {@rest}
    >
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <.icon :if={@kind == :info} name="hero-information-circle" class="h-6 w-6 text-green-500" />
            <.icon
              :if={@kind == :error}
              name="hero-exclamation-circle"
              class="h-6 w-6 text-ltrn-secondary"
            />
          </div>
          <div class="ml-3 w-0 flex-1 pt-0.5">
            <p :if={@title} class="mb-1 text-sm font-bold"><%= @title %></p>
            <p class="text-sm text-ltrn-subtle"><%= msg %></p>
          </div>
          <div class="ml-4 flex flex-shrink-0">
            <button
              type="button"
              class="inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
              aria-label={gettext("close")}
            >
              <span class="sr-only">Close</span>
              <.icon name="hero-x-mark-mini" />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <!-- Global notification live region, render this permanently at the end of the document -->
    <div
      aria-live="assertive"
      class="z-40 pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
    >
      <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
        <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
        <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
        <.flash
          id="client-error"
          kind={:error}
          title={gettext("We can't find the internet")}
          phx-disconnected={show_alert(".phx-client-error #client-error")}
          phx-connected={hide_alert("#client-error")}
          hidden
        >
          <%= gettext("Attempting to reconnect") %>
          <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
        </.flash>

        <.flash
          id="server-error"
          kind={:error}
          title={gettext("Something went wrong!")}
          phx-disconnected={show_alert(".phx-server-error #server-error")}
          phx-connected={hide_alert("#server-error")}
          hidden
        >
          <%= gettext("Hang in there while we get back on track") %>
          <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
        </.flash>
      </div>
    </div>
    """
  end

  defp show_alert(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transform ease-out duration-300 transition-all",
         "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2",
         "translate-y-0 opacity-100 sm:translate-x-0"}
    )
  end

  defp hide_alert(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 100,
      transition: {"transition-all ease-in duration-100", "opacity-100", "opacity-0"}
    )
  end

  @doc """
  Renders a fluid grid.

  View `<.responsive_grid>` for a version with
  horizontal scroll in smaller screens.
  """
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :is_full_width, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def fluid_grid(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "grid gap-4 mx-auto",
        "sm:grid-cols-2 lg:grid-cols-3",
        if(assigns.is_full_width,
          do: "xl:grid-cols-4 2xl:grid-cols-5",
          else: "container lg:max-w-5xl"
        ),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :any, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Highlights entring (mounting) elements in DOM.

  ## Opts

      - `:to_classes`: CSS classes to transition to. Defaults to `"bg-transparent"`.
  """
  def highlight_mounted(js \\ %JS{})

  def highlight_mounted(opts) when is_list(opts),
    do: highlight_mounted(%JS{}, opts)

  def highlight_mounted(js),
    do: highlight_mounted(js, [])

  @doc """
  See `highlight_mounted/1`.
  """
  def highlight_mounted(js, opts) do
    js
    |> JS.transition(
      {
        "ease-out duration-1000",
        "bg-ltrn-mesh-lime",
        Keyword.get(opts, :to_classes, "bg-transparent")
      },
      time: 1000
    )
  end

  @doc """
  Highlights exiting (remove) elements in DOM.

  ## Opts

      - `:to_classes`: CSS classes to transition to. Defaults to `"bg-transparent"`.
  """
  def highlight_remove(js \\ %JS{})

  def highlight_remove(opts) when is_list(opts),
    do: highlight_remove(%JS{}, opts)

  def highlight_remove(js),
    do: highlight_remove(js, [])

  @doc """
  See `highlight_remove/1`.
  """
  def highlight_remove(js, opts) do
    js
    |> JS.transition(
      {
        "ease-out duration-300",
        "bg-ltrn-mesh-rose",
        Keyword.get(opts, :to_classes, "bg-transparent")
      },
      time: 300
    )
  end

  @doc """
  Renders a horizontal rule.
  """
  attr :class, :any, default: nil
  attr :bg_color, :string, default: "bg-ltrn-subtle"

  def hr(assigns) do
    ~H"""
    <hr class={[
      "block w-10 h-2 border-0 #{@bg_color}",
      @class
    ]} />
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :style, :any, default: nil
  attr :id, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={["shrink-0", @name, @class]} style={@style} aria-hidden="true" id={@id} />
    """
  end

  @doc """
  Renders an icon button.

  ## Examples

      <.icon_button name="hero-x-mark" sr_text="Close" />
  """
  attr :type, :string, default: "button"
  attr :class, :any, default: nil
  attr :theme, :string, default: "default", doc: "default | ghost"
  attr :size, :string, default: "normal", doc: "sm | normal"
  attr :rounded, :boolean, default: false
  attr :name, :string, required: true
  attr :sr_text, :string, required: true
  attr :rest, :global, include: ~w(disabled form name value)

  def icon_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        get_button_styles(@theme, @size, @rounded),
        @class
      ]}
      {@rest}
    >
      <span class="sr-only"><%= @sr_text %></span>
      <.icon name={@name} class="w-5 h-5" />
    </button>
    """
  end

  @doc """
  Renders an inline code block.
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def inline_code(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center rounded-sm p-1 font-mono text-xs text-ltrn-secondary bg-slate-100",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
          <dd class="text-zinc-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Parses markdown text to HTML and renders it
  """
  attr :text, :string, required: true
  attr :theme, :string, default: "slate"
  attr :size, :string, default: "sm", doc: "sm | base"
  attr :class, :any, default: nil
  attr :rest, :global

  def markdown(assigns) do
    ~H"""
    <div
      :if={@text}
      class={[
        "prose prose-#{@theme} prose-#{@size}",
        @class
      ]}
      {@rest}
    >
      <%= raw(Earmark.as_html!(@text)) %>
    </div>
    """
  end

  @doc """
  Renders metadata (basically icon + text).
  """
  attr :icon_name, :string, default: nil
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def metadata(assigns) do
    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <.icon :if={@icon_name} name={@icon_name} class="shrink-0 w-6 h-6 text-ltrn-subtle" />
      <div class="text-sm"><%= render_slot(@inner_block) %></div>
    </div>
    """
  end

  @doc """
  Renders the nav menu button.
  """
  attr :class, :any, default: nil

  def nav_menu_button(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "group flex gap-1 items-center p-2 rounded bg-white shadow-xl hover:bg-slate-100",
        @class
      ]}
      phx-click={JS.exec("data-show", to: "#menu")}
      aria-label="open menu"
    >
      <.icon name="hero-bars-3 text-ltrn-subtle" />
      <div class="w-6 h-6 rounded-full bg-ltrn-mesh-primary blur-sm group-hover:blur-none transition-[filter]" />
    </button>
    """
  end

  @doc """
  Renders a page title with menu button.
  """
  attr :class, :any, default: nil
  attr :on_edit_patch, :string, default: nil, doc: "use it to navigate when clicking on edit"
  slot :inner_block, required: true

  def page_title_with_menu(assigns) do
    ~H"""
    <div class={["flex items-center gap-4 justify-between", @class]}>
      <div class="flex items-center gap-2">
        <h1 class="font-display font-black text-3xl">
          <%= render_slot(@inner_block) %>
        </h1>
        <.button
          :if={@on_edit_patch}
          icon_name="hero-pencil-mini"
          sr_text={gettext("Edit")}
          type="link"
          rounded
          theme="ghost"
          patch={@on_edit_patch}
        />
      </div>
      <.nav_menu_button />
    </div>
    """
  end

  @doc """
  Renders a student or staff member badge.

  ## Examples

      <.person_badge person={student} />

  """
  attr :id, :string, default: nil
  attr :person, :map, required: true, doc: "any map with `name` attr"
  attr :theme, :string, default: "subtle", doc: "subtle | cyan"
  attr :on_remove, JS, default: nil
  attr :size, :string, default: "xs", doc: "xs | sm"
  attr :truncate, :boolean, default: false
  attr :navigate, :string, default: nil
  attr :rest, :global

  def person_badge(assigns) do
    {text_size, profile_icon_size} =
      case assigns.size do
        "sm" -> {"text-sm", "sm"}
        _ -> {"text-xs", "xs"}
      end

    name_w = if assigns.truncate, do: "max-w-24"

    assigns =
      assigns
      |> assign(:text_size, text_size)
      |> assign(:profile_icon_size, profile_icon_size)
      |> assign(:name_w, name_w)

    ~H"""
    <span
      id={@id}
      class={[
        "flex items-center gap-2 p-1 rounded-full",
        person_badge_theme_style(@theme)
      ]}
      title={if @truncate, do: @person.name}
      {@rest}
    >
      <.profile_picture
        profile_name={@person.name}
        picture_url={Map.get(@person, :profile_picture_url)}
        size={@profile_icon_size}
        theme="clean"
      />
      <%= if @navigate do %>
        <.link
          navigate={@navigate}
          class={[
            "pr-1 font-bold",
            person_badge_link_theme_style(@theme),
            @text_size,
            @name_w,
            if(@truncate, do: "truncate")
          ]}
        >
          <%= @person.name %>
        </.link>
      <% else %>
        <span class={["pr-1", @text_size, @name_w, if(@truncate, do: "truncate")]}>
          <%= @person.name %>
        </span>
      <% end %>
      <div :if={@on_remove} class="pr-1 -ml-1">
        <button
          type="button"
          class="group flex items-center justify-center rounded-full hover:bg-ltrn-dark/10"
          phx-click={@on_remove}
        >
          <span class="sr-only"><%= gettext("Remove") %></span>
          <.icon
            name="hero-x-mark-mini"
            class="w-3.5 h-3.5 text-ltrn-subtle group-hover:text-ltrn-dark"
          />
        </button>
      </div>
    </span>
    """
  end

  defp person_badge_theme_style("cyan"), do: "text-ltrn-dark bg-ltrn-mesh-cyan"
  defp person_badge_theme_style("staff"), do: "text-ltrn-staff-dark bg-ltrn-staff-lighter"
  defp person_badge_theme_style(_subtle), do: "text-ltrn-subtle bg-ltrn-lighter"

  defp person_badge_link_theme_style("cyan"), do: "hover:text-ltrn-subtle"
  defp person_badge_link_theme_style("staff"), do: "hover:text-ltrn-staff-accent"
  defp person_badge_link_theme_style(_subtle), do: "hover:text-ltrn-subtle"

  @doc """
  Renders a ping.
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def ping(assigns) do
    ~H"""
    <span class={["relative flex h-4 w-4", @class]} id={@id} @rest>
      <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-ltrn-primary opacity-75 blur-[2px]">
      </span>
      <span class="relative inline-flex rounded-full h-4 w-4 bg-ltrn-primary blur-sm"></span>
    </span>
    """
  end

  @doc """
  Renders a profile icon.
  """
  attr :profile_name, :string, required: true
  attr :size, :string, default: "normal", doc: "xs | sm | normal"
  attr :theme, :string, default: "cyan", doc: "cyan | rose | subtle"
  attr :on_click, JS, default: nil
  attr :is_checked, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def profile_icon(%{on_click: %JS{}} = assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "shrink-0 flex items-center justify-center rounded-full font-display font-bold text-center shadow-md",
        profile_icon_size_style(@size),
        profile_icon_theme(@theme, @is_checked),
        @class
      ]}
      title={@profile_name}
      phx-click={@on_click}
      {@rest}
    >
      <%= if @is_checked do %>
        <.icon name="hero-check" />
        <span class="sr-only"><%= gettext("Selected") %></span>
      <% else %>
        <%= profile_icon_initials(@profile_name) %>
      <% end %>
    </button>
    """
  end

  def profile_icon(assigns) do
    ~H"""
    <div
      class={[
        "shrink-0 flex items-center justify-center rounded-full font-display font-bold text-center shadow-md",
        profile_icon_size_style(@size),
        profile_icon_theme(@theme, @is_checked),
        @class
      ]}
      title={@profile_name}
      {@rest}
    >
      <%= if @is_checked do %>
        <.icon name="hero-check" />
        <span class="sr-only"><%= gettext("Selected") %></span>
      <% else %>
        <%= profile_icon_initials(@profile_name) %>
      <% end %>
    </div>
    """
  end

  defp profile_icon_size_style("xs"), do: "w-6 h-6 text-xs"
  defp profile_icon_size_style("sm"), do: "w-8 h-8 text-xs"
  defp profile_icon_size_style(_normal), do: "w-10 h-10 text-sm"

  @profile_icon_themes %{
    "subtle" => "text-ltrn-subtle bg-ltrn-lighter",
    "cyan" => "text-ltrn-dark bg-ltrn-mesh-primary",
    "rose" => "text-ltrn-dark bg-ltrn-mesh-rose",
    "diff" => "text-ltrn-diff-lightest bg-ltrn-diff-accent"
  }

  defp profile_icon_theme(theme, false),
    do: Map.get(@profile_icon_themes, theme, @profile_icon_themes["default"])

  defp profile_icon_theme(_theme, true),
    do: "text-white bg-ltrn-dark"

  defp profile_icon_initials(full_name) do
    case String.split(full_name, ~r{\s}, trim: true) do
      [] ->
        ""

      [single_name] ->
        String.first(single_name)

      names ->
        [first_initial | other_initials] =
          names
          |> Enum.map(&String.first(&1))

        "#{first_initial}#{List.last(other_initials)}"
    end
  end

  @doc """
  Renders a profile icon with name.
  """
  attr :profile_name, :string, required: true
  attr :theme, :string, default: "cyan"
  attr :icon_size, :string, default: "normal"
  attr :extra_info, :string, default: nil
  attr :on_click, JS, default: nil
  attr :is_checked, :boolean, default: false
  attr :navigate, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def profile_icon_with_name(assigns) do
    ~H"""
    <div class={["flex gap-2 items-center text-sm", @class]}>
      <.profile_icon
        profile_name={@profile_name}
        theme={@theme}
        size={@icon_size}
        on_click={@on_click}
        is_checked={@is_checked}
        {@rest}
      />
      <div class="flex-1">
        <%= if @navigate do %>
          <.link
            navigate={@navigate}
            target="_blank"
            class={[
              "font-bold hover:text-ltrn-subtle",
              if(@extra_info, do: "line-clamp-1", else: "line-clamp-2")
            ]}
          >
            <%= @profile_name %>
          </.link>
        <% else %>
          <div class={if(@extra_info, do: "line-clamp-1", else: "line-clamp-2")}>
            <%= @profile_name %>
          </div>
        <% end %>
        <div :if={@extra_info} class="line-clamp-1 text-xs text-ltrn-subtle"><%= @extra_info %></div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a profile picture.
  """
  attr :picture_url, :string, required: true
  attr :profile_name, :string, default: nil, doc: "render initials when there's no image"
  attr :theme, :string, default: "default", doc: "default | clean"
  attr :size, :string, default: "md", doc: "xs | sm | md | lg | xl | 2xl"
  attr :class, :any, default: nil

  def profile_picture(%{picture_url: nil, profile_name: nil} = assigns) do
    ~H"""
    <div class={[
      "relative shrink-0 flex items-center justify-center rounded-full font-display text-center bg-white overflow-hidden",
      profile_picture_theme_style(@theme),
      profile_picture_size_style(@size),
      @class
    ]}>
      <.icon name="hero-user" class={["text-ltrn-subtle", profile_picture_icon_size_style(@size)]} />
    </div>
    """
  end

  def profile_picture(assigns) do
    picture_url = profile_picture_render_url(assigns.picture_url, assigns.size)
    assigns = assign(assigns, :picture_url, picture_url)

    ~H"""
    <div
      class={[
        "relative shrink-0 flex items-center justify-center rounded-full font-display text-center bg-white overflow-hidden",
        profile_picture_theme_style(@theme),
        profile_picture_size_style(@size),
        @class
      ]}
      title={@profile_name}
    >
      <%= if @picture_url do %>
        <img src={@picture_url} class="object-cover w-full h-full" />
      <% else %>
        <%= profile_icon_initials(@profile_name) %>
      <% end %>
    </div>
    """
  end

  # resize to width/height * 2 (144dpi)
  defp profile_picture_render_url(picture_url, _size) when not is_binary(picture_url),
    do: picture_url

  defp profile_picture_render_url(picture_url, "xs"),
    do: object_url_to_render_url(picture_url, width: 48, height: 48)

  defp profile_picture_render_url(picture_url, "sm"),
    do: object_url_to_render_url(picture_url, width: 64, height: 64)

  defp profile_picture_render_url(picture_url, "lg"),
    do: object_url_to_render_url(picture_url, width: 160, height: 160)

  defp profile_picture_render_url(picture_url, "xl"),
    do: object_url_to_render_url(picture_url, width: 256, height: 256)

  defp profile_picture_render_url(picture_url, "2xl"),
    do: object_url_to_render_url(picture_url, width: 480, height: 480)

  defp profile_picture_render_url(picture_url, _md),
    do: object_url_to_render_url(picture_url, width: 80, height: 80)

  defp profile_picture_theme_style("clean"), do: ""
  defp profile_picture_theme_style(_default), do: "ltrn-bg-profile"

  defp profile_picture_size_style("xs"), do: "w-6 h-6 font-bold text-xs"
  defp profile_picture_size_style("sm"), do: "w-8 h-8 font-bold text-xs"
  defp profile_picture_size_style("lg"), do: "w-20 h-20 font-black text-2xl"
  defp profile_picture_size_style("xl"), do: "w-32 h-32 font-black text-4xl"
  defp profile_picture_size_style("2xl"), do: "w-60 h-60 font-black text-6xl"
  defp profile_picture_size_style(_md), do: "w-10 h-10 font-bold text-sm"

  defp profile_picture_icon_size_style("xs"), do: "w-5 h-5"
  defp profile_picture_icon_size_style("sm"), do: "w-6 h-6"
  defp profile_picture_icon_size_style("lg"), do: "w-12 h-12"
  defp profile_picture_icon_size_style("xl"), do: "w-20 h-20"
  defp profile_picture_icon_size_style("2xl"), do: "w-32 h-32"
  defp profile_picture_icon_size_style(_md), do: "w-6 h-6"

  @doc """
  Renders a responsive container.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def responsive_container(assigns) do
    ~H"""
    <div
      class={[
        "container px-6 mx-auto",
        "sm:px-10 lg:max-w-5xl",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a responsive grid.

  Will render a horizontal scroll on small screens,
  and a grid starting on `sm` breakpoint.

  View also `<.fluid_grid>` for an alternative without the
  horizontal scroll.
  """
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :is_full_width, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def responsive_grid(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex items-stretch gap-6 mx-auto overflow-x-auto overflow-y-visible",
        "sm:grid sm:grid-cols-2 lg:grid-cols-3 sm:overflow-x-visible",
        if(assigns.is_full_width,
          do: "xl:grid-cols-4 2xl:grid-cols-5",
          else: "container lg:max-w-5xl"
        ),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Util for ScrollToTop hook implementation.
  """
  attr :id, :string, required: true
  attr :overlay_id, :string, required: true

  def scroll_to_top(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="ScrollToTop"
      data-scroll-to-selector={"##{@overlay_id} *[aria-modal=true]"}
    />
    """
  end

  @doc """
  Renders a spinner.
  """
  attr :class, :any, default: nil

  def spinner(assigns) do
    ~H"""
    <div class={["h-5 w-5 overflow-hidden", @class]}>
      <svg
        class="animate-spin h-full w-full"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4">
        </circle>
        <path
          class="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        >
        </path>
      </svg>
    </div>
    """
  end

  @doc """
  Toggle component.
  """

  attr :enabled, :boolean, required: true
  attr :class, :any, default: nil
  attr :sr_text, :string, default: nil
  attr :theme, :string, default: "default"
  attr :rest, :global

  def toggle(assigns) do
    ~H"""
    <button
      type="button"
      class={[
        "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-offset-2",
        toggle_theme(@theme),
        if(@enabled, do: toggle_enabled_theme(@theme), else: toggle_disabled_theme(@theme)),
        @class
      ]}
      role="switch"
      aria-checked="false"
      {@rest}
    >
      <span :if={@sr_text} class="sr-only"><%= @sr_text %></span>
      <span
        aria-hidden="true"
        class={[
          "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
          if(@enabled, do: "translate-x-5", else: "translate-x-0")
        ]}
      >
      </span>
    </button>
    """
  end

  @toggle_themes %{
    "default" => "focus:ring-ltrn-primary",
    "diff" => "focus:ring-ltrn-diff-accent",
    "student" => "focus:ring-ltrn-student-accent",
    "staff" => "focus:ring-ltrn-staff-accent"
  }

  defp toggle_theme(theme),
    do: Map.get(@toggle_themes, theme, @toggle_themes["default"])

  @toggle_enabled_themes %{
    "default" => "bg-ltrn-primary",
    "diff" => "bg-ltrn-diff-accent",
    "student" => "bg-ltrn-student-accent",
    "staff" => "bg-ltrn-staff-accent"
  }

  defp toggle_enabled_theme(theme),
    do: Map.get(@toggle_enabled_themes, theme, @toggle_enabled_themes["default"])

  @toggle_disabled_themes %{
    "default" => "bg-ltrn-lighter"
  }

  defp toggle_disabled_theme(theme),
    do: Map.get(@toggle_disabled_themes, theme, @toggle_disabled_themes["default"])

  @doc """
  Renders a sortable card
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :is_move_up_disabled, :boolean, default: false
  attr :on_move_up, JS, required: true
  attr :is_move_down_disabled, :boolean, default: false
  attr :on_move_down, JS, required: true

  slot :inner_block, required: true

  def sortable_card(assigns) do
    ~H"""
    <div id={@id} class={["flex items-center gap-4 p-4 rounded bg-white shadow-lg", @class]}>
      <div class="flex-1 min-w-0">
        <%= render_slot(@inner_block) %>
      </div>
      <div class="shrink-0 flex flex-col gap-2">
        <.icon_button
          type="button"
          sr_text={gettext("Move up")}
          name="hero-chevron-up-mini"
          theme="ghost"
          rounded
          size="sm"
          disabled={@is_move_up_disabled}
          phx-click={@on_move_up}
        />
        <.icon_button
          type="button"
          sr_text={gettext("Move moment down")}
          name="hero-chevron-down-mini"
          theme="ghost"
          rounded
          size="sm"
          disabled={@is_move_down_disabled}
          phx-click={@on_move_down}
        />
      </div>
    </div>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="w-[40rem] sm:w-full">
      <thead class="text-sm text-left leading-6 text-zinc-500">
        <tr>
          <th :for={col <- @col} class="p-2 pr-6 pb-4 font-normal"><%= col[:label] %></th>
          <th :if={@action != []} class="relative p-2 pb-4">
            <span class="sr-only"><%= gettext("Actions") %></span>
          </th>
        </tr>
      </thead>
      <tbody
        id={@id}
        phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
      >
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
          <td
            :for={{col, i} <- Enum.with_index(@col)}
            phx-click={@row_click && @row_click.(row)}
            class={["relative p-2", @row_click && "hover:cursor-pointer"]}
          >
            <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
              <%= render_slot(col, @row_item.(row)) %>
            </span>
          </td>
          <td :if={@action != []} class="relative w-14 p-2">
            <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
              <span
                :for={action <- @action}
                class="relative font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
              >
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.stream_table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.stream_table>
  """
  attr :id, :string, required: true
  attr :stream, :any, required: true
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def stream_table(assigns) do
    ~H"""
    <table class="w-[40rem] sm:w-full">
      <thead class="text-sm text-left text-ltrn-dark">
        <tr>
          <th :for={col <- @col} class="py-4 px-2 font-bold"><%= col[:label] %></th>
          <th :if={@action != []} class="relative p-2 pb-4">
            <span class="sr-only"><%= gettext("Actions") %></span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update="stream" class="text-sm">
        <tr :for={{row_id, row} <- @stream} id={row_id} class="group hover:bg-white hover:shadow-md">
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={["p-2", @row_click && "hover:cursor-pointer"]}
          >
            <%= render_slot(col, row) %>
          </td>
          <td :if={@action != []} class="relative w-14 p-2">
            <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
              <span
                :for={action <- @action}
                class="relative font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
              >
                <%= render_slot(action, row) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(Lanttern.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Lanttern.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Renders a tooltip.

  Tooltip parent should have `"group relative"` class.
  """

  attr :h_pos, :string, default: "left", doc: "left | center | right"
  attr :v_pos, :string, default: "top", doc: "top | bottom"
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def tooltip(assigns) do
    assigns =
      assigns
      |> assign(:tooltip_pos_class, get_tooltip_pos_class(assigns))
      |> assign(:inner_pos_class, get_tooltip_inner_pos_class(assigns))

    ~H"""
    <div class={[
      "pointer-events-none absolute w-80 max-w-max",
      "opacity-0 transition-opacity group-hover:opacity-100",
      @tooltip_pos_class,
      @class
    ]}>
      <div class={[
        "relative p-2 rounded text-sm bg-ltrn-dark text-white",
        @inner_pos_class
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp get_tooltip_pos_class(assigns) do
    v_class =
      case assigns do
        %{v_pos: "bottom"} -> "top-full mt-2"
        _v_pos_top -> "bottom-full mb-2"
      end

    h_class =
      case assigns do
        %{h_pos: "center"} -> "left-1/2"
        %{h_pos: "right"} -> "right-0"
        _h_pos_left -> "left-0"
      end

    v_class <> " " <> h_class
  end

  defp get_tooltip_inner_pos_class(%{h_pos: "center"}), do: "-left-1/2"
  defp get_tooltip_inner_pos_class(_assigns), do: ""

  @doc """
  Renders a block with a profile icon.
  """
  attr :profile_name, :string, required: true
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :theme, :string, default: "cyan"
  attr :rest, :global
  slot :inner_block, required: true

  def user_icon_block(assigns) do
    ~H"""
    <div id={@id} class={["flex gap-4", @class]} {@rest}>
      <.profile_icon profile_name={@profile_name} class="shrink-0" theme={@theme} />
      <div class="flex-1">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
