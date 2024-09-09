defmodule LantternWeb.Assessments.EntryParticleComponent do
  @moduledoc """
  This component renders assessment point particles, small visual representations
  of assessments for dataviz.

  As multiple instances of this components are rendered at the same time,
  the component also handles the ordinal values "preload" through `update_many/1`.

  #### Expected external assigns

      attr :entry, AssessmentPointEntry

  #### Optional assigns

      attr :is_student, :boolean, default: false
      attr :size, :string, default: "md", doc: "sm | md"
      attr :class, :any, default: nil

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class={[
        "flex items-center justify-center rounded-sm",
        if(@size == "sm", do: "w-4 h-4 max-w-4 text-xs", else: "w-6 h-6 max-w-6 text-sm"),
        @additional_classes,
        @class
      ]}
      style={@style}
      title={@full_text}
    >
      <%= @particle_text %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:size, "md")
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
    is_student = Map.get(assigns, :is_student)

    ordinal_value_or_score =
      case assigns.entry do
        %{scale_type: "ordinal"} = entry ->
          ov_id = if is_student, do: entry.student_ordinal_value_id, else: entry.ordinal_value_id
          Map.get(ovs_map, ov_id)

        %{scale_type: "numeric"} = entry ->
          if is_student, do: entry.student_score, else: entry.score

        _ ->
          nil
      end

    {additional_classes, style, particle_text, full_text} =
      case ordinal_value_or_score do
        %OrdinalValue{} = ordinal_value ->
          style =
            "color: #{ordinal_value.text_color}; background-color: #{ordinal_value.bg_color}"

          {nil, style, String.first(ordinal_value.name), ordinal_value.name}

        score when is_float(score) ->
          {"text-ltrn-dark bg-ltrn-lighter", nil, "•", score}

        _ ->
          full_text =
            case {assigns.entry, is_student} do
              {%AssessmentPointEntry{}, true} -> gettext("No student self-assessment")
              {%AssessmentPointEntry{}, _} -> gettext("No teacher assessment")
              _ -> gettext("No entry")
            end

          {"border border-dashed border-ltrn-light text-ltrn-light", nil, "-", full_text}
      end

    socket
    |> assign(assigns)
    |> assign(:additional_classes, additional_classes)
    |> assign(:style, style)
    |> assign(:particle_text, particle_text)
    |> assign(:full_text, full_text)
  end
end
