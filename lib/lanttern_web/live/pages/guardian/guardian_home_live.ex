defmodule LantternWeb.GuardianHomeLive do
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
      |> assign_school()
      |> assign_cycles()
      |> stream_student_report_cards()

    {:ok, socket}
  end

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp assign_cycles(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle || %{}

    cycles =
      Schools.list_cycles(
        schools_ids: [socket.assigns.current_user.current_profile.school_id],
        parent_cycles_only: true
      )

    socket
    |> assign(:cycles, cycles)
    |> assign(:current_cycle, current_cycle)
  end

  defp stream_student_report_cards(socket) do
    all_student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.guardian_of_student_id,
        cycle_id: Map.get(socket.assigns.current_cycle, :id),
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
          |> push_navigate(to: ~p"/guardian")
          |> put_flash(:info, gettext("Current cycle changed"))

        _ ->
          # do something with error
          socket
      end

    {:noreply, socket}
  end
end
