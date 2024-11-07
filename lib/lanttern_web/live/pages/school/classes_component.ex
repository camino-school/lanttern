defmodule LantternWeb.SchoolLive.ClassesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Student
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2]

  # shared components
  alias LantternWeb.Schools.ClassFormOverlayComponent
  alias LantternWeb.Schools.StudentFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-6">
        <div class="flex items-end justify-between gap-6 mt-10">
          <p class="font-display font-bold text-lg">
            <%= gettext("Showing classes from") %><br />
            <.filter_text_button
              type={gettext("years")}
              items={@selected_years}
              on_click={JS.exec("data-show", to: "#school-year-filters-overlay")}
            />
          </p>
          <div class="flex gap-4">
            <.collection_action
              :if={@is_school_manager}
              type="link"
              patch={~p"/school/classes?create_class=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Add class") %>
            </.collection_action>
            <.collection_action
              :if={@is_school_manager}
              type="link"
              patch={~p"/school/classes?create_student=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Add student") %>
            </.collection_action>
          </div>
        </div>
      </.responsive_container>
      <.responsive_grid id="school-classes" phx-update="stream" is_full_width>
        <.card_base
          :for={{dom_id, class} <- @streams.classes}
          id={dom_id}
          class="min-w-[16rem] sm:min-w-0 p-4"
        >
          <div class="flex items-center justify-between gap-4">
            <p class="font-display font-black"><%= class.name %> (<%= class.cycle.name %>)</p>
            <.button
              :if={@is_school_manager}
              type="link"
              icon_name="hero-pencil-mini"
              sr_text={gettext("Edit class")}
              rounded
              size="sm"
              theme="ghost"
              patch={~p"/school/classes?edit_class=#{class}"}
            />
          </div>
          <div class="flex flex-wrap gap-2 mt-4">
            <.badge :for={year <- class.years}>
              <%= year.name %>
            </.badge>
          </div>
          <%= if class.students != [] do %>
            <ol class="mt-4 text-sm leading-relaxed list-decimal list-inside">
              <li :for={std <- class.students} class="truncate">
                <.link
                  navigate={~p"/school/students/#{std}"}
                  class="hover:text-ltrn-subtle hover:underline"
                >
                  <%= std.name %>
                </.link>
              </li>
            </ol>
          <% else %>
            <.empty_state_simple class="mt-4">
              <%= gettext("No students in this class") %>
            </.empty_state_simple>
          <% end %>
        </.card_base>
      </.responsive_grid>
      <.live_component
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="school-year-filters-overlay"
        current_user={@current_user}
        title={gettext("Filter classes by year")}
        filter_type={:years}
        navigate={~p"/school/classes"}
      />
      <.live_component
        :if={@class}
        module={ClassFormOverlayComponent}
        id="class-form-overlay"
        class={@class}
        title={@class_form_overlay_title}
        on_cancel={JS.patch(~p"/school/classes")}
        notify_parent
      />
      <.live_component
        :if={@student}
        module={StudentFormOverlayComponent}
        id="student-form-overlay"
        student={@student}
        title={gettext("Create student")}
        on_cancel={JS.patch(~p"/school/classes")}
        notify_parent
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
      |> assign_user_filters([:years])
      |> stream_classes()
      |> assign(:initialized, true)
      |> assign_class()
      |> assign_student()

    {:ok, socket}
  end

  defp stream_classes(%{assigns: %{initialized: false}} = socket) do
    years_ids = socket.assigns.selected_years_ids

    classes =
      Schools.list_user_classes(
        socket.assigns.current_user,
        preload_cycle_years_students: true,
        years_ids: years_ids
      )

    stream(socket, :classes, classes)
  end

  defp stream_classes(socket), do: socket

  defp assign_class(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :class, nil)

  defp assign_class(%{assigns: %{params: %{"create_class" => "true"}}} = socket) do
    class = %Class{
      school_id: socket.assigns.current_user.current_profile.school_id,
      years: [],
      students: []
    }

    socket
    |> assign(:class, class)
    |> assign(:class_form_overlay_title, gettext("Create class"))
  end

  defp assign_class(%{assigns: %{params: %{"edit_class" => class_id}}} = socket) do
    class =
      Schools.get_class(class_id,
        check_permissions_for_user: socket.assigns.current_user,
        preloads: [:years, :students]
      )

    socket
    |> assign(:class, class)
    |> assign(:class_form_overlay_title, gettext("Edit class"))
  end

  defp assign_class(socket), do: assign(socket, :class, nil)

  defp assign_student(%{assigns: %{is_school_manager: false}} = socket),
    do: assign(socket, :student, nil)

  defp assign_student(%{assigns: %{params: %{"create_student" => "true"}}} = socket) do
    student = %Student{
      school_id: socket.assigns.current_user.current_profile.school_id,
      classes: []
    }

    assign(socket, :student, student)
  end

  defp assign_student(socket), do: assign(socket, :student, nil)
end
