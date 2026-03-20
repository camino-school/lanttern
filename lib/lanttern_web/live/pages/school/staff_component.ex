defmodule LantternWeb.SchoolLive.StaffComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.StaffMember

  # shared components
  alias LantternWeb.Schools.StaffMemberFormOverlayComponent
  import LantternWeb.SchoolsComponents, only: [staff_member_card: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between gap-6 p-4">
        <div class="flex gap-4">
          {ngettext("1 active staff member", "%{count} active staff members", @staff_length)}
          <.action type="link" theme="subtle" navigate={~p"/school/staff/deactivated"}>
            {gettext("View deactivated staff members")}
          </.action>
        </div>
        <.action
          :if={@is_school_manager}
          type="link"
          patch={~p"/school/staff?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          {gettext("Add staff member")}
        </.action>
      </div>
      <%= if @staff_length == 0 do %>
        <.empty_state class="px-4 py-10">{gettext("No staff members found")}</.empty_state>
      <% else %>
        <.fluid_grid id="staff-members" phx-update="stream" is_full_width class="p-4">
          <.staff_member_card
            :for={{dom_id, staff_member} <- @streams.staff}
            id={dom_id}
            staff_member={staff_member}
            navigate={~p"/school/staff/#{staff_member}"}
            on_edit={@is_school_manager && JS.patch(~p"/school/staff?edit=#{staff_member.id}")}
          />
        </.fluid_grid>
      <% end %>
      <.live_component
        :if={@staff_member}
        module={StaffMemberFormOverlayComponent}
        id="staff-member-form-overlay"
        staff_member={@staff_member}
        title={@staff_member_overlay_title}
        on_cancel={JS.patch(~p"/school/staff")}
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
  def update(%{action: {StaffMemberFormOverlayComponent, {action, _staff_member}}}, socket)
      when action in [:created, :updated, :deactivated] do
    message =
      case action do
        :created -> gettext("Staff member created successfully")
        :updated -> gettext("Staff member updated successfully")
        :deactivated -> gettext("Staff member deactivated successfully")
      end

    socket =
      socket
      |> delegate_navigation(
        put_flash: {:info, message},
        push_navigate: [to: ~p"/school/staff"]
      )

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_staff_member()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_staff()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_staff(socket) do
    staff =
      Schools.list_staff_members(
        school_id: socket.assigns.current_user.current_profile.school_id,
        load_email: true,
        only_active: true
      )

    socket
    |> stream(:staff, staff)
    |> assign(:staff_length, length(staff))
    |> assign(:staff_members_ids, Enum.map(staff, &"#{&1.id}"))
  end

  defp assign_staff_member(
         %{assigns: %{is_school_manager: true, params: %{"new" => "true"}}} = socket
       ) do
    staff_member = %StaffMember{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:staff_member, staff_member)
    |> assign(:staff_member_overlay_title, gettext("New staff member"))
  end

  defp assign_staff_member(%{assigns: %{params: %{"edit" => staff_member_id}}} = socket) do
    with true <-
           socket.assigns.is_school_manager ||
             "#{socket.assigns.current_user.current_profile.staff_member_id}" == staff_member_id,
         true <- staff_member_id in socket.assigns.staff_members_ids do
      staff_member = Schools.get_staff_member!(staff_member_id, load_email: true)

      socket
      |> assign(:staff_member, staff_member)
      |> assign(:staff_member_overlay_title, gettext("Edit staff member"))
    else
      _ ->
        assign(socket, :staff_member, nil)
    end
  end

  defp assign_staff_member(socket), do: assign(socket, :staff_member, nil)
end
