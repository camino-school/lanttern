defmodule LantternWeb.SchoolLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2]

  # shared components
  alias LantternWeb.Schools.ClassFormOverlayComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:years])
      |> stream_classes()
      |> assign_is_school_manager()
      |> assign(:page_title, socket.assigns.current_user.current_profile.school_name)

    {:ok, socket}
  end

  defp stream_classes(socket) do
    years_ids = socket.assigns.selected_years_ids

    classes =
      Schools.list_user_classes(
        socket.assigns.current_user,
        preload_cycle_years_students: true,
        years_ids: years_ids
      )

    stream(socket, :classes, classes)
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_class(params)

    {:noreply, socket}
  end

  defp assign_class(%{assigns: %{is_school_manager: false}} = socket, _params),
    do: assign(socket, :class, nil)

  defp assign_class(socket, %{"create_class" => "true"}) do
    class = %Class{
      school_id: socket.assigns.current_user.current_profile.school_id,
      years: [],
      students: []
    }

    socket
    |> assign(:class, class)
    |> assign(:class_form_overlay_title, gettext("Create class"))
  end

  defp assign_class(socket, %{"edit_class" => class_id}) do
    class =
      Schools.get_class(class_id,
        check_permissions_for_user: socket.assigns.current_user,
        preloads: [:years, :students]
      )

    socket
    |> assign(:class, class)
    |> assign(:class_form_overlay_title, gettext("Edit class"))
  end

  defp assign_class(socket, _params), do: assign(socket, :class, nil)

  @impl true
  def handle_info({ClassFormOverlayComponent, {:created, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class created successfully"))
      |> push_navigate(to: ~p"/school")

    {:noreply, socket}
  end

  def handle_info({ClassFormOverlayComponent, {:updated, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class updated successfully"))
      |> push_navigate(to: ~p"/school")

    {:noreply, socket}
  end

  def handle_info({ClassFormOverlayComponent, {:deleted, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class deleted successfully"))
      |> push_navigate(to: ~p"/school")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: socket
end
