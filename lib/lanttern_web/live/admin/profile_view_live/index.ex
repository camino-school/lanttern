defmodule LantternWeb.Admin.ProfileViewLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Personalization
  alias Lanttern.Personalization.ProfileView

  @impl true
  def mount(_params, _session, socket) do
    profile_views =
      Personalization.list_profile_views(
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:ok, stream(socket, :profile_views, profile_views)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Profile view")
    |> assign(
      :profile_view,
      Personalization.get_profile_view!(id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Profile view")
    |> assign(:profile_view, %ProfileView{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Profile views")
    |> assign(:profile_view, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Admin.ProfileViewLive.FormComponent, {:saved, profile_view}},
        socket
      ) do
    profile_view =
      Personalization.get_profile_view!(profile_view.id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:noreply, stream_insert(socket, :profile_views, profile_view)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    profile_view = Personalization.get_profile_view!(id)
    {:ok, _} = Personalization.delete_profile_view(profile_view)

    {:noreply, stream_delete(socket, :profile_views, profile_view)}
  end

  def profile_name(%{type: "teacher"} = profile),
    do: profile.teacher.name

  def profile_name(%{type: "student"} = profile),
    do: profile.student.name
end
