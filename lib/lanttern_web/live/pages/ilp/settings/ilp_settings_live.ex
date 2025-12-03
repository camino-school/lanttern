defmodule LantternWeb.ILPSettingsLive do
  @moduledoc """
  This view handles the ILP templates creation/editing in a "SPA" way.

  When the user is creating or editing a template, we need to show/place the form
  correctly, at the same time we hide the edit and create buttons to prevent showing
  multiple forms at the same time.

  One of the challenges is that we want to use streams to show the templates list,
  so the control of the internal state is a bit more complex.

  We are currently handling this as follows:

  - every time we have a `@template` assign, we hide the edit and new buttons. The
    new button visibility is straightforward to handle with an `:if` special attribute,
    but we can't use this for the edit buttons because they are in a stream list.
    The current solution is to implement a dynamic class `.is-editing` in the list parent div,
    and hide the edit buttons with a `group-[.is-editing]:hidden` class

  - the new template form component is rendered when `@template` id is `nil`

  - to render the edit form inside the stream list, we need to update the list with
    a `stream_insert`. We use a virtual `is_editing` field in `ILPTemplate` to show the
    edit form (and we need to re-update it when the form is closed)

  """

  use LantternWeb, :live_view

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPTemplate

  import Lanttern.Utils, only: [reorder: 3]

  # shared

  alias LantternWeb.ILP.ILPTemplateFormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      case check_if_user_has_access(socket) do
        {false, socket} ->
          socket

        {true, socket} ->
          socket
          |> assign(:page_title, gettext("ILP settings"))
          |> assign(:template, nil)
          |> stream_templates()
      end

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "ilp_management" in socket.assigns.current_user.current_profile.permissions

    if has_access do
      {true, socket}
    else
      socket =
        socket
        |> push_navigate(to: ~p"/ilp", replace: true)
        |> put_flash(:error, gettext("You don't have access to ILP settings page"))

      {false, socket}
    end
  end

  defp stream_templates(socket) do
    templates =
      ILP.list_ilp_templates(
        school_id: socket.assigns.current_user.current_profile.school_id,
        preloads: [:ai_layer, sections: :components]
      )

    # keep track of sections and components ids order and index for sorting

    # "spec" %{"template_id" => [section_id, ...], ...}
    templates_sections_order_map =
      templates
      |> Enum.map(fn template ->
        sections_ids = Enum.map(template.sections, & &1.id)
        {"#{template.id}", sections_ids}
      end)
      |> Enum.into(%{})

    # "spec" %{"section_id" => [{component_id, index}, ...], ...}
    sections_components_order_map =
      templates
      |> Enum.flat_map(& &1.sections)
      |> Enum.map(fn section ->
        components_ids = Enum.map(section.components, & &1.id)
        {"#{section.id}", components_ids}
      end)
      |> Enum.into(%{})

    socket
    |> stream(:templates, templates)
    |> assign(:templates_ids, Enum.map(templates, & &1.id))
    |> assign(:has_templates, length(templates) > 0)
    |> assign(:templates_sections_order_map, Map.new(templates_sections_order_map))
    |> assign(:sections_components_order_map, Map.new(sections_components_order_map))
  end

  # event handlers

  @impl true
  def handle_event("new", _, socket) do
    template =
      %ILPTemplate{
        school_id: socket.assigns.current_user.current_profile.school_id
      }

    {:noreply, assign(socket, :template, template)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    template =
      if id in socket.assigns.templates_ids,
        do: ILP.get_ilp_template!(id, preloads: [:ai_layer, sections: :components])

    template = Map.put(template, :is_editing, true)

    socket =
      socket
      |> assign(:template, template)
      |> stream_insert(:templates, template)

    {:noreply, socket}
  end

  # view Sortable hook for payload info
  def handle_event(
        "sortable_update",
        %{
          "from" => %{"groupName" => "sections", "templateId" => template_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        } = _payload,
        socket
      )
      when old_index != new_index do
    sections_ids =
      socket.assigns.templates_sections_order_map
      |> Map.get(template_id)

    sections_ids = reorder(sections_ids, old_index, new_index)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    ILP.update_ilp_sections_positions(sections_ids)

    templates_sections_order_map =
      socket.assigns.templates_sections_order_map
      |> Map.put(template_id, sections_ids)

    {:noreply, assign(socket, :templates_sections_order_map, templates_sections_order_map)}
  end

  def handle_event(
        "sortable_update",
        %{
          "from" => %{"groupName" => "components", "sectionId" => section_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        } = _payload,
        socket
      )
      when old_index != new_index do
    components_ids =
      socket.assigns.sections_components_order_map
      |> Map.get(section_id)

    components_ids = reorder(components_ids, old_index, new_index)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    ILP.update_ilp_components_positions(components_ids)

    sections_components_order_map =
      socket.assigns.sections_components_order_map
      |> Map.put(section_id, components_ids)

    {:noreply, assign(socket, :sections_components_order_map, sections_components_order_map)}
  end

  def handle_event("sortable_update", _, socket), do: {:noreply, socket}

  # info handlers

  @impl true
  def handle_info({ILPTemplateFormComponent, :cancel}, socket) do
    socket =
      socket
      |> case do
        %{assigns: %{template: %ILPTemplate{id: id} = template}} when not is_nil(id) ->
          template = %{template | is_editing: nil}
          stream_insert(socket, :templates, template)

        socket ->
          socket
      end
      |> assign(:template, nil)

    {:noreply, socket}
  end

  def handle_info({ILPTemplateFormComponent, {action, _template}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("ILP template created successfully")
        :updated -> gettext("ILP template updated successfully")
        :deleted -> gettext("ILP template deleted successfully")
      end

    socket =
      socket
      |> push_navigate(to: ~p"/ilp/settings")
      |> put_flash(:info, message)

    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}
end
