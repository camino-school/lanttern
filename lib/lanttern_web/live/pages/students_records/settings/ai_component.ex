defmodule LantternWeb.StudentsRecordsSettingsLive.AIComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentRecordReports
  alias Lanttern.StudentRecordReports.StudentRecordReportAIConfig

  # import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.StudentRecordReports.StudentRecordReportAIConfigFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <p class="flex items-center gap-2">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext("Manage instructions for student record reports generation") %>
        </p>
        <.action
          :if={!@is_editing}
          type="link"
          patch={~p"/students_records/settings/ai?edit=true"}
          icon_name="hero-pencil-mini"
        >
          <%= gettext("Edit") %>
        </.action>
      </.action_bar>
      <.responsive_container id="student-record-report-ai-config" class="py-10 px-4">
        <.ai_box title={gettext("Student record report generation instructions")}>
          <%= if @is_editing do %>
            <.live_component
              module={StudentRecordReportAIConfigFormComponent}
              id="student-record-report-ai-config-form"
              config={@student_record_report_ai_config}
              notify_component={@myself}
            />
          <% else %>
            <div class="pb-6 border-b border-ltrn-ai-accent mb-6">
              <div class="flex items-center gap-4 mt-4">
                <div class="flex items-center gap-2">
                  <%= gettext("Current model:") %>
                  <%= if @student_record_report_ai_config.model do %>
                    <.badge theme="ai"><%= @student_record_report_ai_config.model %></.badge>
                  <% else %>
                    <.badge><%= gettext("No model selected") %></.badge>
                  <% end %>
                </div>
                <div class="flex items-center gap-2">
                  <%= gettext("AI request cooldown (in minutes):") %>
                  <.badge theme="ai">
                    <%= if @student_record_report_ai_config.cooldown_minutes == 0,
                      do: gettext("No cooldown"),
                      else: @student_record_report_ai_config.cooldown_minutes %>
                  </.badge>
                </div>
              </div>
            </div>
            <h6 class="mb-4 font-display font-black text-base text-ltrn-subtle">
              <%= gettext("Generate summary instructions") %>
            </h6>
            <%= if @student_record_report_ai_config.summary_instructions do %>
              <.markdown text={@student_record_report_ai_config.summary_instructions} />
            <% else %>
              <.empty_state_simple><%= gettext("No instructions set yet") %></.empty_state_simple>
            <% end %>
            <h6 class="mt-10 mb-4 font-display font-black text-base text-ltrn-subtle">
              <%= gettext("Generate update instructions") %>
            </h6>
            <%= if @student_record_report_ai_config.update_instructions do %>
              <.markdown text={@student_record_report_ai_config.update_instructions} />
            <% else %>
              <.empty_state_simple><%= gettext("No instructions set yet") %></.empty_state_simple>
            <% end %>
          <% end %>
        </.ai_box>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {StudentRecordReportAIConfigFormComponent, :cancel}}, socket) do
    nav_opts = [
      push_navigate: [to: ~p"/students_records/settings/ai"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(%{action: {StudentRecordReportAIConfigFormComponent, {action, _config}}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("AI config created successfully")
        :updated -> gettext("AI config updated successfully")
        :deleted -> gettext("AI config cleaned up successfully")
      end

    nav_opts = [
      put_flash: {:info, message},
      push_navigate: [to: ~p"/students_records/settings/ai"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_is_editing()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_student_record_report_ai_config()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_student_record_report_ai_config(socket) do
    student_record_report_ai_config =
      case StudentRecordReports.get_student_record_report_ai_config_by_school_id(
             socket.assigns.current_user.current_profile.school_id
           ) do
        %StudentRecordReportAIConfig{} = settings ->
          settings

        _ ->
          %StudentRecordReportAIConfig{
            school_id: socket.assigns.current_user.current_profile.school_id
          }
      end

    socket
    |> assign(:student_record_report_ai_config, student_record_report_ai_config)
  end

  defp assign_is_editing(%{assigns: %{params: %{"edit" => "true"}}} = socket),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket), do: assign(socket, :is_editing, false)
end
