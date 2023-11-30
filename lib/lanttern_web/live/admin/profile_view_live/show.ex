defmodule LantternWeb.Admin.ProfileViewLive.Show do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Personalization

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    assesment_point_filter_view =
      Personalization.get_profile_view!(id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:profile_view, assesment_point_filter_view)}
  end

  defp page_title(:show), do: "Show Profile view"
  defp page_title(:edit), do: "Edit Profile view"

  def profile_name(%{type: "teacher"} = profile),
    do: profile.teacher.name

  def profile_name(%{type: "student"} = profile),
    do: profile.student.name
end
