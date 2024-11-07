defmodule LantternWeb.LiveViewHelpers do
  @moduledoc """
  Set of reusable helpers for live views
  """
  import Phoenix.LiveView

  @doc """
  Creates a `handle_info` hook to manage the message sent by `LantternWeb.LiveComponentHelpers.delegate_navigation/2`.

  Based on https://sevenseacat.net/posts/2023/flash-messages-in-phoenix-liveview-components/
  """
  def on_mount(_name, _params, _session, socket),
    do: {:cont, attach_hook(socket, :delegated_nav, :handle_info, &maybe_receive_delegated_nav/2)}

  defp maybe_receive_delegated_nav({:delegated_nav, opts}, socket),
    do: apply_delegated_nav(socket, opts)

  defp maybe_receive_delegated_nav(_, socket), do: {:cont, socket}

  defp apply_delegated_nav(socket, []), do: {:halt, socket}

  defp apply_delegated_nav(socket, [{:put_flash, {kind, message}} | opts]) do
    socket
    |> put_flash(kind, message)
    |> apply_delegated_nav(opts)
  end

  defp apply_delegated_nav(socket, [{:push_patch, push_patch_opts} | opts]) do
    socket
    |> push_patch(push_patch_opts)
    |> apply_delegated_nav(opts)
  end

  defp apply_delegated_nav(socket, [{:push_navigate, push_navigate_opts} | opts]) do
    socket
    |> push_navigate(push_navigate_opts)
    |> apply_delegated_nav(opts)
  end

  defp apply_delegated_nav(socket, [_ | opts]),
    do: apply_delegated_nav(socket, opts)
end
