defmodule LantternWeb.SchoolLive.GuardiansComponent do
  use LantternWeb, :live_component

  import LantternWeb.SchoolsComponents

  alias Lanttern.Schools
  alias Lanttern.Schools.Guardian

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between gap-6 p-4">
        <div class="flex gap-4">
          {ngettext("1 guardian", "%{count} guardians", @guardians_length)}
        </div>
        <div :if={@is_school_manager} class="flex items-center gap-4">
          <.action type="link" patch={~p"/school/guardians?new=true"} icon_name="hero-plus-circle-mini">
            {gettext("Add guardian")}
          </.action>
        </div>
      </div>
      <.fluid_grid id="guardians" phx-update="stream" is_full_width class="p-4">
        <.guardian_card
          :for={{dom_id, guardian} <- @streams.guardians}
          id={dom_id}
          guardian={guardian}
          navigate={~p"/school/guardians/#{guardian}"}
          show_edit={@is_school_manager}
          edit_patch={~p"/school/guardians?edit=#{guardian.id}"}
          on_delete={JS.push("delete", value: %{id: guardian.id}, target: @myself) |> hide("##{dom_id}")}
        />
      </.fluid_grid>
      <.live_component
        :if={@guardian}
        module={LantternWeb.Schools.GuardianFormOverlayComponent}
        id="guardian-form-overlay"
        guardian={@guardian}
        title={@guardian_overlay_title}
        on_cancel={JS.patch(~p"/school/guardians")}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_guardian()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_guardians()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_guardians(socket) do
    guardians =
      Schools.list_guardians(
        school_id: socket.assigns.current_user.current_profile.school_id
      )

    socket
    |> stream(:guardians, guardians, reset: true)
    |> assign(:guardians_length, length(guardians))
  end

  defp update_guardians_length(socket) do
    length = Enum.count(socket.assigns.streams.guardians || [])
    assign(socket, :guardians_length, length)
  end

  defp assign_guardian(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :guardian, nil)

  defp assign_guardian(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    guardian = %Guardian{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:guardian, guardian)
    |> assign(:guardian_overlay_title, gettext("New guardian"))
  end

  defp assign_guardian(%{assigns: %{params: %{"edit" => guardian_id}}} = socket) do
    guardian = Schools.get_guardian!(guardian_id)

    socket
    |> assign(:guardian, guardian)
    |> assign(:guardian_overlay_title, gettext("Edit guardian"))
  end

  defp assign_guardian(socket), do: assign(socket, :guardian, nil)

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    guardian = Schools.get_guardian!(id)
    {:ok, _} = Schools.delete_guardian(guardian)

    socket =
      socket
      |> put_flash(:info, gettext("Guardian deleted successfully"))
      |> stream_delete(:guardians, guardian)
      |> update_guardians_length()

    {:noreply, socket}
  end

  @impl true
  def handle_info({GuardianFormOverlayComponent, {:created, _guardian}}, socket) do
    {:noreply,
     socket
     |> stream_guardians()
     |> put_flash(:info, gettext("Guardian created successfully"))
     |> push_patch(to: ~p"/school/guardians")}
  end

  def handle_info({GuardianFormOverlayComponent, {:updated, _guardian}}, socket) do
    {:noreply,
     socket
     |> stream_guardians()
     |> put_flash(:info, gettext("Guardian updated successfully"))
     |> push_patch(to: ~p"/school/guardians")}
  end

  def handle_info({GuardianFormOverlayComponent, {:deleted, _guardian}}, socket) do
    {:noreply,
     socket
     |> stream_guardians()
     |> put_flash(:info, gettext("Guardian deleted successfully"))
     |> push_patch(to: ~p"/school/guardians")}
  end
end
