defmodule LantternWeb.StudentHomeLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Schools

  # shared components
  import LantternWeb.ReportingComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.student_id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    has_student_report_cards = length(student_report_cards) > 0

    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)
      |> assign(:school, school)

    {:ok, socket}
  end
end
