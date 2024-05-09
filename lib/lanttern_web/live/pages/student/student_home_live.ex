defmodule LantternWeb.StudentHomeLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Notes
  alias Lanttern.Reporting
  alias Lanttern.Schools

  # shared components
  import LantternWeb.LearningContextComponents
  alias LantternWeb.Notes.NoteComponent
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

    student_strands_notes =
      socket.assigns.current_user
      |> Notes.list_student_strands_notes()

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)
      |> stream(:student_report_cards_wip, student_report_cards_wip)
      |> assign(:has_student_report_cards_wip, has_student_report_cards_wip)
      |> assign(:school, school)
      |> stream_configure(
        :student_strands_notes,
        dom_id: fn {_, strand, cycle} ->
          "strand-#{strand.id}-cycle-#{cycle.id}"
        end
      )
      |> stream(:student_strands_notes, student_strands_notes)
      |> assign(:strand, nil)
      |> assign(:note, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_is_editing_note(params)

    {:noreply, socket}
  end

  defp assign_is_editing_note(socket, params) do
    is_editing_note =
      case params do
        %{"is_editing_note" => "true"} -> true
        _ -> false
      end

    socket
    |> assign(:is_editing_note, is_editing_note)
  end

  # event handlers

  @impl true
  def handle_event("edit_note", %{"strand_id" => strand_id}, socket) do
    strand = LearningContext.get_strand!(strand_id)

    note =
      Notes.get_student_note(
        socket.assigns.current_user.current_profile.student_id,
        strand_id: strand_id
      )

    socket =
      socket
      |> assign(:strand, strand)
      |> assign(:note, note)
      |> push_patch(to: ~p"/student?is_editing_note=true")

    {:noreply, socket}
  end
end
