defmodule LantternWeb.StudentRecordLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecord

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :students_records, StudentsRecords.list_students_records())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Student record")
    |> assign(:student_record, StudentsRecords.get_student_record!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Student record")
    |> assign(:student_record, %StudentRecord{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Students records")
    |> assign(:student_record, nil)
  end

  @impl true
  def handle_info({LantternWeb.StudentRecordLive.FormComponent, {:saved, student_record}}, socket) do
    {:noreply, stream_insert(socket, :students_records, student_record)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student_record = StudentsRecords.get_student_record!(id)
    {:ok, _} = StudentsRecords.delete_student_record(student_record)

    {:noreply, stream_delete(socket, :students_records, student_record)}
  end
end
