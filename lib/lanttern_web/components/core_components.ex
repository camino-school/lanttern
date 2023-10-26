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
  import LantternWeb.Gettext

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
        @kind == :error && "bg-rose-50 ring-rose-500/50"
      ]}
      {@rest}
    >
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <.icon :if={@kind == :info} name="hero-information-circle" class="h-6 w-6 text-green-500" />
            <.icon :if={@kind == :error} name="hero-exclamation-circle" class="h-6 w-6 text-rose-500" />
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
        <.flash kind={:info} title="Success!" flash={@flash} />
        <.flash kind={:error} title="Error!" flash={@flash} />
        <.flash
          id="client-error"
          kind={:error}
          title="We can't find the internet"
          phx-disconnected={show_alert(".phx-client-error #client-error")}
          phx-connected={hide_alert("#client-error")}
          hidden
        >
          Attempting to reconnect <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
        </.flash>

        <.flash
          id="server-error"
          kind={:error}
          title="Something went wrong!"
          phx-disconnected={show_alert(".phx-server-error #server-error")}
          phx-connected={hide_alert("#server-error")}
          hidden
        >
          Hang in there while we get back on track
          <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
        </.flash>
      </div>
    </div>
    """
  end

  def show_alert(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transform ease-out duration-300 transition-all",
         "translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2",
         "translate-y-0 opacity-100 sm:translate-x-0"}
    )
  end

  def hide_alert(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 100,
      transition: {"transition-all ease-in duration-100", "opacity-100", "opacity-0"}
    )
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :any, default: nil
  attr :theme, :string, default: "default", doc: "default | ghost"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "rounded-sm py-2 px-2 font-display text-sm font-bold",
        "phx-submit-loading:opacity-50 phx-click-loading:opacity-50 phx-click-loading:pointer-events-none",
        button_theme(@theme),
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_theme(theme) do
    %{
      "default" => "bg-ltrn-primary hover:bg-cyan-300 shadow-sm",
      "ghost" => "text-ltrn-subtle bg-transparent hover:bg-slate-100"
    }
    |> Map.get(theme, "bg-ltrn-primary hover:bg-cyan-300")
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
  attr :id, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" id={@id} />
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
      Gettext.dngettext(LantternWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(LantternWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Renders a badge.
  """
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :theme, :string, default: "default"

  attr :get_bagde_color_from, :map,
    default: nil,
    doc: "map with `:bg_color` and `:text_color` keys"

  attr :show_remove, :boolean, default: false
  attr :rest, :global, doc: "use to pass phx-* bindings to the remove button"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span
      id={@id}
      class={[
        "inline-flex items-center rounded-sm px-2 py-1 font-mono text-xs text-slate-700",
        badge_theme(@theme),
        @class
      ]}
      style={badge_colors_style(@get_bagde_color_from)}
    >
      <%= render_slot(@inner_block) %>
      <button
        :if={@show_remove}
        type="button"
        class="group relative ml-1 -mr-1 h-3.5 w-3.5 rounded-[1px] hover:bg-ltrn-subtle/20"
        {@rest}
      >
        <span class="sr-only">Remove</span>
        <.icon name="hero-x-mark-mini" class="w-3.5 text-ltrn-subtle hover:text-slate-700" />
        <span class="absolute -inset-1"></span>
      </button>
    </span>
    """
  end

  defp badge_theme(theme) do
    %{
      "default" => "bg-gray-100",
      "cyan" => "bg-cyan-50"
    }
    |> Map.get(theme, "bg-gray-100")
  end

  defp badge_colors_style(%{bg_color: bg_color, text_color: text_color}) do
    "background-color: #{bg_color}; color: #{text_color}"
  end

  defp badge_colors_style(_), do: ""

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
  Renders a profile icon.
  """
  attr :profile_name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def profile_icon(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center justify-center w-10 h-10 rounded-full font-display text-sm font-bold text-center bg-cyan-50 shadow-md",
        @class
      ]}
      title={@profile_name}
      {@rest}
    >
      <%= profile_icon_initials(@profile_name) %>
    </div>
    """
  end

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
  attr :class, :any, default: nil
  attr :rest, :global

  def icon_with_name(assigns) do
    ~H"""
    <div class={["flex gap-2 items-center text-sm", @class]}>
      <.profile_icon profile_name={@profile_name} /> <%= @profile_name %>
    </div>
    """
  end

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
  Renders a page title with menu button.
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def page_title_with_menu(assigns) do
    ~H"""
    <div class={["flex items-center justify-between", @class]}>
      <h1 class="font-display font-black text-3xl">
        <%= render_slot(@inner_block) %>
      </h1>
      <button
        type="button"
        class="group flex gap-1 items-center p-2 rounded bg-white shadow-xl hover:bg-slate-100"
        phx-click={JS.exec("data-show", to: "#menu")}
        aria-label="open menu"
      >
        <.icon name="hero-bars-3 text-ltrn-subtle" />
        <div class="w-6 h-6 rounded-full bg-ltrn-mesh-primary blur-sm group-hover:blur-none transition-[filter]" />
      </button>
    </div>
    """
  end

  @doc """
  Renders an empty state block
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def empty_state(assigns) do
    ~H"""
    <div class={["text-center", @class]}>
      <div class="p-10">
        <div class="animate-pulse h-24 w-24 rounded-full mx-auto bg-ltrn-hairline blur-md"></div>
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
  Parses markdown text to HTML and renders it
  """
  attr :text, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def markdown(assigns) do
    ~H"""
    <div class={["prose prose-slate", @class]} {@rest}>
      <%= raw(Earmark.as_html!(@text)) %>
    </div>
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
end
