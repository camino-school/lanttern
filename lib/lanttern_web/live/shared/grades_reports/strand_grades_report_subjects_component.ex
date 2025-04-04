defmodule LantternWeb.GradesReports.StrandGradesReportSubjectsComponent do
  @moduledoc """
  This component renders a list of grades report subjects linked to the strand in a cycle.

  As multiple instances of this components are rendered at the same time,
  the component uses `update_many/1` to prevent multiple requests.

  #### Expected external assigns

  - `strand_id`
  - `cycle_id`
  - `grades_report_id`

  #### Optional assigns

  - `class` - any, default: `nil`

  """
  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  # alias Lanttern.Grading.OrdinalValue

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <%= if @has_grades_reports_subjects do %>
        <p><%= gettext("Used in grading for") %></p>
        <div id={"subjects-list-#{@id}"} class="flex flex-wrap gap-2 mt-2" phx-update="stream">
          <.badge
            :for={{dom_id, grs} <- @streams.grades_reports_subjects}
            id={"#{@id}-#{dom_id}"}
            theme="dark"
          >
            <%= grs.subject.name %>
          </.badge>
        </div>
      <% else %>
        <p class="text-ltrn-subtle"><%= gettext("Not used for grading") %></p>
      <% end %>
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
    strands_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.strand_id
      end)

    # let it crash: will fail if more than one cycle_id is passed
    [cycle_id] =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.cycle_id
      end)
      |> Enum.uniq()

    # let it crash: will fail if more than one grades_report_id is passed
    [grades_report_id] =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.grades_report_id
      end)
      |> Enum.uniq()

    strands_ids_grs_list_map =
      GradesReports.list_strands_linked_grades_report_subjects(
        strands_ids,
        cycle_id,
        grades_report_id
      )
      |> Enum.into(%{})

    assigns_sockets
    |> Enum.map(&update_single(&1, strands_ids_grs_list_map))
  end

  defp update_single({assigns, socket}, strands_ids_grs_list_map) do
    grades_reports_subjects = Map.get(strands_ids_grs_list_map, assigns.strand_id)
    has_grades_reports_subjects = length(grades_reports_subjects) > 0

    socket
    |> assign(assigns)
    |> stream(:grades_reports_subjects, grades_reports_subjects)
    |> assign(:has_grades_reports_subjects, has_grades_reports_subjects)
  end
end
