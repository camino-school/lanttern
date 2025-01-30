defmodule LantternWeb.StudentsRecordsSettingsLive.StatusComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecordStatus

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.StudentsRecords.StudentRecordStatusFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <p class="flex items-center gap-2">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext("Manage students records statuses below") %>
        </p>
        <.action
          type="link"
          patch={~p"/students_records/settings/status?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New status") %>
        </.action>
      </.action_bar>
      <%= if @statuses_length == 0 do %>
        <div class="p-10">
          <.empty_state><%= gettext("No student record status created yet") %></.empty_state>
        </div>
      <% else %>
        <.responsive_container id="student-record-statuses" class="p-4">
          <.sortable_card
            :for={{status, i} <- @statuses_with_index}
            id={"student-record-status-#{status.id}"}
            is_move_up_disabled={i == 0}
            on_move_up={
              JS.push("swap_statuses_position", value: %{"from" => i, "to" => i - 1}, target: @myself)
            }
            is_move_down_disabled={i + 1 == @statuses_length}
            on_move_down={
              JS.push("swap_statuses_position", value: %{"from" => i, "to" => i + 1}, target: @myself)
            }
            class="mt-4 first:mt-0"
            bg_class={if(status.is_closed, do: "bg-ltrn-mesh-cyan")}
          >
            <div class="flex items-center gap-4 p-6">
              <.badge
                color_map={status}
                icon_name={if(status.is_closed, do: "hero-check-circle-mini")}
              >
                <%= status.name %>
              </.badge>
              <.action
                type="link"
                patch={~p"/students_records/settings/status?edit=#{status.id}"}
                theme="subtle"
              >
                <%= gettext("Edit") %>
              </.action>
            </div>
          </.sortable_card>
        </.responsive_container>
      <% end %>
      <.live_component
        :if={@status}
        module={StudentRecordStatusFormOverlayComponent}
        id="student-record-status-form-overlay"
        status={@status}
        title={@status_overlay_title}
        on_cancel={JS.patch(~p"/students_records/settings/status")}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {StudentRecordStatusFormOverlayComponent, {action, _status}}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("Status created successfully")
        :updated -> gettext("Status updated successfully")
        :deleted -> gettext("Status deleted successfully")
      end

    nav_opts = [
      put_flash: {:info, message},
      push_navigate: [to: ~p"/students_records/settings/status"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_status()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_statuses_with_index()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_statuses_with_index(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    statuses = StudentsRecords.list_student_record_statuses(school_id: school_id)

    socket
    |> assign(:statuses_with_index, Enum.with_index(statuses))
    |> assign(:statuses_length, length(statuses))
    |> assign(:statuses_ids, Enum.map(statuses, &"#{&1.id}"))
  end

  defp assign_status(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    status = %StudentRecordStatus{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:status, status)
    |> assign(:status_overlay_title, gettext("New status"))
  end

  defp assign_status(%{assigns: %{params: %{"edit" => status_id}}} = socket) do
    if status_id in socket.assigns.statuses_ids do
      status = StudentsRecords.get_student_record_status!(status_id)

      socket
      |> assign(:status, status)
      |> assign(:status_overlay_title, gettext("Edit status"))
    else
      assign(socket, :status, nil)
    end
  end

  defp assign_status(socket), do: assign(socket, :status, nil)

  # event handlers

  @impl true
  def handle_event("swap_statuses_position", %{"from" => i, "to" => j}, socket) do
    sorted_statuses =
      socket.assigns.statuses_with_index
      |> Enum.map(fn {s, _i} -> s end)
      |> swap(i, j)

    sorted_statuses_ids = Enum.map(sorted_statuses, & &1.id)

    case StudentsRecords.update_student_record_statuses_positions(sorted_statuses_ids) do
      :ok ->
        {:noreply, assign(socket, :statuses_with_index, Enum.with_index(sorted_statuses))}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
