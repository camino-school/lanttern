defmodule LantternWeb.StudentLive.AboutComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo

  # shared components
  # import LantternWeb.ReportingComponents
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10">
      <div class="flex items-center gap-6">
        <div class="w-32 h-32 rounded-full bg-ltrn-subtle shadow-lg"></div>
        <div>
          <h2 class="font-display font-black text-2xl">
            <%= @student.name %>
          </h2>
          <div class="flex items-center gap-4 mt-2">
            <div class="relative">
              <.action
                type="button"
                id="current-cycle-dropdown-button"
                icon_name="hero-chevron-down-mini"
              >
                <%= @current_cycle.name %>
              </.action>
              <.dropdown_menu
                id="current-cycle-dropdown"
                button_id="current-cycle-dropdown-button"
                z_index="10"
              >
                <:item
                  :for={{cycle, classes} <- @cycles_and_classes}
                  text={"#{cycle.name} (#{cycle_classes_opt(classes)})"}
                  on_click={
                    JS.push("change_cycle", value: %{"cycle_id" => cycle.id}, target: @myself)
                  }
                />
              </.dropdown_menu>
            </div>
            <%= if @current_classes == [] do %>
              <.badge>
                <%= gettext("No classes linked to student in cycle") %>
              </.badge>
            <% else %>
              <.badge :for={class <- @current_classes} id={"current-student-class-#{class.id}"}>
                <%= class.name %>
              </.badge>
            <% end %>
          </div>
        </div>
      </div>
      <div class="flex items-start gap-10 mt-12">
        <div class="flex-1">
          <div class="pb-6 border-b-2 border-ltrn-light">
            <h4 class="font-display font-black text-lg"><%= gettext("School area") %></h4>
            <p class="flex items-center gap-2 mt-2">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Access to information in this area is restricted to school staff") %>
            </p>
          </div>
          <div class="mt-10">
            <.empty_state_simple>
              <%= gettext("No information about student in school area") %>
            </.empty_state_simple>
            <.action type="button" icon_name="hero-pencil-mini" class="mt-10">
              <%= gettext("Edit information") %>
            </.action>
          </div>
        </div>
        <div class="flex-1">
          <div class="pb-6 border-b-2 border-ltrn-student-lighter">
            <h4 class="font-display font-black text-lg text-ltrn-student-dark">
              <%= gettext("Family area") %>
            </h4>
            <p class="flex items-center gap-2 mt-2">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Information shared with student and family") %>
            </p>
          </div>
          <div class="mt-10">
            <.empty_state_simple>
              <%= gettext("No information about student in family area") %>
            </.empty_state_simple>
            <.action type="button" icon_name="hero-pencil-mini" class="mt-10">
              <%= gettext("Edit information") %>
            </.action>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket),
    do: {:ok, assign(socket, :initialized, false)}

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:student_info])
    |> assign_cycles_and_classes()
    |> assign_current_cycle_and_classes()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_cycles_and_classes(socket) do
    cycles_and_classes =
      StudentsCycleInfo.list_cycles_and_classes_for_student(socket.assigns.student)

    socket
    |> assign(:cycles_and_classes, cycles_and_classes)
  end

  defp assign_current_cycle_and_classes(socket) do
    {current_cycle, current_classes} =
      socket.assigns.cycles_and_classes
      |> Enum.find(fn {cycle, _classes} ->
        cycle.id == socket.assigns.student_info_selected_cycle_id
      end)
      |> case do
        # if for some reason we can't find cycle and classes,
        # use the first item of the list
        nil -> List.first(socket.assigns.cycles_and_classes)
        cycle_and_classes -> cycle_and_classes
      end

    socket
    |> assign(:current_cycle, current_cycle)
    |> assign(:current_classes, current_classes)
  end

  # event handlers

  @impl true
  def handle_event("change_cycle", %{"cycle_id" => id}, socket) do
    socket =
      socket
      |> assign(:student_info_selected_cycle_id, id)
      |> save_profile_filters([:student_info])
      |> assign_current_cycle_and_classes()

    {:noreply, socket}
  end

  # helpers

  defp cycle_classes_opt([]), do: gettext("No classes")
  defp cycle_classes_opt(classes), do: Enum.map_join(classes, ", ", & &1.name)
end
