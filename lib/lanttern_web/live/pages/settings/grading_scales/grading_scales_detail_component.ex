defmodule LantternWeb.GradingScalesDetailComponent do
  @moduledoc """
  Detail component for displaying grading scale information.
  """

  use LantternWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <.header>
      Scale {@scale.id}
      <:subtitle>This is a scale record from your database.</:subtitle>
      <:actions>
        <.link navigate={~p"/settings/grading_scales/#{@scale}/edit"}>
          <.button>Edit scale</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Name">{@scale.name}</:item>
      <:item title="Type">{@scale.type}</:item>
      <:item title="Start">{@scale.start}</:item>
      <:item title="Stop">{@scale.stop}</:item>
      <:item title="Breakpoints">{inspect(@scale.breakpoints)}</:item>
    </.list>
    """
  end
end
