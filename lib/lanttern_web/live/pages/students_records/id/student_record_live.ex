defmodule LantternWeb.StudentRecordLive do
  use LantternWeb, :live_view

  alias Lanttern.StudentsRecords

  import LantternWeb.PersonalizationHelpers, only: [profile_has_permission?: 2]

  # shared components

  alias LantternWeb.StudentsRecords.StudentRecordFormOverlayComponent
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    if !profile_has_permission?(socket.assigns.current_user.current_profile, "wcd"),
      do: raise(LantternWeb.NotFoundError)

    socket =
      socket
      |> assign_student_record(params)
      |> check_profile_school_access()

    {:ok, socket}
  end

  defp assign_student_record(socket, %{"id" => id}) do
    student_record =
      StudentsRecords.get_student_record(id,
        preloads: [
          :students,
          :students_relationships,
          :classes_relationships,
          :type,
          :status,
          [classes: :cycle]
        ]
      )
      |> put_students_ids()

    page_title = student_record.name || gettext("Student record details")

    socket
    |> assign(:student_record, student_record)
    |> assign(:page_title, page_title)
  end

  defp put_students_ids(student_record) do
    students_ids =
      student_record.students_relationships
      |> Enum.map(& &1.student_id)

    %{student_record | students_ids: students_ids}
  end

  defp check_profile_school_access(socket) do
    %{
      student_record: %{school_id: record_school_id},
      current_user: %{current_profile: %{school_id: profile_school_id}}
    } = socket.assigns

    if record_school_id != profile_school_id,
      do: raise(LantternWeb.NotFoundError)

    socket
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  # info handlers

  @impl true
  def handle_info({StudentRecordFormOverlayComponent, {:updated, _student_record}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student record updated successfully"))
      |> push_navigate(to: ~p"/students_records/#{socket.assigns.student_record}")

    {:noreply, socket}
  end

  def handle_info({StudentRecordFormOverlayComponent, {:deleted, _student_record}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Student record deleted successfully"))
      |> push_navigate(to: ~p"/students_records")

    {:noreply, socket}
  end
end
