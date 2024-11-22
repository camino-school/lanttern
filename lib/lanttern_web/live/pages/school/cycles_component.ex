defmodule LantternWeb.SchoolLive.CyclesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2]

  # shared components
  alias LantternWeb.Schools.CycleFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-6">
        <div :if={@is_school_manager} class="flex justify-end mt-10">
          <div class="flex gap-4">
            <.collection_action
              type="link"
              patch={~p"/school/cycles?new=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Add cycle") %>
            </.collection_action>
          </div>
        </div>
      </.responsive_container>
      <%= if @has_cycles do %>
        <.responsive_grid id="school-cycles" phx-update="stream" is_full_width>
          <.card_base
            :for={{dom_id, cycle} <- @streams.cycles}
            id={dom_id}
            class="min-w-[16rem] sm:min-w-0 p-4"
          >
            <%= cycle.name %>
            <.link patch={~p"/school/cycles?edit=#{cycle.id}"}>edit</.link>
          </.card_base>
        </.responsive_grid>
      <% else %>
        <.responsive_container class="pt-6 pb-10">
          <.empty_state>
            <%= gettext("No cycles in this school") %>
          </.empty_state>
        </.responsive_container>
      <% end %>
      <.live_component
        :if={@cycle}
        module={CycleFormOverlayComponent}
        id="cycle-form-overlay"
        cycle={@cycle}
        title={@cycle_form_overlay_title}
        on_cancel={JS.patch(~p"/school/cycles")}
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
  def update(%{action: {CycleFormOverlayComponent, {:created, _cycle}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Cycle created successfully")},
      push_navigate: [to: ~p"/school/cycles"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(%{action: {CycleFormOverlayComponent, {:updated, cycle}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Cycle updated successfully")},
      push_patch: [to: ~p"/school/cycles"]
    ]

    socket =
      socket
      |> delegate_navigation(nav_opts)
      |> stream_insert(:cycles, cycle)

    {:ok, socket}
  end

  def update(%{action: {CycleFormOverlayComponent, {:deleted, cycle}}}, socket) do
    nav_opts = [
      put_flash: {:info, gettext("Cycle deleted successfully")},
      push_patch: [to: ~p"/school/cycles"]
    ]

    socket =
      socket
      |> delegate_navigation(nav_opts)
      |> stream_delete(:cycles, cycle)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_cycle()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:years, :cycles])
    |> stream_cycles()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_cycles(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    cycles = Schools.list_cycles(schools_ids: [school_id])

    socket
    |> stream(:cycles, cycles)
    |> assign(:has_cycles, length(cycles) > 0)
  end

  defp assign_cycle(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :cycle, nil)

  defp assign_cycle(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    cycle = %Cycle{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:cycle, cycle)
    |> assign(:cycle_form_overlay_title, gettext("Create cycle"))
  end

  defp assign_cycle(%{assigns: %{params: %{"edit" => cycle_id}}} = socket) do
    cycle =
      Schools.get_cycle(cycle_id,
        check_permissions_for_user: socket.assigns.current_user
      )

    socket
    |> assign(:cycle, cycle)
    |> assign(:cycle_form_overlay_title, gettext("Edit cycle"))
  end

  defp assign_cycle(socket), do: assign(socket, :cycle, nil)
end
