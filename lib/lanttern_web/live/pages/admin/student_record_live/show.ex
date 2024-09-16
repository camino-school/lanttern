defmodule LantternWeb.StudentRecordLive.Show do
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
     |> assign(:student_record, StudentsRecords.get_student_record!(id))}
  end

  defp page_title(:show), do: "Show Student record"
  defp page_title(:edit), do: "Edit Student record"
end
