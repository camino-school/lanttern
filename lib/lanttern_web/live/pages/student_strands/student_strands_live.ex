defmodule LantternWeb.StudentStrandsLive do
  @moduledoc """
  Student home live view
  """

  alias Lanttern.Identity.Profile
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Reporting
  alias Lanttern.Schools

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.Assessments.EntryParticleComponent
  alias LantternWeb.Filters.InlineFiltersComponent
  import LantternWeb.LearningContextComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    # check if user is guardian or student
    check_if_user_has_access(socket.assigns.current_user.current_profile)

    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_report_cards_cycles =
      Reporting.list_student_report_cards_cycles(student_id)

    socket =
      socket
      |> assign(:school, school)
      |> assign(:student_report_cards_cycles, student_report_cards_cycles)
      |> assign_user_filters([:cycles])
      |> adjust_cycles_filter()
      # adjust dom id to prevent duplication
      # (some strands can be in more than one report card at the same time)
      |> stream_configure(
        :student_strands,
        dom_id: fn {strand, _entries} -> "student-strand-report-#{strand.strand_report_id}" end
      )
      |> stream_student_strands()

    {:ok, socket}
  end

  defp check_if_user_has_access(%{type: profile_type} = %Profile{})
       when profile_type in ["student", "guardian"],
       do: nil

  defp check_if_user_has_access(_profile),
    do: raise(LantternWeb.NotFoundError)

  # if no cycle is selected, select the most recent (the last one)
  defp adjust_cycles_filter(%{assigns: %{selected_cycles_ids: []}} = socket) do
    case socket.assigns.student_report_cards_cycles do
      [] ->
        socket

      cycles ->
        last_cycle = List.last(cycles)

        socket
        |> assign(:selected_cycles_ids, [last_cycle.id])
        |> save_profile_filters([:cycles])
    end
  end

  defp adjust_cycles_filter(socket), do: socket

  defp stream_student_strands(socket) do
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_strands =
      LearningContext.list_student_strands(
        student_id,
        cycles_ids: socket.assigns.selected_cycles_ids
      )

    has_student_strands = student_strands != []

    socket
    |> stream(:student_strands, student_strands, reset: true)
    |> assign(:has_student_strands, has_student_strands)
  end

  # info handlers

  @impl true
  def handle_info({InlineFiltersComponent, {:apply, cycles_ids}}, socket) do
    socket =
      socket
      |> assign(:selected_cycles_ids, cycles_ids)
      |> save_profile_filters([:cycles])
      |> stream_student_strands()

    {:noreply, socket}
  end
end
