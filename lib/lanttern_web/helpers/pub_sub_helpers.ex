defmodule LantternWeb.PubSubHelpers do
  @moduledoc """
  Set of reusable PubSub helpers for live views
  """

  @pubsub Lanttern.PubSub

  def unsubscribe_all do
    @pubsub
    |> Registry.keys(self())
    |> Enum.each(&Phoenix.PubSub.unsubscribe(@pubsub, &1))
  end
end
