defmodule LantternWeb.StudentRecordTypeLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.StudentsRecords

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:student_record_type, StudentsRecords.get_student_record_type!(id))}
  end

  defp page_title(:show), do: "Show Student record type"
  defp page_title(:edit), do: "Edit Student record type"
end
