defmodule LantternWeb.StudentsRecordsLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_students_records()
      |> assign(:page_title, gettext("Students records"))

    {:ok, socket}
  end

  defp stream_students_records(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    students_records =
      StudentsRecords.list_students_records(school_id: school_id, preloads: [:type, :status])

    socket
    |> stream(:students_records, students_records)
    |> assign(:students_records_length, length(students_records))
  end
end
