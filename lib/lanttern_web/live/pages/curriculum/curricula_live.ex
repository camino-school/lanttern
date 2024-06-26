defmodule LantternWeb.CurriculaLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:curricula, Curricula.list_curricula())
      |> assign(:page_title, gettext("Curriculum"))

    {:ok, socket}
  end
end
