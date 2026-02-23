defmodule LantternWeb.LearningContext.ToggleStrandStarActionComponent do
  @moduledoc """
  Renders a star icon with a tooltip.

  Used in the strand and moment pages header.
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <button
        type="button"
        phx-click={JS.push(@on_click_event, target: @myself)}
        class={["hover:opacity-50", @icon_color_class]}
      >
        <.icon name="hero-star-mini" />
      </button>
      <.tooltip id={"#{@id}-star-tooltip"}>
        {@tooltip_text}
      </.tooltip>
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
    socket
    |> assign_color_tooltip_and_event()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_color_tooltip_and_event(socket) do
    {icon_color_class, tooltip_text, on_click_event} =
      if socket.assigns.strand.is_starred do
        {
          "text-ltrn-primary",
          gettext("Starred strand"),
          "unstar_strand"
        }
      else
        {
          "text-ltrn-subtle",
          gettext("Click to star strand"),
          "star_strand"
        }
      end

    socket
    |> assign(:icon_color_class, icon_color_class)
    |> assign(:tooltip_text, tooltip_text)
    |> assign(:on_click_event, on_click_event)
  end

  # event handlers

  @impl true
  def handle_event("star_strand", _params, socket) do
    strand = socket.assigns.strand

    LearningContext.star_strand(
      strand.id,
      socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, _strand} ->
        strand = %{strand | is_starred: true}

        socket =
          socket
          |> assign(:strand, strand)
          |> assign_color_tooltip_and_event()

        notify(__MODULE__, {:strand_starred, strand}, socket.assigns)

        {:noreply, socket}

      {:error, changeset} ->
        notify(__MODULE__, {:error, changeset}, socket.assigns)
        {:noreply, socket}
    end
  end

  def handle_event("unstar_strand", _params, socket) do
    strand = socket.assigns.strand

    LearningContext.unstar_strand(
      strand.id,
      socket.assigns.current_user.current_profile_id
    )
    |> case do
      {:ok, _strand} ->
        strand = %{strand | is_starred: false}

        socket =
          socket
          |> assign(:strand, strand)
          |> assign_color_tooltip_and_event()

        notify(__MODULE__, {:strand_unstarred, strand}, socket.assigns)

        {:noreply, socket}

      {:error, changeset} ->
        notify(__MODULE__, {:error, changeset}, socket.assigns)
        {:noreply, socket}
    end
  end
end
