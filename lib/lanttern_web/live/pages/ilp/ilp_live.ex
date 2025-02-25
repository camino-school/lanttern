defmodule LantternWeb.ILPLive do
  use LantternWeb, :live_view

  alias Lanttern.ILP
  alias Lanttern.ILP.StudentILP

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, save_profile_filters: 2]

  # shared components
  alias LantternWeb.ILP.StudentILPFormOverlayComponent
  alias LantternWeb.Schools.StudentHeaderComponent
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("ILP"))
      |> assign_is_school_manager()
      |> assign_templates()
      |> assign_user_filters([:ilp_template, :student])
      |> assign_current_template()
      |> assign_student_ilp()
      |> assign(:is_creating, false)
      |> assign(:is_editing, false)
      |> assign(:ilp_form_overlay_title, nil)

    {:ok, socket}
  end

  defp assign_is_school_manager(socket) do
    is_school_manager =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    assign(socket, :is_school_manager, is_school_manager)
  end

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
    {template_id, template_name} =
      case socket.assigns.templates_ids do
        [] ->
          {nil, nil}

        [id | _] ->
          socket.assigns.template_options
          |> Enum.find({nil, nil}, fn {opt_id, _} -> opt_id == id end)
      end

    if template_id do
      socket
      |> assign(:current_template, template_name)
      |> assign(:selected_ilp_template_id, template_id)
      |> save_profile_filters([:ilp_template])
    else
      assign(socket, :current_template, nil)
    end
  end

  # when user has selected ilp_template, validate access before loading it
  defp assign_current_template(socket) do
    template_id = socket.assigns.selected_ilp_template_id

    {_id, template_name} =
      socket.assigns.template_options
      |> Enum.find({nil, nil}, fn {opt_id, _} -> opt_id == template_id end)

    socket
    |> assign(:current_template, template_name)
  end

  defp assign_student_ilp(socket) do
    with student_id when not is_nil(student_id) <- socket.assigns.selected_student_id,
         template_id when not is_nil(template_id) <- socket.assigns.selected_ilp_template_id do
      student_ilp =
        ILP.get_student_ilp_by(
          [
            student_id: student_id,
            template_id: template_id,
            cycle_id: socket.assigns.current_user.current_profile.current_school_cycle.id
          ],
          preloads: [template: [sections: :components]]
        )

      socket
      |> assign(:student_ilp, student_ilp)
    else
      _ -> assign(socket, :student_ilp, nil)
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_edit_student_ilp(params)

    {:noreply, socket}
  end

  defp assign_edit_student_ilp(%{assigns: %{student_ilp: nil}} = socket, %{"edit" => "true"}) do
    with student_id when not is_nil(student_id) <- socket.assigns.selected_student_id,
         template_id when not is_nil(template_id) <- socket.assigns.selected_ilp_template_id do
      student_ilp =
        %StudentILP{
          school_id: socket.assigns.current_user.current_profile.school_id,
          student_id: student_id,
          template_id: template_id,
          cycle_id: socket.assigns.current_user.current_profile.current_school_cycle.id
        }

      socket
      |> assign(:edit_student_ilp, student_ilp)
      |> assign(:ilp_form_overlay_title, gettext("Create ILP"))
    else
      _ -> assign(socket, :edit_student_ilp, nil)
    end
  end

  defp assign_edit_student_ilp(%{assigns: %{student_ilp: %StudentILP{}}} = socket, %{
         "edit" => "true"
       }) do
    socket
    |> assign(:edit_student_ilp, socket.assigns.student_ilp)
    |> assign(:ilp_form_overlay_title, gettext("Edit ILP"))
  end

  defp assign_edit_student_ilp(socket, _params),
    do: assign(socket, :edit_student_ilp, nil)

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

  def handle_info({StudentILPFormOverlayComponent, {action, _ilp}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("ILP created successfully")
        :updated -> gettext("ILP updated successfully")
        :deleted -> gettext("ILP deleted successfully")
      end

    socket =
      socket
      |> push_navigate(to: ~p"/ilp")
      |> put_flash(:info, message)

    {:noreply, socket}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
