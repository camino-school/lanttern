defmodule LantternWeb.GradesReports.StudentGradesReportEntryButtonComponent do
  @moduledoc """
  This component renders buttons based on students grades report entries,
  handling the ordinal value representation.

  As multiple instances of this components are rendered at the same time,
  the component handles the ordinal values "preload" through `update_many/1`.

  #### Expected external assigns

      attr :student_grades_report_entry, StudentGradesReportEntry

  #### Optional assigns

      attr :class, :any, default: nil
      attr :on_click, :any, default: nil
      attr :is_pre_retake, :boolean, default: false

  """
  use LantternWeb, :live_component

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue

  @impl true
  def render(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center rounded-sm",
        @additional_classes,
        @class
      ]}
      style={@style}
      phx-click={@on_click}
    >
      <%= @text %>
    </button>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:on_click, nil)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    ordinal_values_ids =
      assigns_sockets
      |> Enum.flat_map(fn {assigns, _socket} ->
        ov_id =
          assigns.student_grades_report_entry &&
            assigns.student_grades_report_entry.ordinal_value_id

        pre_retake_ov_id =
          assigns.student_grades_report_entry &&
            assigns.student_grades_report_entry.pre_retake_ordinal_value_id

        [ov_id, pre_retake_ov_id]
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
    is_pre_retake = Map.get(assigns, :is_pre_retake, false)

    ordinal_value_or_score =
      case {assigns.student_grades_report_entry, is_pre_retake} do
        {%{pre_retake_ordinal_value_id: ov_id}, true} when not is_nil(ov_id) ->
          Map.get(ovs_map, ov_id)

        {%{pre_retake_score: score}, true} when not is_nil(score) ->
          score

        {%{ordinal_value_id: ov_id}, false} when not is_nil(ov_id) ->
          Map.get(ovs_map, ov_id)

        {%{score: score}, false} when not is_nil(score) ->
          score

        _ ->
          nil
      end

    {additional_classes, style, text} =
      get_entry_styles_and_text(ordinal_value_or_score)

    socket
    |> assign(assigns)
    |> assign(:additional_classes, additional_classes)
    |> assign(:style, style)
    |> assign(:text, text)
  end

  defp get_entry_styles_and_text(%OrdinalValue{} = ordinal_value) do
    style =
      "color: #{ordinal_value.text_color}; background-color: #{ordinal_value.bg_color}"

    {nil, style, ordinal_value.name}
  end

  defp get_entry_styles_and_text(score) when is_float(score),
    do: {"text-ltrn-dark bg-ltrn-lighter", nil, score}

  defp get_entry_styles_and_text(_),
    do: {"border border-dashed border-ltrn-light text-ltrn-light", nil, "-"}
end
