defmodule LantternWeb.DashboardLive do
  @moduledoc """
  Dashboard live view
  """

  use LantternWeb, :live_view

  # lifecycle

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Dashboard"))

    {:ok, socket}
  end
end
