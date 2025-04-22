defmodule LantternWeb.ClassLive do
  use LantternWeb, :live_view

  alias Lanttern.Schools
  alias Lanttern.Schools.Class

  # page components

  alias __MODULE__.ILPComponent
  alias __MODULE__.StudentsComponent
  # alias __MODULE__.StudentRecordsComponent

  # shared components

  alias LantternWeb.Schools.ClassFormOverlayComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_class(params)
      |> assign_is_school_manager()

    {:ok, socket}
  end

  defp assign_class(socket, params) do
    case Schools.get_class(params["id"], preloads: [:school, :cycle, :years]) do
      %Class{} = class ->
        check_if_user_has_access(socket.assigns.current_user, class)

        socket
        |> assign(:class, class)
        |> assign(:page_title, class.name)

      _ ->
        raise(LantternWeb.NotFoundError)
    end
  end

  # check if user can view the class page
  # staff members can view only classes from their school
  defp check_if_user_has_access(current_user, class) do
    if class.school_id != current_user.current_profile.school_id,
      do: raise(LantternWeb.NotFoundError)
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:params, params)
      |> assign_is_editing(params)

    {:noreply, socket}
  end

  defp assign_is_editing(%{assigns: %{is_school_manager: true}} = socket, %{"edit" => "true"}) do
    # maybe preload students
    socket =
      if is_list(socket.assigns.class.students) do
        socket
      else
        class =
          socket.assigns.class
          |> Lanttern.Repo.preload(:students)

        assign(socket, :class, class)
      end

    assign(socket, :is_editing, true)
  end

  defp assign_is_editing(socket, _params),
    do: assign(socket, :is_editing, false)

  @impl true
  def handle_info({ClassFormOverlayComponent, {:updated, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class updated successfully"))
      |> push_navigate(to: socket.assigns.current_path)

    {:noreply, socket}
  end

  def handle_info({ClassFormOverlayComponent, {:deleted, _class}}, socket) do
    socket =
      socket
      |> put_flash(:info, gettext("Class deleted successfully"))
      |> push_navigate(to: ~p"/school/classes")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
