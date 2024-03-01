defmodule LantternWeb.CurriculaLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula

  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:curricula, Curricula.list_curricula())

    {:ok, socket}
  end
end
