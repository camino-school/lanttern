defmodule LantternWeb.ReportCardLive.StudentsTrackingComponent do
  alias Lanttern.LearningContext
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  import LantternWeb.FiltersHelpers,
    only: [assign_report_card_linked_student_classes_filter: 2, save_profile_filters: 3]

  # shared
  alias LantternWeb.Filters.InlineFiltersComponent
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar>
        <.live_component
          module={InlineFiltersComponent}
          id="linked-students-grades-classes-filter"
          filter_items={@linked_students_classes}
          selected_items_ids={@selected_linked_students_classes_ids}
          notify_component={@myself}
        />
      </.action_bar>
      <%= if !@has_students do %>
        <div class="container mx-auto mt-4 lg:max-w-5xl">
          <div class="p-10 rounded-sm shadow-xl bg-white">
            <.empty_state>
              <%= gettext("Add students to report card to track entries") %>
            </.empty_state>
          </div>
        </div>
      <% else %>
        <.students_moments_entries_grid
          students_stream={@streams.students}
          strands={@strands}
          has_students={@has_students}
          students_entries_map={@students_entries_map}
        />
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, socket, temporary_assigns: [students_entries_map: %{}]}
  end

  @impl true
  def update(%{action: {InlineFiltersComponent, {:apply, classes_ids}}}, socket) do
    socket =
      socket
      |> assign(:selected_linked_students_classes_ids, classes_ids)
      |> save_profile_filters(
        [:linked_students_classes],
        report_card_id: socket.assigns.report_card.id
      )
      |> assign_students_entries_grid()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_report_card_linked_student_classes_filter(assigns.report_card)
      |> stream_report_card_strands()
      |> assign_students_entries_grid()

    {:ok, socket}
  end

  defp stream_report_card_strands(socket) do
    strands =
      socket.assigns.report_card.id
      |> LearningContext.list_report_card_strands()
      # remove strands without assessment points
      |> Enum.filter(&(&1.assessment_points_count > 0))

    socket
    |> assign(:strands, strands)
  end

  defp assign_students_entries_grid(socket) do
    students =
      Reporting.list_students_linked_to_report_card(
        socket.assigns.report_card,
        classes_ids: socket.assigns.selected_linked_students_classes_ids,
        active_students_only: true,
        students_only: true
      )

    students_ids =
      students
      |> Enum.map(& &1.id)

    students_entries_map =
      Reporting.build_students_moments_entries_map_for_report_card(
        socket.assigns.report_card.id,
        students_ids
      )

    socket
    |> stream(:students, students)
    |> assign(:has_students, students != [])
    |> assign(:students_entries_map, students_entries_map)
  end
end
