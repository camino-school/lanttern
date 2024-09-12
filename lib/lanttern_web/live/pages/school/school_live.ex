defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3]

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:years], socket.assigns.current_user)
      |> stream_classes()
      |> assign(:page_title, socket.assigns.current_user.current_profile.school_name)

    {:ok, socket}
  end

  defp stream_classes(socket) do
    years_ids = socket.assigns.selected_years_ids

    classes =
      Schools.list_user_classes(
        socket.assigns.current_user,
        preload_cycle_years_students: true,
        years_ids: years_ids
      )

    stream(socket, :classes, classes)
  end
end
