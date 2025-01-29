defmodule LantternWeb.StudentsRecordsSettingsLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords

  import Lanttern.Utils, only: [swap: 3]

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Students records settings"))
      |> assign_tags_with_index()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "students_records_full_access" in socket.assigns.current_user.current_profile.permissions

    if has_access, do: socket, else: raise(LantternWeb.NotFoundError)
  end

  defp assign_tags_with_index(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    tags = StudentsRecords.list_student_record_tags(school_id: school_id)

    socket
    |> assign(:tags_with_index, Enum.with_index(tags))
    |> assign(:tags_length, length(tags))
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, assign(socket, :params, params)}

  # event handlers

  @impl true
  def handle_event("swap_tags_position", %{"from" => i, "to" => j}, socket) do
    sorted_tags =
      socket.assigns.tags_with_index
      |> Enum.map(fn {t, _i} -> t end)
      |> swap(i, j)

    sorted_tags_ids = Enum.map(sorted_tags, & &1.id)

    case StudentsRecords.update_student_record_tags_positions(sorted_tags_ids) do
      :ok ->
        {:noreply, assign(socket, :tags_with_index, Enum.with_index(sorted_tags))}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
