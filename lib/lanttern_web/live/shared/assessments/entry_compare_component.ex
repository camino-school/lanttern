defmodule LantternWeb.Assessments.EntryCompareComponent do
  @moduledoc """
  Displays teacher assessment and student self-assessment
  side by side.

  Expected external assigns:

      attr :entry, Lanttern.Assessments.AssessmentPointEntry, required: true
      attr :scale, Lanttern.Grading.Scale, required: true

  """
  use LantternWeb, :live_component

  alias Lanttern.Grading.OrdinalValue

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["grid grid-cols-2 gap-1", @class]}>
      <.entry_view entry_value={@teacher_value} entry_style={@teacher_style} scale_type={@scale.type} />
      <.entry_view entry_value={@student_value} entry_style={@student_style} scale_type={@scale.type} />
    </div>
    """
  end

  attr :scale_type, :string, required: true
  attr :entry_style, :string, default: nil
  attr :entry_value, :any, default: nil

  def entry_view(%{entry_value: nil} = assigns) do
    ~H"""
    <div class="flex items-center justify-center p-2 rounded-xs font-mono text-sm text-ltrn-subtle bg-ltrn-lighter">
      —
    </div>
    """
  end

  def entry_view(%{scale_type: "ordinal"} = assigns) do
    ~H"""
    <div
      class="flex items-center justify-center p-2 rounded-xs font-mono text-sm bg-white"
      style={@entry_style}
    >
      <span class="truncate">
        <%= @entry_value %>
      </span>
    </div>
    """
  end

  def entry_view(%{scale_type: "numeric"} = assigns) do
    ~H"""
    <div
      class="flex items-center justify-center p-2 border border-ltrn-light rounded-xs font-mono text-sm bg-white"
      style={@entry_style}
    >
      <%= @entry_value %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:viewing_note, nil)
      |> assign(:teacher_style, nil)
      |> assign(:teacher_value, nil)
      |> assign(:student_style, nil)
      |> assign(:student_value, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_styles_and_values()

    {:ok, socket}
  end

  # helpers

  defp assign_styles_and_values(%{assigns: %{entry: %{scale_type: "ordinal"}}} = socket) do
    %{
      entry: %{
        ordinal_value_id: ordinal_value_id,
        student_ordinal_value_id: student_ordinal_value_id
      },
      scale: %{ordinal_values: ordinal_values}
    } = socket.assigns

    {teacher_style, teacher_value} =
      ordinal_values
      |> Enum.find(&(&1.id == ordinal_value_id))
      |> case do
        nil -> {nil, nil}
        ov -> {get_colors_style(ov), ov.name}
      end

    {student_style, student_value} =
      ordinal_values
      |> Enum.find(&(&1.id == student_ordinal_value_id))
      |> case do
        nil -> {nil, nil}
        ov -> {get_colors_style(ov), ov.name}
      end

    socket
    |> assign(:teacher_style, teacher_style)
    |> assign(:teacher_value, teacher_value)
    |> assign(:student_style, student_style)
    |> assign(:student_value, student_value)
  end

  defp assign_styles_and_values(%{assigns: %{entry: %{scale_type: "numeric"}}} = socket) do
    entry = socket.assigns.entry

    socket
    |> assign(:teacher_value, entry.score)
    |> assign(:student_value, entry.student_score)
  end

  defp assign_styles_and_values(socket), do: socket

  defp get_colors_style(%OrdinalValue{} = ordinal_value) do
    "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  end

  defp get_colors_style(_), do: ""
end
