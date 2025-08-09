defmodule LantternWeb.Admin.StudentReportCardLive.Index do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StudentReportCard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :student_report_cards, Reporting.list_student_report_cards())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Student report card")
    |> assign(:student_report_card, Reporting.get_student_report_card!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Student report card")
    |> assign(:student_report_card, %StudentReportCard{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Student report cards")
    |> assign(:student_report_card, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Reporting.StudentReportCardFormComponent, {:saved, student_report_card}},
        socket
      ) do
    {:noreply, stream_insert(socket, :student_report_cards, student_report_card)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student_report_card = Reporting.get_student_report_card!(id)
    {:ok, _} = Reporting.delete_student_report_card(student_report_card)

    {:noreply, stream_delete(socket, :student_report_cards, student_report_card)}
  end
end
