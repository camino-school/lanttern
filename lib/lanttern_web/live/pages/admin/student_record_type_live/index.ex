defmodule LantternWeb.StudentRecordTypeLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecordType

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :student_record_types, StudentsRecords.list_student_record_types())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Student record type")
    |> assign(:student_record_type, StudentsRecords.get_student_record_type!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Student record type")
    |> assign(:student_record_type, %StudentRecordType{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Student record types")
    |> assign(:student_record_type, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.StudentRecordTypeLive.FormComponent, {:saved, student_record_type}},
        socket
      ) do
    {:noreply, stream_insert(socket, :student_record_types, student_record_type)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student_record_type = StudentsRecords.get_student_record_type!(id)
    {:ok, _} = StudentsRecords.delete_student_record_type(student_record_type)

    {:noreply, stream_delete(socket, :student_record_types, student_record_type)}
  end
end
