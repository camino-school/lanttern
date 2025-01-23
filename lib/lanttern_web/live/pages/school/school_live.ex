defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  # view components
  alias __MODULE__.StudentsComponent
  alias __MODULE__.ClassesComponent
  alias __MODULE__.CyclesComponent
  alias __MODULE__.MomentCardsTemplatesComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_is_school_manager()
      |> assign_is_content_manager()
      |> assign(:page_title, socket.assigns.current_user.current_profile.school_name)

    {:ok, socket}
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  defp assign_is_content_manager(socket) do
    is_content_manager =
      "content_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_content_manager, is_content_manager)
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, assign(socket, :params, params)}
end
