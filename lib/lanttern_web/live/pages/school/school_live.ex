defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  # view components
  alias __MODULE__.StudentsComponent
  alias __MODULE__.ClassesComponent

  # shared components
  alias LantternWeb.Schools.ClassFormOverlayComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_is_school_manager()
      |> assign(:page_title, socket.assigns.current_user.current_profile.school_name)

    {:ok, socket, layout: {LantternWeb.Layouts, :app_logged_in_blank}}
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, assign(socket, :params, params)}

  @impl true
  def handle_info({ClassFormOverlayComponent, {:created, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class created successfully"))
      |> push_navigate(to: ~p"/school/classes")

    {:noreply, socket}
  end

  def handle_info({ClassFormOverlayComponent, {:updated, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class updated successfully"))
      |> push_navigate(to: ~p"/school/classes")

    {:noreply, socket}
  end

  def handle_info({ClassFormOverlayComponent, {:deleted, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class deleted successfully"))
      |> push_navigate(to: ~p"/school/classes")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
