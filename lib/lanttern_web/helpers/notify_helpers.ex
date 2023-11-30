defmodule LantternWeb.Helpers.NotifyHelpers do
  def notify_parent(module, msg, %{notify_parent: true}),
    do: send(self(), {module, msg})

  def notify_parent(_module, _msg, _assigns), do: nil

  def notify_component(module, msg, %{notify_component: %Phoenix.LiveComponent.CID{} = cid}),
    do: Phoenix.LiveView.send_update(cid, action: {module, msg})

  def notify_component(_module, _msg, _assigns), do: nil
end
