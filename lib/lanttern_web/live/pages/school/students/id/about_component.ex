defmodule LantternWeb.StudentLive.AboutComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo

  # shared components
  # import LantternWeb.ReportingComponents
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]
  alias LantternWeb.StudentsCycleInfo.StudentCycleInfoFormComponent

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
            <%= if @is_editing_student_school_info do %>
              <.live_component
                module={StudentCycleInfoFormComponent}
                id={"#{@student_cycle_info.id}-school-info-form"}
                student_cycle_info={@student_cycle_info}
                type="school"
                label={gettext("Add school area student info...")}
                notify_component={@myself}
              />
            <% else %>
              <.empty_state_simple :if={!@student_cycle_info.school_info}>
                <%= gettext("No information about student in school area") %>
              </.empty_state_simple>
              <.markdown text={@student_cycle_info.school_info} />
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                class="mt-10"
                phx-click="edit_student_school_info"
                phx-target={@myself}
                disabled={@is_editing_student_family_info}
              >
                <%= gettext("Edit information") %>
              </.action>
            <% end %>
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
            <%= if @is_editing_student_family_info do %>
              <.live_component
                module={StudentCycleInfoFormComponent}
                id={"#{@student_cycle_info.id}-family-info-form"}
                student_cycle_info={@student_cycle_info}
                type="family"
                label={gettext("Add family area student info...")}
                notify_component={@myself}
              />
            <% else %>
              <.empty_state_simple :if={!@student_cycle_info.family_info}>
                <%= gettext("No information about student in family area") %>
              </.empty_state_simple>
              <.markdown text={@student_cycle_info.family_info} />
              <.action
                type="button"
                icon_name="hero-pencil-mini"
                class="mt-10"
                phx-click="edit_student_family_info"
                phx-target={@myself}
                disabled={@is_editing_student_school_info}
              >
                <%= gettext("Edit information") %>
              </.action>
            <% end %>
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
  def update(%{action: {StudentCycleInfoFormComponent, {:cancel, "school"}}}, socket) do
    {:ok, assign(socket, :is_editing_student_school_info, false)}
  end

  def update(%{action: {StudentCycleInfoFormComponent, {:cancel, "family"}}}, socket) do
    {:ok, assign(socket, :is_editing_student_family_info, false)}
  end

  def update(%{action: {StudentCycleInfoFormComponent, {:saved, student_cycle_info}}}, socket) do
    socket =
      socket
      |> assign(:student_cycle_info, student_cycle_info)
      |> assign(:is_editing_student_school_info, false)
      |> assign(:is_editing_student_family_info, false)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign(:is_editing_student_school_info, false)
    |> assign(:is_editing_student_family_info, false)
    |> assign_user_filters([:student_info])
    |> assign_cycles_and_classes()
    |> assign_current_cycle_and_classes()
    |> assign_student_cycle_info()
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

  defp assign_student_cycle_info(socket) do
    student_cycle_info =
      StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(
        socket.assigns.student.id,
        socket.assigns.current_cycle.id
      )
      |> case do
        nil ->
          # create student cycle info if it does not exist
          {:ok, info} =
            StudentsCycleInfo.create_student_cycle_info(%{
              school_id: socket.assigns.student.school_id,
              student_id: socket.assigns.student.id,
              cycle_id: socket.assigns.current_cycle.id
            })

          info

        student_cycle_info ->
          student_cycle_info
      end

    assign(socket, :student_cycle_info, student_cycle_info)
  end

  # event handlers

  @impl true
  def handle_event("change_cycle", %{"cycle_id" => id}, socket) do
    socket =
      socket
      |> assign(:student_info_selected_cycle_id, id)
      |> save_profile_filters([:student_info])
      |> assign_current_cycle_and_classes()
      |> assign_student_cycle_info()
      |> assign(:is_editing_student_school_info, false)
      |> assign(:is_editing_student_family_info, false)

    {:noreply, socket}
  end

  def handle_event("edit_student_school_info", _params, socket),
    do: {:noreply, assign(socket, :is_editing_student_school_info, true)}

  def handle_event("edit_student_family_info", _params, socket),
    do: {:noreply, assign(socket, :is_editing_student_family_info, true)}

  # helpers

  defp cycle_classes_opt([]), do: gettext("No classes")
  defp cycle_classes_opt(classes), do: Enum.map_join(classes, ", ", & &1.name)
end
