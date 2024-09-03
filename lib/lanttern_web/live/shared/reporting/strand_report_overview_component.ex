defmodule LantternWeb.Reporting.StrandReportOverviewComponent do
  @moduledoc """
  Renders the overview content of a `StrandReport`.

  ### Required attrs

  - `strand_report` - `%StrandReport{}`
  - `student_id`

  """

  use LantternWeb, :live_component

  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  # shared components
  import LantternWeb.RubricsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <.markdown :if={@description} text={@description} />
        <div :if={@has_rubric} class={if @description, do: "mt-10"}>
          <h3 class="font-display font-black text-xl"><%= gettext("Strand rubrics") %></h3>
          <.rubric_card :for={{dom_id, rubric} <- @streams.rubrics} id={dom_id} rubric={rubric} />
          <.rubric_card :for={{dom_id, rubric} <- @streams.diff_rubrics} id={dom_id} rubric={rubric} />
        </div>
        <.empty_state :if={!@description && !@has_rubric}>
          <%= gettext("No strand report info yet.") %>
        </.empty_state>
      </.responsive_container>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rubric, Rubric, required: true

  def rubric_card(assigns) do
    {is_diff, diff_type} =
      case assigns.rubric do
        %{is_differentiation: true} -> {true, :curriculum}
        %{diff_for_rubric_id: parent_rubric} when not is_nil(parent_rubric) -> {true, :rubric}
        _ -> {false, nil}
      end

    assigns =
      assigns
      |> assign(:is_diff, is_diff)
      |> assign(:diff_type, diff_type)

    ~H"""
    <.card_base id={@id} class={["mt-6", if(@is_diff, do: "border border-ltrn-diff-accent")]}>
      <div class="pt-4 px-4 text-sm">
        <p :if={@is_diff} class="mb-2 text-ltrn-diff-dark font-bold">
          <%= if @diff_type == :curriculum,
            do: gettext("Curriculum differentiation"),
            else: gettext("Rubric differentiation") %>
        </p>
        <p>
          <span class="font-bold"><%= @rubric.curriculum_item.curriculum_component.name %></span>
          <%= @rubric.curriculum_item.name %>
        </p>
        <p class="mt-2">
          <span class="font-bold"><%= gettext("Criteria:") %></span>
          <%= @rubric.criteria %>
        </p>
      </div>
      <div class="overflow-x-auto">
        <%!-- extra div with min-w-min prevent clamped right padding issue --%>
        <%!-- https://stackoverflow.com/a/26892899 --%>
        <div class="p-4 min-w-min">
          <.rubric_descriptors rubric={@rubric} />
        </div>
      </div>
    </.card_base>
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
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_description()
      |> stream_strand_rubrics()
      |> stream_diff_rubrics()

    {:ok, socket}
  end

  defp assign_description(socket) do
    # we try to use the strand report description
    # and we fall back to the strand description

    description =
      case socket.assigns.strand_report do
        %{description: strand_report_desc} when is_binary(strand_report_desc) ->
          strand_report_desc

        %{strand: %{description: strand_desc}} when is_binary(strand_desc) ->
          strand_desc

        _ ->
          nil
      end

    assign(socket, :description, description)
  end

  defp stream_strand_rubrics(socket) do
    rubrics =
      Rubrics.list_strand_rubrics(socket.assigns.strand_report.strand_id)

    socket
    |> stream(:rubrics, rubrics)
    |> assign(:has_rubric, rubrics != [])
  end

  defp stream_diff_rubrics(socket) do
    diff_rubrics =
      Rubrics.list_strand_diff_rubrics_for_student_id(
        socket.assigns.student_id,
        socket.assigns.strand_report.strand_id
      )

    socket
    |> stream(:diff_rubrics, diff_rubrics)
    |> assign(:has_diff_rubric, diff_rubrics != [])
  end
end
