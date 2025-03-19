defmodule LantternWeb.StudentReportCardsLive do
  @moduledoc """
  Guardian home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Personalization
  alias Lanttern.Reporting
  alias Lanttern.Schools

  # shared components
  import LantternWeb.ReportingComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_student()
      |> assign_school()
      |> assign_current_cycle()
      |> stream_student_report_cards()

    {:ok, socket}
  end

  defp assign_student(socket) do
    student_id =
      case socket.assigns.current_user.current_profile.type do
        "guardian" -> socket.assigns.current_user.current_profile.guardian_of_student_id
        "student" -> socket.assigns.current_user.current_profile.student_id
      end

    student = Schools.get_student!(student_id)

    assign(socket, :student, student)
  end

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp assign_current_cycle(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle
    assign(socket, :current_cycle, current_cycle)
  end

  defp stream_student_report_cards(socket) do
    all_student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.student.id,
        parent_cycle_id: Map.get(socket.assigns.current_cycle, :id),
        preloads: [report_card: [:year, :school_cycle]]
      )

    student_report_cards =
      all_student_report_cards
      |> Enum.filter(fn report_card ->
        case socket.assigns.current_user.current_profile.type do
          "guardian" -> report_card.allow_guardian_access
          "student" -> report_card.allow_student_access
        end
      end)

    has_student_report_cards = length(student_report_cards) > 0

    student_report_cards_wip =
      all_student_report_cards
      |> Enum.filter(fn report_card ->
        case socket.assigns.current_user.current_profile.type do
          "guardian" -> !report_card.allow_guardian_access
          "student" -> !report_card.allow_student_access
        end
      end)

    has_student_report_cards_wip = length(student_report_cards_wip) > 0

    socket
    |> stream(:student_report_cards, student_report_cards)
    |> assign(:has_student_report_cards, has_student_report_cards)
    |> stream(:student_report_cards_wip, student_report_cards_wip)
    |> assign(:has_student_report_cards_wip, has_student_report_cards_wip)
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
          |> push_navigate(to: ~p"/student_report_cards")
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          # do something with error
          socket
      end

    {:noreply, socket}
  end
end
