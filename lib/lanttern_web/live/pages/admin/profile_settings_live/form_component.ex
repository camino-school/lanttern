defmodule LantternWeb.Admin.ProfileSettingsLive.FormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Personalization
  alias LantternWeb.PersonalizationHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage profile settings in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="profile-settings-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          id="permissions-toggle"
          field={@form[:permissions]}
          type="select"
          multiple
          label="Select permissions"
          options={@permission_options}
          prompt="No permissions"
          class="mb-4"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save profile settings</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    permission_options = PersonalizationHelpers.generate_permission_options()

    socket =
      socket
      |> assign(:permission_options, permission_options)

    {:ok, socket}
  end

  @impl true
  def update(%{profile_settings: profile_settings} = assigns, socket) do
    changeset = Personalization.change_profile_settings(profile_settings)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"profile_settings" => profile_settings_params}, socket) do
    changeset =
      socket.assigns.profile_settings
      |> Personalization.change_profile_settings(profile_settings_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"profile_settings" => profile_settings_params}, socket) do
    permissions =
      case profile_settings_params["permissions"] do
        [""] -> []
        permissions -> permissions
      end

    case Personalization.set_profile_settings(
           socket.assigns.profile_settings.profile_id,
           %{permissions: permissions}
         ) do
      {:ok, profile_settings} ->
        notify_parent({:saved, profile_settings})

        socket =
          socket
          |> put_flash(:info, "Permissions updated successfully")
          |> push_patch(to: socket.assigns.patch)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
