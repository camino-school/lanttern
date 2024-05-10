defmodule LantternWeb.StudentHomeLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Notes
  alias Lanttern.Reporting
  alias Lanttern.Schools

  import LantternWeb.FiltersHelpers

  # shared components
  import LantternWeb.LearningContextComponents
  alias LantternWeb.Notes.NoteComponent
  alias LantternWeb.Filters.InlineFiltersComponent
  import LantternWeb.ReportingComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    all_student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.student_id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    student_report_cards =
      all_student_report_cards
      |> Enum.filter(& &1.allow_student_access)

    has_student_report_cards = length(student_report_cards) > 0

    student_report_cards_wip =
      all_student_report_cards
      |> Enum.filter(&(not &1.allow_student_access))

    has_student_report_cards_wip = length(student_report_cards_wip) > 0

    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    student_report_cards_cycles =
      Reporting.list_student_report_cards_cycles(
        socket.assigns.current_user.current_profile.student_id
      )

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)
      |> stream(:student_report_cards_wip, student_report_cards_wip)
      |> assign(:has_student_report_cards_wip, has_student_report_cards_wip)
      |> assign(:school, school)
      |> assign(:student_report_cards_cycles, student_report_cards_cycles)
      |> assign(:strand, nil)
      |> assign(:note, nil)
      |> assign_user_filters([:cycles], socket.assigns.current_user)
      |> stream_configure(
        :student_strands_notes,
        dom_id: fn {_, strand} ->
          "strand-note-#{strand.id}"
        end
      )
      |> stream_configure(
        :student_report_cards_for_strand,
        dom_id: fn {student_report_card, _} ->
          "student-report-card-#{student_report_card.id}"
        end
      )
      |> stream_student_strands_notes()

    {:ok, socket}
  end

  defp stream_student_strands_notes(socket) do
    student_strands_notes =
      socket.assigns.current_user
      |> Notes.list_student_strands_notes(cycles_ids: socket.assigns.selected_cycles_ids)

    has_student_strands_notes = student_strands_notes != []

    socket
    |> stream(:student_strands_notes, student_strands_notes, reset: true)
    |> assign(:has_student_strands_notes, has_student_strands_notes)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_is_editing_note(params)

    {:noreply, socket}
  end

  defp assign_is_editing_note(socket, params) do
    case {params, socket.assigns.strand} do
      {%{"is_editing_note" => "true"}, nil} ->
        socket
        |> push_patch(to: ~p"/student", replace: true)

      {%{"is_editing_note" => "true"}, _strand} ->
        socket
        |> assign(:is_editing_note, true)

      _ ->
        socket
        |> assign(:is_editing_note, false)
    end
  end

  # event handlers

  @impl true
  def handle_event("edit_note", %{"strand_id" => strand_id}, socket) do
    strand = LearningContext.get_strand!(strand_id)

    student_id =
      socket.assigns.current_user.current_profile.student_id

    note =
      Notes.get_student_note(
        student_id,
        strand_id: strand_id
      )

    student_report_cards_for_strand =
      Reporting.list_student_report_cards_linked_to_strand(
        student_id,
        strand_id
      )

    has_student_report_cards_for_strand =
      student_report_cards_for_strand != []

    socket =
      socket
      |> assign(:strand, strand)
      |> assign(:note, note)
      |> stream(:student_report_cards_for_strand, student_report_cards_for_strand, reset: true)
      |> assign(:has_student_report_cards_for_strand, has_student_report_cards_for_strand)
      |> push_patch(to: ~p"/student?is_editing_note=true")

    {:noreply, socket}
  end

  # info handlers

  @impl true
  def handle_info({InlineFiltersComponent, {:apply, cycles_ids}}, socket) do
    socket =
      socket
      |> assign(:selected_cycles_ids, cycles_ids)
      |> save_profile_filters(
        socket.assigns.current_user,
        [:cycles]
      )
      |> stream_student_strands_notes()

    {:noreply, socket}
  end
end
