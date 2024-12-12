defmodule LantternWeb.StudentLive.StudentReportCardsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <%= if @has_student_report_cards do %>
        <.responsive_grid is_full_width id="student-report-cards" phx-update="stream">
          <.report_card_card
            :for={{dom_id, student_report_card} <- @streams.student_report_cards}
            id={dom_id}
            report_card={student_report_card.report_card}
            open_in_new={~p"/student_report_card/#{student_report_card}"}
            year={student_report_card.report_card.year}
            cycle={student_report_card.report_card.school_cycle}
            class="shrink-0 w-64 sm:w-auto"
            is_wip={!student_report_card.allow_student_access}
          />
        </.responsive_grid>
      <% else %>
        <.empty_state><%= gettext("No report cards linked to student") %></.empty_state>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_student_report_cards()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_student_report_cards(socket) do
    student_report_cards =
      Reporting.list_student_report_cards(
        student_id: socket.assigns.student.id,
        preloads: [report_card: [:year, :school_cycle]]
      )

    socket
    |> stream(:student_report_cards, student_report_cards)
    |> assign(:has_student_report_cards, student_report_cards != [])
  end
end
