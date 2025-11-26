defmodule LantternWeb.StrandLive.AboutComponent do
  use LantternWeb, :live_component

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.responsive_container class="pb-10">
        <.cover_image
          image_url={@cover_image_url}
          alt_text={gettext("Strand cover image")}
          empty_state_text={gettext("Edit strand to add a cover image")}
          size="sm"
        />
        <hgroup class="mt-10 font-display font-black">
          <h1 class="text-4xl sm:text-5xl">{@strand.name}</h1>
          <p :if={@strand.type} class="mt-2 text-xl sm:text-2xl">{@strand.type}</p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand.subjects} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name)}
          </.badge>
          <.badge :for={year <- @strand.years} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name)}
          </.badge>
        </div>
        <.markdown text={@strand.description} class="mt-10 line-clamp-3" strip_tags />
        <.button type="link" navigate={~p"/strands/#{@strand.id}/overview"} class="mt-4">
          {gettext("Full overview")}
        </.button>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    strand = socket.assigns.strand

    socket
    |> assign(
      :cover_image_url,
      object_url_to_render_url(strand.cover_image_url, width: 1280, height: 640)
    )
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket
end
