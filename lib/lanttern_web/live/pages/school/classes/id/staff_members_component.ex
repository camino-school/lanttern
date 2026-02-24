defmodule LantternWeb.ClassLive.StaffMembersComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools

  # shared components
  import LantternWeb.SchoolsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="p-4">
        {ngettext("1 staff member", "%{count} staff members", @staff_members_length)}
      </div>
      <%= if @staff_members_length == 0 do %>
        <.empty_state class="px-4 py-10">
          {gettext("No staff members linked to this class")}
        </.empty_state>
      <% else %>
        <.fluid_grid id="staff-members" phx-update="stream" is_full_width class="p-4">
          <.staff_member_simple_card
            :for={{dom_id, staff} <- @streams.staff_members}
            id={dom_id}
            staff_member={staff}
            navigate={~p"/school/staff/#{staff}"}
            class_role={staff.class_role}
          />
        </.fluid_grid>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
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
    |> stream_class_staff_members()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_class_staff_members(socket) do
    staff_members =
      Schools.list_class_staff_members(
        socket.assigns.current_user.current_profile,
        socket.assigns.class.id,
        load_email: true
      )

    socket
    |> stream(:staff_members, staff_members, reset: true)
    |> assign(:staff_members_length, length(staff_members))
  end
end
