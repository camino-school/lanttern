defmodule LantternWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LantternWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders the layout for signed in users.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, required: true
  # todo: migrate current_user to current_scope
  # attr :current_scope, :map,
  #   default: nil,
  #   doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  attr :current_path, :string, required: true
  attr :no_bg, :boolean, default: false
  slot :inner_block, required: true

  def app_logged_in(assigns) do
    ~H"""
    <main class={["min-h-screen", if(!@no_bg, do: "ltrn-bg-main")]}>
      {render_slot(@inner_block)}
    </main>
    <.live_component
      module={LantternWeb.MenuComponent}
      id="menu"
      current_user={@current_user}
      current_path={@current_path}
    />
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the layout for root admins.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <header class="flex justify-between w-full p-2 border-b border-ltrn-subtle">
      <div class="flex gap-4">
        <.link href={~p"/admin"}>Admin home</.link>
      </div>
      <div class="flex gap-4">
        <.link href={~p"/dashboard"}>Back to main</.link>
        <.link href={~p"/users/log_out"} method="delete" data-confirm="Are you sure?">Logout</.link>
      </div>
    </header>
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto">
        {render_slot(@inner_block)}
      </div>
    </main>
    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <!-- Global notification live region, render this permanently at the end of the document -->
    <div
      id={@id}
      aria-live="polite"
      class="z-90 pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
    >
      <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
        <.flash kind={:info} flash={@flash} />
        <.flash kind={:error} flash={@flash} />

        <.flash
          id="client-error"
          kind={:error}
          title={gettext("We can't find the internet")}
          phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
          phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
          hidden
        >
          {gettext("Attempting to reconnect")}
          <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
        </.flash>

        <.flash
          id="server-error"
          kind={:error}
          title={gettext("Something went wrong!")}
          phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
          phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
          hidden
        >
          {gettext("Attempting to reconnect")}
          <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
        </.flash>
      </div>
    </div>
    """
  end

  # @doc """
  # Provides dark vs light theme toggle based on themes defined in app.css.

  # See <head> in root.html.heex which applies the theme before page load.
  # """
  # def theme_toggle(assigns) do
  #   ~H"""
  #   <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
  #     <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

  #     <button
  #       class="flex p-2 cursor-pointer w-1/3"
  #       phx-click={JS.dispatch("phx:set-theme")}
  #       data-phx-theme="system"
  #     >
  #       <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
  #     </button>

  #     <button
  #       class="flex p-2 cursor-pointer w-1/3"
  #       phx-click={JS.dispatch("phx:set-theme")}
  #       data-phx-theme="light"
  #     >
  #       <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
  #     </button>

  #     <button
  #       class="flex p-2 cursor-pointer w-1/3"
  #       phx-click={JS.dispatch("phx:set-theme")}
  #       data-phx-theme="dark"
  #     >
  #       <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
  #     </button>
  #   </div>
  #   """
  # end
end
