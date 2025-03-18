defmodule LantternWeb.ILPLive do
  use LantternWeb, :live_view

  alias Lanttern.ILP
  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.ILP.StudentILPComponent
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("ILP"))
      |> assign_is_ilp_manager()
      |> assign_templates()
      |> handle_assign_user_filters(params)
      |> assign_current_template()

    {:ok, socket}
  end

  defp assign_is_ilp_manager(socket) do
    is_ilp_manager =
      "ilp_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_ilp_manager, is_ilp_manager)
  end

  # if there's a valid student_id in params, it should take precedence
  # and overwrite the saved student filter
  defp handle_assign_user_filters(socket, %{"student" => student_id}) do
    user_school_id = socket.assigns.current_user.current_profile.school_id

    case Schools.get_student(student_id) do
      %Student{school_id: school_id} = student when school_id == user_school_id ->
        socket
        |> assign(:selected_student, student)
        |> assign(:selected_student_id, student.id)
        |> save_profile_filters([:student])
        |> assign_user_filters([:ilp_template])

      _ ->
        assign_user_filters(socket, [:ilp_template, :student])
    end
  end

  defp handle_assign_user_filters(socket, _params),
    do: assign_user_filters(socket, [:ilp_template, :student])

  defp assign_templates(socket) do
    templates =
      ILP.list_ilp_templates(school_id: socket.assigns.current_user.current_profile.school_id)

    socket
    |> assign(:has_templates, length(templates) > 0)
    |> assign(:templates_ids, Enum.map(templates, & &1.id))
    |> assign(:template_options, Enum.map(templates, &{&1.id, &1.name}))
  end

  # when user has no selected ilp_template,
  # select first item in templates list as default if possible
  defp assign_current_template(%{assigns: %{selected_ilp_template_id: nil}} = socket) do
    template =
      case socket.assigns.templates_ids do
        [] -> nil
        [id | _] -> ILP.get_ilp_template!(id, preloads: [sections: :components])
      end

    if template do
      socket
      |> assign(:current_template, template)
      |> assign(:selected_ilp_template_id, template.id)
      |> save_profile_filters([:ilp_template])
    else
      assign(socket, :current_template, nil)
    end
  end

  # when user has selected ilp_template, validate access before loading it
  # (in case the selected template is not valid, remove it from profile and refresh the page)
  defp assign_current_template(socket) do
    template_id = socket.assigns.selected_ilp_template_id

    template =
      if template_id in socket.assigns.templates_ids do
        ILP.get_ilp_template!(template_id, preloads: [sections: :components])
      end

    if template do
      assign(socket, :current_template, template)
    else
      socket
      |> assign(:selected_ilp_template_id, nil)
      |> save_profile_filters([:ilp_template])
      |> push_navigate(to: ~p"/ilp")
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(:params, params)

    {:noreply, socket}
  end

  # event handlers

  @impl true
  def handle_event("select_template_id", %{"id" => id}, socket) do
    template =
      if id in socket.assigns.templates_ids do
        ILP.get_ilp_template!(id, preloads: [sections: :components])
      end

    socket =
      socket
      |> assign(:current_template, template)
      |> assign(:selected_ilp_template_id, template && template.id)
      |> save_profile_filters([:ilp_template])
      |> push_navigate(to: ~p"/ilp")

    {:noreply, socket}
  end

  # info handlers

  @impl true
  def handle_info({StudentSearchComponent, {:selected, student}}, socket) do
    socket =
      socket
      |> assign(:selected_student_id, student.id)
      |> save_profile_filters([:student])
      |> push_navigate(to: ~p"/ilp")

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
