defmodule LantternWeb.Admin.AssessmentCompositionCheckLive do
  @moduledoc """
  Admin-only page to find composed assessment point entries whose stored value has
  drifted from their components, and re-sync them in bulk.

  Pick a strand, the page runs `AssessmentComposition.list_strand_composition_sync_status/2`
  (read-only) and lists the out-of-sync entries per edit domain. The **Sync** action
  recalculates every composed entry in the strand.
  """

  use LantternWeb, :live_view

  import Lanttern.Utils, only: [format_float: 1]
  import LantternWeb.GradingComponents, only: [ov_short: 1]

  alias Lanttern.AssessmentComposition
  alias LantternWeb.LearningContext.StrandSearchComponent

  # function components

  attr :scale_type, :string, required: true
  attr :value, :map, required: true

  defp value_cell(%{scale_type: "numeric"} = assigns) do
    ~H"""
    <span :if={is_number(@value.score)} class="tabular-nums">{format_score(@value.score)}</span>
    <span :if={is_nil(@value.score)} class="text-ltrn-subtle">—</span>
    """
  end

  defp value_cell(%{scale_type: "ordinal"} = assigns) do
    ~H"""
    <div :if={@value.ordinal_value} class="flex items-center justify-end gap-2">
      <.badge color_map={@value.ordinal_value}>{ov_short(@value.ordinal_value)}</.badge>
      <span class="tabular-nums text-ltrn-subtle">{format_normalized(@value.normalized_value)}</span>
    </div>
    <span :if={is_nil(@value.ordinal_value)} class="text-ltrn-subtle">—</span>
    """
  end

  defp domain_label(:teacher_entry), do: gettext("Teacher")
  defp domain_label(:student_entry), do: gettext("Student")

  defp ap_display_name(%{moment_id: nil} = ap),
    do: "(#{ap.curriculum_item.curriculum_component.name}) #{ap.curriculum_item.name}"

  defp ap_display_name(ap), do: ap.name

  defp student_name(%{name: name}), do: name
  defp student_name(_student), do: "—"

  # the recomputed sum can be an integer (e.g. summing `is_missing` zeros), while
  # `format_float/1` expects a float — coerce before formatting
  defp format_score(value) when is_number(value), do: format_float(value * 1.0)

  defp format_normalized(nil), do: "—"
  defp format_normalized(value), do: :erlang.float_to_binary(value * 1.0, decimals: 2)

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Assessment composition check"))
      |> assign(:selected_strand, nil)
      |> assign(:status, nil)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_info({StrandSearchComponent, {:strand_selected, nil}}, socket) do
    socket =
      socket
      |> assign(:selected_strand, nil)
      |> assign(:status, nil)

    {:noreply, socket}
  end

  def handle_info({StrandSearchComponent, {:strand_selected, strand_id}}, socket) do
    socket =
      socket
      |> assign(:selected_strand, strand_id)
      |> assign_status(strand_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("sync", _params, %{assigns: %{selected_strand: strand_id}} = socket)
      when is_integer(strand_id) do
    :ok =
      AssessmentComposition.sync_strand_composed_entries(socket.assigns.current_scope, strand_id)

    socket =
      socket
      |> put_flash(:info, gettext("Composed entries synced"))
      |> assign_status(strand_id)

    {:noreply, socket}
  end

  defp assign_status(socket, strand_id) do
    status =
      AssessmentComposition.list_strand_composition_sync_status(
        socket.assigns.current_scope,
        strand_id
      )

    assign(socket, :status, status)
  end
end
