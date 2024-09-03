defmodule LantternWeb.Assessments.EntryParticleComponent do
  @moduledoc """
  This component renders assessment point particles, small visual representations
  of assessments for dataviz.

  As multiple instances of this components are rendered at the same time,
  the component also handles the ordinal values "preload" through `update_many/1`.

  #### Expected external assigns

      attr :entry, AssessmentPointEntry
      attr :class, :any

  """
  use LantternWeb, :live_component

  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center justify-center w-6 h-6 max-w-6 rounded-sm text-base",
        @additional_classes,
        @class
      ]}
      style={@style}
    >
      <%= @text %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    ordinal_values_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.entry && assigns.entry.ordinal_value_id
      end)
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.uniq()

    # map format
    # %{
    #   ordinal_value_id: %OrdinalValue{},
    #   ...
    # }
    ovs_map =
      Grading.list_ordinal_values(ids: ordinal_values_ids)
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    assigns_sockets
    |> Enum.map(&update_single(&1, ovs_map))
  end

  defp update_single({assigns, socket}, ovs_map) do
    {additional_classes, style, text} =
      case assigns.entry do
        %{scale_type: "ordinal"} = entry ->
          ordinal_value = ovs_map[entry.ordinal_value_id]

          style =
            "color: #{ordinal_value.text_color}; background-color: #{ordinal_value.bg_color}"

          {nil, style, "•"}

        %{scale_type: "numeric"} ->
          {"text-ltrn-dark bg-ltrn-lighter", nil, "•"}

        nil ->
          {"border border-dashed border-ltrn-light text-ltrn-light", nil, "-"}
      end

    socket
    |> assign(assigns)
    |> assign(:additional_classes, additional_classes)
    |> assign(:style, style)
    |> assign(:text, text)
  end
end
