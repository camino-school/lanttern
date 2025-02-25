defmodule LantternWeb.Schools.StudentHeaderComponent do
  @moduledoc """
  Renders a student profile header with picture, name, and cycle classes.

  ### Required attrs

  - `:cycle_id`
  - `:student_id`

  ### Optional attrs

  - `:class` - any, additional classes for the component

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["sm:flex sm:items-center sm:gap-6", @class]}>
      <.profile_picture
        class="shadow-lg"
        picture_url={@student.profile_picture_url}
        profile_name={@student.name}
        size="xl"
      />
      <div class="mt-6 sm:mt-0">
        <h2 class="font-display font-black text-2xl">
          <%= @student.name %>
        </h2>
        <div class="flex items-center gap-4 mt-2">
          <.badge theme="dark">
            <%= @cycle.name %>
          </.badge>
          <%= if @student.classes == [] do %>
            <.badge>
              <%= gettext("No classes linked to student in cycle") %>
            </.badge>
          <% else %>
            <.badge :for={class <- @student.classes} id={"student-class-#{class.id}"}>
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
    |> assign_cycle()
    |> assign_student()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_cycle(socket) do
    cycle = Schools.get_cycle(socket.assigns.cycle_id)
    assign(socket, :cycle, cycle)
  end

  defp assign_student(socket) do
    student =
      Schools.get_student(
        socket.assigns.student_id,
        load_profile_picture_from_cycle_id: socket.assigns.cycle_id,
        preload_classes_from_cycle_id: socket.assigns.cycle_id
      )

    assign(socket, :student, student)
  end
end
