defmodule LantternWeb.LiveComponentHelpers do
  @moduledoc """
  Set of reusable helpers for live components
  """

  @doc """
  Send notification to parent or component based on
  `:notify_parent` and `:notify_component` assigns.
  """
  @spec notify(module :: atom(), msg :: any(), assigns :: map()) :: any()
  def notify(module, msg, %{notify_parent: true}),
    do: send(self(), {module, msg})

  def notify(module, msg, %{notify_component: %Phoenix.LiveComponent.CID{} = cid}),
    do: Phoenix.LiveView.send_update(cid, action: {module, msg})

  def notify(_module, _msg, _assigns), do: nil

  @doc """
  Send notification to parent based on `:notify_parent` assign.
  """
  def notify_parent(module, msg, %{notify_parent: true}),
    do: send(self(), {module, msg})

  def notify_parent(_module, _msg, _assigns), do: nil

  @doc """
  Send update to component based on `:notify_component` assign.
  """
  def notify_component(module, msg, %{notify_component: %Phoenix.LiveComponent.CID{} = cid}),
    do: Phoenix.LiveView.send_update(cid, action: {module, msg})

  def notify_component(_module, _msg, _assigns), do: nil

  @doc """
  Handles navigation based on socket assigns.

  Usually used to navigate after successful actions.
  """
  def handle_navigation(socket, arg \\ %{})

  def handle_navigation(%{assigns: %{patch: patch}} = socket, arg)
      when is_function(patch),
      do: Phoenix.LiveView.push_patch(socket, to: patch.(arg))

  def handle_navigation(%{assigns: %{patch: patch}} = socket, _arg)
      when is_binary(patch),
      do: Phoenix.LiveView.push_patch(socket, to: patch)

  def handle_navigation(%{assigns: %{navigate: navigate}} = socket, arg)
      when is_function(navigate),
      do: Phoenix.LiveView.push_navigate(socket, to: navigate.(arg))

  def handle_navigation(%{assigns: %{navigate: navigate}} = socket, _arg)
      when is_binary(navigate),
      do: Phoenix.LiveView.push_navigate(socket, to: navigate)

  def handle_navigation(socket, _arg), do: socket

  @doc """
  Send a message to parent live view with a `put_flash/3`, `push_patch/2`, and/or `push_navigate/2` args.

  View `LantternWeb.LiveViewHelpers` to check how the parent live view handles the message.

  Based on https://sevenseacat.net/posts/2023/flash-messages-in-phoenix-liveview-components/

  ### Supported opts

  - `put_flash: {kind, message}`
  - `push_patch: push_patch_opts`
  - `push_navigate: push_navigate_opts`
  """
  def delegate_navigation(socket, opts) do
    send(self(), {:delegated_nav, opts})
    socket
  end
end
