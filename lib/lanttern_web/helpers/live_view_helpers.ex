defmodule LantternWeb.LiveViewHelpers do
  @moduledoc """
  Set of reusable helpers for live views
  """

  alias Lanttern.Personalization

  @doc """
  Handle params and profile filters syncronization.

  This helper function is meant to be used in views where we expect filter params.

  When the param is updated (in cases where there are filters persisted in profile settings
  but no filters in the URL), this function triggers a `push_patch/2` updating the URL
  according to `handle_assigns` param.
  """
  def handle_params_and_profile_filters_sync(
        params,
        socket,
        filters,
        handle_assigns,
        handle_update_params
      ) do
    case Personalization.sync_params_and_profile_filters(
           params,
           socket.assigns.current_user,
           filters
         ) do
      {:noop, _} ->
        {:noreply, handle_assigns.(socket, params)}

      {:updated, params} ->
        {:noreply,
         socket
         |> Phoenix.LiveView.push_patch(to: handle_update_params.(params), replace: true)}
    end
  end
end
