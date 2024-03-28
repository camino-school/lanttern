defmodule LantternWeb.StudentHomeLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Reporting

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def mount(_params, _session, socket) do
    student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.student_id,
        preloads: [report_card: :year]
      )

    has_student_report_cards = length(student_report_cards) > 0

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)

    {:ok, socket}
  end
end
