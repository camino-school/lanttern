defmodule LantternWeb.Admin.ProfileSettingsLive.Index do
  alias Lanttern.Personalization
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Identity
  alias Lanttern.Personalization.ProfileSettings

  @impl true
  def mount(_params, _session, socket) do
    profiles =
      Identity.list_profiles(type: "teacher", preloads: [:teacher, :settings])
      |> Enum.map(&%{&1 | name: &1.teacher.name})

    {:ok, stream(socket, :profiles, profiles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"profile_id" => profile_id}) do
    profile_settings =
      Personalization.get_profile_settings(profile_id) ||
        %ProfileSettings{profile_id: profile_id}

    socket
    |> assign(:page_title, "Edit profile settings")
    |> assign(:profile_settings, profile_settings)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing profile settings")
    |> assign(:profile_settings, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Admin.ProfileSettingsLive.FormComponent, {:saved, profile_setting}},
        socket
      ) do
    profile =
      profile_setting.profile_id
      |> Identity.get_profile!(preloads: [:teacher, :settings])

    profile = %{profile | name: profile.teacher.name}

    {:noreply, stream_insert(socket, :profiles, profile)}
  end
end
