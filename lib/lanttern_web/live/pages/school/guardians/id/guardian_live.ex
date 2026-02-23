defmodule LantternWeb.GuardianLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  alias LantternWeb.Schools.GuardianFormOverlayComponent

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_guardian(params)
      |> assign_is_school_manager()

    {:ok, socket}
  end

  defp assign_guardian(socket, params) do
    scope = socket.assigns.current_user.current_profile

    case Schools.get_guardian(scope, params["id"], preloads: [:school, :students]) do
      %{} = guardian ->
        check_if_user_has_access(socket.assigns.current_user, guardian)

        shared_guardians = Schools.get_shared_guardians(scope, guardian)

        socket
        |> assign(:guardian, guardian)
        |> assign(:shared_guardians, shared_guardians)
        |> assign(:page_title, guardian.name)

      _ ->
        raise(LantternWeb.NotFoundError)
    end
  end

  # check if user can view the guardian profile
  # staff members can view only guardians from their school
  defp check_if_user_has_access(current_user, guardian) do
    if guardian.school_id != current_user.current_profile.school_id,
      do: raise(LantternWeb.NotFoundError)
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

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  @impl true
  def handle_info({GuardianFormOverlayComponent, {:updated, guardian}}, socket) do
    socket =
      socket
      |> assign(:guardian, guardian)
      |> put_flash(:info, gettext("Guardian updated successfully"))
      |> push_patch(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info({GuardianFormOverlayComponent, {:deleted, _guardian}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Guardian deleted successfully"))
      |> push_navigate(to: ~p"/school/guardians")

    {:noreply, socket}
  end
end
