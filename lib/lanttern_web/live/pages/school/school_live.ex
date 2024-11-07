defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  # view components
  alias __MODULE__.StudentsComponent
  alias __MODULE__.ClassesComponent

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
end
