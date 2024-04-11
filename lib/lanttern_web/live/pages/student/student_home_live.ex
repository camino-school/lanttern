defmodule LantternWeb.StudentHomeLive do
  @moduledoc """
  Student home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Schools
  import LantternWeb.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # shared components
  import LantternWeb.ReportingComponents

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

    logo_image_url =
      case school.logo_image_url do
        nil ->
          nil

        url ->
          object_url_to_render_url(
            url,
            width: 128,
            height: 128
          )
      end

    socket =
      socket
      |> stream(:student_report_cards, student_report_cards)
      |> assign(:has_student_report_cards, has_student_report_cards)
      |> assign(:school, school)
      |> assign(:logo_image_url, logo_image_url)

    {:ok, socket}
  end
end
