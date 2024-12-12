defmodule LantternWeb.MomentLive.OverviewComponent do
  use LantternWeb, :live_component

  alias Lanttern.Curricula

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.cover_image
        image_url={@cover_image_url}
        alt_text={gettext("Strand cover image")}
        empty_state_text={gettext("Strand without cover image")}
        theme="lime"
        size="sm"
      />
      <.responsive_container class="mt-10">
        <h1 class="font-display font-black text-4xl"><%= @moment.name %></h1>
        <p class="mt-2 font-display font-black text-2xl text-ltrn-subtle">
          <%= gettext("Moment of %{strand}", strand: @strand.name) %>
        </p>
        <div class="flex flex-wrap gap-2 mt-4">
          <.badge :for={subject <- @moment.subjects} theme="dark">
            <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", subject.name) %>
          </.badge>
        </div>
        <.markdown text={@moment.description} class="mt-10" />
        <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Curriculum") %></h3>
        <div id="moment-curriculum-items" phx-update="stream">
          <div :for={{dom_id, curriculum_item} <- @streams.curriculum_items} id={dom_id} class="mt-6">
            <.badge theme="dark"><%= curriculum_item.curriculum_component.name %></.badge>
            <p class="mt-4"><%= curriculum_item.name %></p>
          </div>
        </div>
      </.responsive_container>
    </div>
    """
  end

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
    socket
    |> assign_cover_image_url()
    |> stream_curriculum_items()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_cover_image_url(socket) do
    cover_image_url =
      object_url_to_render_url(
        socket.assigns.strand.cover_image_url,
        width: 1280,
        height: 640
      )

    assign(socket, :cover_image_url, cover_image_url)
  end

  defp stream_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_moment_curriculum_items(
        socket.assigns.moment.id,
        preloads: :curriculum_component
      )

    stream(socket, :curriculum_items, curriculum_items)
  end
end
