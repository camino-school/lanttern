defmodule LantternWeb.StudentsRecordsSettingsLive do
  use LantternWeb, :live_view

  # page imports

  alias __MODULE__.TagsComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Students records settings"))

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "students_records_full_access" in socket.assigns.current_user.current_profile.permissions

    if has_access, do: socket, else: raise(LantternWeb.NotFoundError)
  end

  @impl true
  def handle_params(params, _uri, socket), do: {:noreply, assign(socket, :params, params)}
end
