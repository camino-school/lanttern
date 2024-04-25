defmodule LantternWeb.GuardianHomeLive do
  @moduledoc """
  Guardian home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Schools

  # shared components
  import LantternWeb.ReportingComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    all_student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.guardian_of_student_id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    student_report_cards =
      all_student_report_cards
      |> Enum.filter(& &1.allow_guardian_access)

    has_student_report_cards = length(student_report_cards) > 0

    student_report_cards_wip =
      all_student_report_cards
      |> Enum.filter(&(not &1.allow_guardian_access))

    has_student_report_cards_wip = length(student_report_cards_wip) > 0

    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)
      |> stream(:student_report_cards_wip, student_report_cards_wip)
      |> assign(:has_student_report_cards_wip, has_student_report_cards_wip)
      |> assign(:school, school)

    {:ok, socket}
  end
end
