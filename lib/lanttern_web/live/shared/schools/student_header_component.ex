defmodule LantternWeb.Schools.StudentHeaderComponent do
  @moduledoc """
  Renders a student profile header with picture, name, and cycle classes.

  ### Required attrs

  - `:cycle_id`
  - `:student_id`

  ### Optional attrs

  - `:class` - any, additional classes for the component
  - `:on_edit_profile_picture` - any, passed to edit profile picture button's `phx-click`
  - `:show_deactivated` - boolean, show deactivated info
  - `:show_tags` - boolean, show tags info
  - `:navigate` - function, student id as argument. Expect a valid `<.link>` `navigate` attr.
  - `:cycle_tooltip` - string, tooltip for cycle badge. Useful to indicate to users that they can change the current cycle in the main menu.

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  import LantternWeb.DateTimeHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={["sm:flex sm:items-center sm:gap-6", @class]}>
      <div class="relative">
        <.profile_picture
          class="shadow-lg"
          picture_url={@student.profile_picture_url}
          profile_name={@student.name}
          size="xl"
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
        <div class="flex items-center gap-2">
          <h2 class={[
            "flex items-center gap-2 font-display font-bold text-2xl",
            if(@show_deactivated && @student.deactivated_at,
              do: "text-ltrn-subtle",
              else: "text-ltrn-darkest"
            )
          ]}>
            <%= if @navigate do %>
              <.link navigate={@navigate.(@student.id)} class="hover:text-ltrn-subtle">
                {@student.name}
              </.link>
              <a href={@navigate.(@student.id)} target="_blank" class="hover:text-ltrn-subtle">
                <.icon name="hero-arrow-top-right-on-square-mini" />
              </a>
            <% else %>
              {@student.name}
            <% end %>
          </h2>
          <.badge :if={@show_deactivated && @student.deactivated_at} theme="dark">
            {gettext("Deactivated")}
          </.badge>
        </div>
        <%= if @age do %>
          <div class="mt-2 text-sm text-ltrn-subtle">
            {format_age_full(@age)} ({format_birthdate(@student.birthdate)})
          </div>
        <% end %>
        <div class="flex items-center gap-4 mt-2">
          <%= if @show_tags do %>
            <.badge :for={tag <- @student.tags} color_map={tag}>
              {tag.name}
            </.badge>
          <% end %>
          <div {if(@cycle_tooltip, do: %{"tabindex" => "0"}, else: %{})}>
            <.badge theme="dark">
              {@cycle.name}
            </.badge>
            <.tooltip :if={@cycle_tooltip} id={"#{@id}-cycle-tooltip"}>
              {@cycle_tooltip}
            </.tooltip>
          </div>
          <%= if @student.classes == [] do %>
            <.badge>
              {gettext("No classes linked to student in cycle")}
            </.badge>
          <% else %>
            <.badge :for={class <- @student.classes} id={"#{@id}-student-class-#{class.id}"}>
              {class.name}
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
      |> assign(:on_edit_profile_picture, nil)
      |> assign(:show_deactivated, false)
      |> assign(:show_tags, false)
      |> assign(:navigate, nil)
      |> assign(:cycle_tooltip, nil)
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
    opts = [
      load_profile_picture_from_cycle_id: socket.assigns.cycle_id,
      preload_classes_from_cycle_id: socket.assigns.cycle_id,
      preloads: :tags
    ]

    opts =
      if socket.assigns.show_tags do
        [{:preloads, :tags} | opts]
      else
        opts
      end

    student =
      Schools.get_student(
        socket.assigns.student_id,
        opts
      )

    age = calculate_age(student.birthdate)

    socket
    |> assign(:student, student)
    |> assign(:age, age)
  end
end
