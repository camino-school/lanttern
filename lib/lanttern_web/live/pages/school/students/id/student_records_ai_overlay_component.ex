defmodule LantternWeb.StudentLive.StudentRecordsAIOverlayComponent do
  @moduledoc """
  Renders an overlay with student record reports.

  If there's no student record report, nothing is rendered.
  """

  use LantternWeb, :live_component

  alias Lanttern.StudentRecordReports
  alias Lanttern.StudentRecordReports.StudentRecordReport
  alias Lanttern.StudentRecordReports.StudentRecordReportAIConfig

  import LantternWeb.DateTimeHelpers, only: [format_by_locale: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.ai_panel_overlay
        :if={@last_report}
        id={"#{@id}-ai-panel"}
        show
        on_cancel={@on_cancel}
        panel_title={gettext("Student records report")}
        class="p-4"
      >
        <%= if @student_record_report_ai_config && @student_record_report_ai_config.about do %>
          <.markdown text={@student_record_report_ai_config.about} class="mt-6" />
        <% end %>
        <div id="student-record-reports" phx-update="stream">
          <div
            :for={{dom_id, srr} <- @streams.student_record_reports}
            id={dom_id}
            class="pt-6 border-t border-ltrn-ai-light mt-10"
          >
            <div class="flex items-center gap-4 mb-6">
              <p class="flex-1 text-ltrn-ai-dark"><%= report_info(srr, @tz) %></p>
              <div class="group relative shrink-0">
                <.action_icon
                  type="button"
                  name="hero-trash-mini"
                  size="mini"
                  theme="subtle"
                  sr_text={gettext("Delete student record report")}
                  phx-click={JS.push("delete", value: %{"id" => srr.id}, target: @myself)}
                  data-confirm={gettext("Are you sure?")}
                />
                <.tooltip h_pos="right" v_pos="bottom">
                  <%= gettext("Delete report") %>
                </.tooltip>
              </div>
            </div>
            <.markdown text={srr.description} />
          </div>
        </div>
        <.ai_generated_content_disclaimer class="mt-6" />
        <div class="pt-10 pb-6 border-t border-ltrn-ai-light mt-6">
          <.action
            :if={!@generate_error && !@is_on_ai_cooldown}
            type="button"
            phx-click={JS.push("generate", target: @myself)}
            theme="ai-generate"
            icon_name="hero-sparkles-mini"
            class="peer"
          >
            <%= gettext("Generate updated report") %>
          </.action>
          <p class="mt-4 hidden peer-phx-click-loading:block">
            <%= gettext("Generating report...") %>
          </p>
          <p :if={@generate_error} class="text-ltrn-subtle">
            <%= @generate_error %>
          </p>
          <div :if={@is_on_ai_cooldown}>
            <p class="flex items-center gap-2 text-ltrn-ai-dark">
              <.icon name="hero-clock-micro" class="w-4 h-4" />
              <%= gettext("Reports can be generated every %{minute} minutes",
                minute: @ai_cooldown_minutes
              ) %>
              <%= ngettext(
                "(1 minute left until next report request)",
                "(%{count} minutes left until next report request)",
                @ai_cooldown_minutes_left
              ) %>
            </p>
          </div>
        </div>
      </.ai_panel_overlay>
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
      |> assign(:generate_error, nil)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_student_record_report_ai_config()
    |> stream_student_record_reports()
    |> assign_is_on_ai_cooldown()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_student_record_report_ai_config(socket) do
    case StudentRecordReports.get_student_record_report_ai_config_by_school_id(
           socket.assigns.current_profile.school_id
         ) do
      %StudentRecordReportAIConfig{} = config ->
        socket
        |> assign(:student_record_report_ai_config, config)

      _ ->
        socket
        |> assign(:student_record_report_ai_config, nil)
        |> assign(
          :generate_error,
          gettext("Student record report AI generator is not configured for your school yet.")
        )
    end
  end

  defp stream_student_record_reports(socket) do
    student_record_reports =
      StudentRecordReports.list_student_record_reports(student_id: socket.assigns.student.id)

    last_report =
      if student_record_reports != [] do
        student_record_reports
        |> Enum.at(-1)
      end

    socket
    |> stream(:student_record_reports, student_record_reports, reset: true)
    |> assign(:last_report, last_report)
  end

  defp assign_is_on_ai_cooldown(
         %{
           assigns: %{
             last_report: %StudentRecordReport{} = last_srr,
             student_record_report_ai_config: %StudentRecordReportAIConfig{} = config
           }
         } = socket
       ) do
    ai_cooldown_minutes =
      config.cooldown_minutes || 0

    cooldown_end_datetime =
      last_srr.inserted_at
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.shift(minute: ai_cooldown_minutes)

    is_on_ai_cooldown =
      DateTime.before?(DateTime.utc_now(), cooldown_end_datetime)

    ai_cooldown_minutes_left =
      Timex.diff(
        cooldown_end_datetime,
        DateTime.utc_now(),
        :minutes
      )

    socket
    |> assign(:is_on_ai_cooldown, is_on_ai_cooldown)
    |> assign(:ai_cooldown_minutes, ai_cooldown_minutes)
    |> assign(:ai_cooldown_minutes_left, ai_cooldown_minutes_left)
  end

  defp assign_is_on_ai_cooldown(socket),
    do: assign(socket, :is_on_ai_cooldown, false)

  # event handlers

  @impl true
  def handle_event("generate", _params, socket) do
    opts =
      case socket.assigns.last_report do
        %StudentRecordReport{} = srr -> [last_report: srr]
        _ -> []
      end

    socket =
      StudentRecordReports.generate_student_record_report(socket.assigns.student.id, opts)
      |> case do
        {:ok, student_record_report} ->
          socket
          |> stream_insert(:student_record_reports, student_record_report, at: 0)
          |> assign(:has_student_record_reports, true)
          |> assign(:last_report, student_record_report)

        {:error, :no_config} ->
          assign(
            socket,
            :generate_error,
            gettext("Student record report AI generator is not configured for your school yet.")
          )

        {:error, :no_records} ->
          assign(
            socket,
            :generate_error,
            gettext("There's no student records to generate the report.")
          )

        _ ->
          assign(
            socket,
            :generate_error,
            gettext("Something went wrong.")
          )
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    StudentRecordReports.get_student_record_report!(id)
    |> StudentRecordReports.delete_student_record_report()
    |> case do
      {:ok, _srr} ->
        socket =
          socket
          |> stream_student_record_reports()

        {:noreply, socket}

      _ ->
        # do something with error?
        {:noreply, socket}
    end
  end

  # helpers

  defp report_info(%StudentRecordReport{} = report, tz) do
    generated_at = format_by_locale(report.inserted_at, tz)

    from =
      report.from_datetime &&
        format_by_locale(report.from_datetime, tz)

    if from do
      gettext("Report generated with records data from %{from} to %{generated_at}",
        generated_at: generated_at,
        from: from
      )
    else
      gettext("Report generated with records data up to %{generated_at}",
        generated_at: generated_at
      )
    end
  end
end
