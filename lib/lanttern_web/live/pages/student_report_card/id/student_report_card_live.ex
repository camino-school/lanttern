defmodule LantternWeb.StudentReportCardLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  # alias Lanttern.Reporting.StrandReport

  # live components
  # alias LantternWeb.Reporting.ReportCardFormComponent
  # alias LantternWeb.Reporting.StrandReportFormComponent

  # shared components
  import LantternWeb.LearningContextComponents

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  # # prevent user from navigating directly to nested views

  # defp maybe_redirect(%{assigns: %{live_action: live_action}} = socket, params)
  #      when live_action in [:edit, :edit_strand_report],
  #      do: redirect(socket, to: ~p"/reporting/#{params["id"]}")

  # defp maybe_redirect(socket, _params), do: socket

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    student_report_card =
      Reporting.get_student_report_card!(id,
        preloads: [
          :student,
          report_card: [:school_cycle, strand_reports: [strand: [:subjects, :years]]]
        ]
      )

    socket =
      socket
      |> assign(:student_report_card, student_report_card)

    {:noreply, socket}
  end
end
