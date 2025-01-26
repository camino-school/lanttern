defmodule LantternWeb.DisabledStaffLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    page_title =
      gettext(
        "%{school}'s disabled staff members",
        school: socket.assigns.current_user.current_profile.school_name
      )

    socket =
      socket
      |> assign_is_school_manager()
      |> stream_staff()
      |> assign(:page_title, page_title)

    {:ok, socket}
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  defp stream_staff(socket) do
    staff =
      Schools.list_staff_members(
        school_id: socket.assigns.current_user.current_profile.school_id,
        load_email: true,
        only_disabled: true
      )

    socket
    |> stream(:staff, staff)
    |> assign(:staff_length, length(staff))
    |> assign(:staff_members_ids, Enum.map(staff, &"#{&1.id}"))
  end

  # event handlers

  @impl true
  def handle_event("reactivate", %{"id" => id}, socket) do
    if id in socket.assigns.staff_members_ids do
      staff_member = Schools.get_staff_member!(id)

      case Schools.reactivate_staff_member(staff_member) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{staff_member} reactivated", staff_member: staff_member.name)
            )
            |> stream_delete(:staff, staff_member)
            |> assign(:staff_length, socket.assigns.staff_length - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to reactivate staff member"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid staff member"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    if id in socket.assigns.staff_members_ids do
      staff_member = Schools.get_staff_member!(id)

      case Schools.delete_staff_member(staff_member) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(
              :info,
              gettext("%{staff_member} deleted", staff_member: staff_member.name)
            )
            |> stream_delete(:staff, staff_member)
            |> assign(:staff_length, socket.assigns.staff_length - 1)

          {:noreply, socket}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to delete staff member"))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Invalid staff member"))}
    end
  end
end
