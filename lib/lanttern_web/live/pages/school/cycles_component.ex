defmodule LantternWeb.SchoolLive.CyclesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle

  # shared components
  alias LantternWeb.Schools.CycleFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div :if={@is_school_manager} class="flex justify-end gap-6 p-4">
        <.action type="link" patch={~p"/school/cycles?new=true"} icon_name="hero-plus-circle-mini">
          {gettext("Add cycle")}
        </.action>
      </div>
      <%= if @has_cycles do %>
        <div class="bg-white">
          <.data_grid
            id="cycles"
            stream={@streams.cycles}
            show_empty_state_message={if !@has_cycles, do: gettext("No cycles found in this school.")}
            sticky_header_offset="7rem"
          >
            <:col :let={cycle} label={gettext("Cycle")}>
              <%= if !cycle.parent_cycle_id do %>
                <div class="flex items-center gap-2 font-bold">
                  <.icon name="hero-folder" class="w-6 h-6" /> {cycle.name}
                </div>
              <% else %>
                <div class="ml-8">
                  {cycle.name}
                </div>
              <% end %>
            </:col>
            <:col :let={cycle} label={gettext("Start at")}>
              {cycle.start_at}
            </:col>
            <:col :let={cycle} label={gettext("End at")}>
              {cycle.end_at}
            </:col>
            <:action :let={cycle} :if={@is_school_manager}>
              <.button
                type="link"
                sr_text={gettext("Edit cycle")}
                icon_name="hero-pencil-mini"
                size="sm"
                theme="ghost"
                rounded
                patch={~p"/school/cycles?edit=#{cycle.id}"}
              />
            </:action>
          </.data_grid>
        </div>
      <% else %>
        <.responsive_container class="pt-6 pb-10">
          <.empty_state>
            {gettext("No cycles in this school")}
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
      push_navigate: [to: ~p"/school/cycles"]
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
    |> stream_cycles()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_cycles(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    cycles =
      Schools.list_cycles_and_subcycles(schools_ids: [school_id])
      |> Enum.flat_map(&[%{&1 | subcycles: nil} | &1.subcycles])

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
