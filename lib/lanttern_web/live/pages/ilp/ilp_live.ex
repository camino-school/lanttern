defmodule LantternWeb.ILPLive do
  use LantternWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("ILP"))

    {:ok, socket}
  end
end
