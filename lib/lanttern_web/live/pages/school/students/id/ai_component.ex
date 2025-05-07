defmodule LantternWeb.StudentLive.AIComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentRecordReports

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-10 px-4">
        <.action type="button" phx-click={JS.push("generate", target: @myself)} theme="ai">
          Request AI report
        </.action>

        <%= if @has_student_record_reports do %>
          <div id="student-record-reports" phx-update="stream">
            <.ai_box
              :for={{dom_id, srr} <- @streams.student_record_reports}
              id={dom_id}
              class="p-6 mt-10"
            >
              <.markdown text={srr.description} />
              <.ai_generated_content_disclaimer class="mt-4" />
            </.ai_box>
          </div>
        <% else %>
          <div class="mt-10">no reports yet</div>
        <% end %>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

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
    |> stream_student_record_reports()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_student_record_reports(socket) do
    student_record_reports =
      StudentRecordReports.list_student_record_reports(student_id: socket.assigns.student.id)

    socket
    |> stream(:student_record_reports, student_record_reports)
    |> assign(:has_student_record_reports, length(student_record_reports) > 0)
  end

  # event handlers

  @impl true
  def handle_event("generate", _params, socket) do
    socket =
      StudentRecordReports.generate_student_record_report(socket.assigns.student.id)
      |> case do
        {:ok, student_record_report} ->
          socket
          |> stream_insert(:student_record_reports, student_record_report, at: 0)
          |> assign(:has_student_record_reports, true)

        _ ->
          socket
      end

    {:noreply, socket}
  end
end
