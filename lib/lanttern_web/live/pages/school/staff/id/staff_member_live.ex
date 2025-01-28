defmodule LantternWeb.StaffMemberLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  alias Lanttern.Schools.StaffMember

  # page components

  alias __MODULE__.StudentsRecordsComponent

  # shared components

  alias LantternWeb.Schools.StaffMemberFormOverlayComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_staff_member(params)
      |> assign_is_school_manager()
      |> assign_is_wcd()
      |> assign_is_current_user()

    {:ok, socket}
  end

  defp assign_staff_member(socket, params) do
    case Schools.get_staff_member!(params["id"], preloads: :school, load_email: true) do
      %StaffMember{} = staff_member ->
        check_if_user_has_access(socket.assigns.current_user, staff_member)

        socket
        |> assign(:staff_member, staff_member)
        |> assign(:page_title, staff_member.name)

      _ ->
        raise(LantternWeb.NotFoundError)
    end
  end

  # check if user can view the staff member profile
  # users can view only staff members from their school
  defp check_if_user_has_access(current_user, staff_member) do
    if staff_member.school_id != current_user.current_profile.school_id,
      do: raise(LantternWeb.NotFoundError)
  end

  defp assign_is_current_user(socket) do
    is_current_user =
      socket.assigns.current_user.current_profile.staff_member_id ==
        socket.assigns.staff_member.id

    assign(socket, :is_current_user, is_current_user)
  end

  defp assign_is_wcd(socket) do
    is_wcd = "wcd" in socket.assigns.current_user.current_profile.permissions
    assign(socket, :is_wcd, is_wcd)
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_is_editing(params)

    {:noreply, socket}
  end

  defp assign_is_editing(%{assigns: %{is_school_manager: true}} = socket, %{"edit" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(%{assigns: %{is_current_user: true}} = socket, %{"edit" => "true"}),
    do: assign(socket, :is_editing, true)

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  @impl true
  def handle_info({StaffMemberFormOverlayComponent, {:updated, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Staff member updated successfully"))
      |> push_navigate(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info({StaffMemberFormOverlayComponent, {:deleted, _student}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Staff member deleted successfully"))
      |> push_navigate(to: ~p"/school/staff")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: socket
end
