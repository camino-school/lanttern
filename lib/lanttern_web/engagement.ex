defmodule LantternWeb.Engagement do
  @moduledoc """
  `on_mount` hook for tracking engagement metrics.
  """

  alias Lanttern.Engagement

  def on_mount(:track_dau, _params, _session, socket) do
    scope = Map.get(socket.assigns, :current_scope)
    Engagement.track_dau(scope)
    {:cont, socket}
  end
end
