defmodule LantternWeb.StudentRecordReports.StudentRecordReportAIActionBarComponent do
  @moduledoc """
  Renders an action bar for a student record report.

  ### Attrs

  - `:view_patch`*
  - `:student_id`*
  - `:class`
  - `:notify_parent` - boolean
  - `:notify_component` - `Phoenix.LiveComponent.CID`

  ### Notifications

  - {`:generate_success`, %StudentRecordReport{}}

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentRecordReports

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.ai_action_bar name={gettext("LantternAI report")}>
        <%= if @has_reports do %>
          <div class="flex items-center gap-2">
            <.action type="link" patch={@view_patch} theme="ai">
              <%= gettext("View") %>
            </.action>
            <.ai_content_indicator />
          </div>
        <% else %>
          <.action
            :if={!@generate_error}
            type="button"
            phx-click={JS.push("generate", target: @myself)}
            theme="ai-generate"
            icon_name="hero-sparkles-mini"
          >
            <%= gettext("Generate") %>
          </.action>
          <p :if={@generate_error} class="text-ltrn-subtle"><%= @generate_error %></p>
        <% end %>
      </.ai_action_bar>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:generate_error, nil)
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
    |> assign_has_reports()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_has_reports(socket) do
    has_reports =
      StudentRecordReports.student_has_record_reports?(socket.assigns.student_id)

    assign(socket, :has_reports, has_reports)
  end

  # event handlers

  @impl true
  def handle_event("generate", _params, socket) do
    socket =
      StudentRecordReports.generate_student_record_report(socket.assigns.student_id)
      |> case do
        {:ok, student_record_report} ->
          notify(__MODULE__, {:generate_success, student_record_report}, socket.assigns)
          socket

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
end
