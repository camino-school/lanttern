defmodule LantternWeb.Admin.StudentRecordStatusLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.StudentRecordStatus

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :student_record_statuses, StudentsRecords.list_student_record_statuses())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Student record status")
    |> assign(:student_record_status, StudentsRecords.get_student_record_status!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Student record status")
    |> assign(:student_record_status, %StudentRecordStatus{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Student record statuses")
    |> assign(:student_record_status, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Admin.StudentRecordStatusLive.FormComponent,
         {:saved, student_record_status}},
        socket
      ) do
    {:noreply, stream_insert(socket, :student_record_statuses, student_record_status)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student_record_status = StudentsRecords.get_student_record_status!(id)
    {:ok, _} = StudentsRecords.delete_student_record_status(student_record_status)

    {:noreply, stream_delete(socket, :student_record_statuses, student_record_status)}
  end
end
