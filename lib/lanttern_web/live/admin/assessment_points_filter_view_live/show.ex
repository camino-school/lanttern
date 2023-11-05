defmodule LantternWeb.Admin.AssessmentPointsFilterViewLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Explorer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    assesment_point_filter_view =
      Explorer.get_assessment_points_filter_view!(id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:assessment_points_filter_view, assesment_point_filter_view)}
  end

  defp page_title(:show), do: "Show Assessment points filter view"
  defp page_title(:edit), do: "Edit Assessment points filter view"

  def profile_name(%{type: "teacher"} = profile),
    do: profile.teacher.name

  def profile_name(%{type: "student"} = profile),
    do: profile.student.name
end
