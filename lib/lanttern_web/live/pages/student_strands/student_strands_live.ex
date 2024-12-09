defmodule LantternWeb.StudentStrandsLive do
  @moduledoc """
  Student home live view
  """

  alias Lanttern.Identity.Profile
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Personalization
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

    socket =
      socket
      |> assign_school()
      |> assign_parent_cycles()
      |> assign_student_report_cards_cycles()
      |> assign_user_filters([:cycles])
      # adjust dom id to prevent duplication
      # (some strands can be in more than one report card at the same time)
      |> stream_configure(
        :student_strands,
        dom_id: fn {strand, _entries} -> "student-strand-report-#{strand.strand_report_id}" end
      )
      |> adjust_cycles_filter()
      |> stream_student_strands()

    {:ok, socket}
  end

  defp check_if_user_has_access(%{type: profile_type} = %Profile{})
       when profile_type in ["student", "guardian"],
       do: nil

  defp check_if_user_has_access(_profile),
    do: raise(LantternWeb.NotFoundError)

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp assign_parent_cycles(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle || %{}

    parent_cycles =
      Schools.list_cycles(
        schools_ids: [socket.assigns.current_user.current_profile.school_id],
        parent_cycles_only: true
      )

    socket
    |> assign(:parent_cycles, parent_cycles)
    |> assign(:current_cycle, current_cycle)
  end

  defp assign_student_report_cards_cycles(socket) do
    student_id =
      case socket.assigns.current_user.current_profile do
        %{type: "student"} = profile -> profile.student_id
        %{type: "guardian"} = profile -> profile.guardian_of_student_id
      end

    student_report_cards_cycles =
      Reporting.list_student_report_cards_cycles(student_id,
        parent_cycle_id: Map.get(socket.assigns.current_cycle, :id)
      )

    socket
    |> assign(:student_report_cards_cycles, student_report_cards_cycles)
    |> assign(:student_report_cards_cycles_ids, Enum.map(student_report_cards_cycles, & &1.id))
    |> assign(:has_student_report_cards_cycles, length(student_report_cards_cycles) > 0)
  end

  # if there's no student report cards cycles, consider no cycle is selected
  # (if there's one selected, it belongs to a different parent cycle, so we ignore)
  defp adjust_cycles_filter(%{assigns: %{has_student_report_cards_cycles: false}} = socket),
    do: assign(socket, :selected_cycles_ids, [])

  # if there's no selected cycle, select the most recent from the list as the new selected cycle.
  defp adjust_cycles_filter(%{assigns: %{selected_cycles_ids: []}} = socket) do
    last_cycle = List.last(socket.assigns.student_report_cards_cycles)

    socket
    |> assign(:selected_cycles_ids, [last_cycle.id])
    |> save_profile_filters([:cycles])
  end

  # if there's a selected cycle, check if it belongs to user's current selected cycle.
  # if not, select the most recent from the list as the new selected cycle.
  defp adjust_cycles_filter(%{assigns: %{selected_cycles_ids: [selected_cycle_id]}} = socket) do
    if selected_cycle_id in socket.assigns.student_report_cards_cycles_ids do
      socket
    else
      last_cycle = List.last(socket.assigns.student_report_cards_cycles)

      socket
      |> assign(:selected_cycles_ids, [last_cycle.id])
      |> save_profile_filters([:cycles])
    end
  end

  # for all other cases, consider selected cycles ids is invalid
  # e.g. more than one cycle selected
  defp adjust_cycles_filter(socket), do: assign(socket, :selected_cycles_ids, [])

  # if no selected_cycles_ids at this point, return an empty list
  defp stream_student_strands(%{assigns: %{selected_cycles_ids: []}} = socket) do
    socket
    |> stream(:student_strands, [], reset: true)
    |> assign(:has_student_strands, false)
  end

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

  # event handlers

  @impl true
  def handle_event("change_cycle", %{"id" => cycle_id}, socket) do
    socket =
      Personalization.set_profile_settings(
        socket.assigns.current_user.current_profile.id,
        %{current_school_cycle_id: cycle_id}
      )
      |> case do
        {:ok, _profile_setting} ->
          socket
          |> push_navigate(to: ~p"/student_strands")
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          # do something with error
          socket
      end

    {:noreply, socket}
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
