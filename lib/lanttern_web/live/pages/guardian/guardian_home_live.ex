defmodule LantternWeb.GuardianHomeLive do
  @moduledoc """
  Guardian home live view
  """

  use LantternWeb, :live_view

  alias Lanttern.Personalization
  alias Lanttern.Reporting
  alias Lanttern.Schools
  alias Lanttern.StudentsCycleInfo

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent
  import LantternWeb.ReportingComponents
  import LantternWeb.SchoolsComponents

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_student()
      |> assign_school()
      |> assign_cycles_and_classes()
      |> assign_current_cycle_and_classes()
      |> assign_student_cycle_info()
      |> stream_student_report_cards()

    {:ok, socket}
  end

  defp assign_student(socket) do
    student =
      socket.assigns.current_user.current_profile.guardian_of_student_id
      |> Schools.get_student!()

    assign(socket, :student, student)
  end

  defp assign_school(socket) do
    school =
      socket.assigns.current_user.current_profile.school_id
      |> Schools.get_school!()

    assign(socket, :school, school)
  end

  defp assign_cycles_and_classes(socket) do
    cycles_and_classes =
      StudentsCycleInfo.list_cycles_and_classes_for_student(socket.assigns.student)

    socket
    |> assign(:cycles_and_classes, cycles_and_classes)
  end

  defp assign_current_cycle_and_classes(socket) do
    current_cycle = socket.assigns.current_user.current_profile.current_school_cycle

    {_cycle, classes} =
      socket.assigns.cycles_and_classes
      |> Enum.find(fn {cycle, _classes} -> cycle.id == current_cycle.id end)

    socket
    |> assign(:current_cycle, current_cycle)
    |> assign(:current_classes, classes)
  end

  defp assign_student_cycle_info(socket) do
    student_cycle_info =
      StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(
        socket.assigns.student.id,
        socket.assigns.current_cycle.id,
        check_attachments_for: :family
      )
      |> case do
        nil ->
          # create student cycle info if it does not exist
          {:ok, info} =
            StudentsCycleInfo.create_student_cycle_info(
              %{
                school_id: socket.assigns.student.school_id,
                student_id: socket.assigns.student.id,
                cycle_id: socket.assigns.current_cycle.id
              },
              log_profile_id: socket.assigns.current_user.current_profile_id
            )

          info

        student_cycle_info ->
          student_cycle_info
      end

    assign(socket, :student_cycle_info, student_cycle_info)
  end

  defp stream_student_report_cards(socket) do
    all_student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.current_user.current_profile.guardian_of_student_id,
        parent_cycle_id: Map.get(socket.assigns.current_cycle, :id),
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
  def handle_event("change_cycle", %{"cycle_id" => cycle_id}, socket) do
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

  # helpers

  defp cycle_classes_opt([]), do: gettext("No classes")
  defp cycle_classes_opt(classes), do: Enum.map_join(classes, ", ", & &1.name)
end
