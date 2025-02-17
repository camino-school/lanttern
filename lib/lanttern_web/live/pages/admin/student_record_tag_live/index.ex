defmodule LantternWeb.Admin.StudentRecordTagLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.Tag

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :student_record_tags, StudentsRecords.list_student_record_tags())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Student record tag")
    |> assign(:student_record_tag, StudentsRecords.get_student_record_tag!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Student record tag")
    |> assign(:student_record_tag, %Tag{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Student record tags")
    |> assign(:student_record_tag, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Admin.StudentRecordTagLive.FormComponent, {:saved, student_record_tag}},
        socket
      ) do
    {:noreply, stream_insert(socket, :student_record_tags, student_record_tag)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    student_record_tag = StudentsRecords.get_student_record_tag!(id)
    {:ok, _} = StudentsRecords.delete_student_record_tag(student_record_tag)

    {:noreply, stream_delete(socket, :student_record_tags, student_record_tag)}
  end
end
