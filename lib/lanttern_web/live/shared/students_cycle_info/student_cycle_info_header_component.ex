defmodule LantternWeb.StudentsCycleInfo.StudentCycleInfoHeaderComponent do
  @moduledoc """
  Renders a student cycle profile header with picture, name, and cycles dropdown.

  ### Required attrs

  - `:selected_cycle_id`
  - `:student_cycle_info` - `%Lanttern.StudentsCycleInfo.StudentCycleInfo{}`
  - `:student` - `%Lanttern.Schools.Student{}`
  - `:on_change_cycle` - function. Called with cycle id as argument

  ### Optional attrs

  - `:class` - any, additional classes for the component
  - `:on_edit_profile_picture` - any, passed to edit profile picture button's `phx-click`

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["sm:flex sm:items-center sm:gap-6", @class]}>
      <div class="relative">
        <.profile_picture
          class="shadow-lg"
          picture_url={@student_cycle_info.profile_picture_url}
          profile_name={@student.name}
          size="lg"
        />
        <.button
          :if={@on_edit_profile_picture}
          icon_name="hero-pencil-mini"
          sr_text={gettext("Edit cycle profile picture")}
          rounded
          size="sm"
          theme="white"
          class="absolute bottom-0 right-0"
          phx-click={@on_edit_profile_picture}
        />
      </div>
      <div class="mt-6 sm:mt-0">
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
                on_click={@on_change_cycle.(cycle.id)}
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
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:on_edit_profile_picture, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

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
        cycle.id == socket.assigns.selected_cycle_id
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

  # helpers

  defp cycle_classes_opt([]), do: gettext("No classes")
  defp cycle_classes_opt(classes), do: Enum.map_join(classes, ", ", & &1.name)
end
