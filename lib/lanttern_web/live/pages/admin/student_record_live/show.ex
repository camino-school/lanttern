defmodule LantternWeb.Admin.StudentRecordLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    student_record =
      StudentsRecords.get_student_record!(id, preloads: [:students, :students_relationships])
      |> put_students_ids()

    socket =
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:student_record, student_record)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Student record"
  defp page_title(:edit), do: "Edit Student record"

  defp put_students_ids(student_record) do
    students_ids =
      student_record.students_relationships
      |> Enum.map(& &1.student_id)

    %{student_record | students_ids: students_ids}
  end
end
