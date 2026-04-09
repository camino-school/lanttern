defmodule LantternWeb.CurriculumComponentLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2]

  # shared components
  alias LantternWeb.Curricula.CurriculumItemFormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:subjects, :years])

    {:ok, socket, temporary_assigns: [curriculum_items: []]}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_new(:curriculum_component, fn ->
        Curricula.get_curriculum_component!(socket.assigns.current_scope, params["id"],
          preloads: :curriculum
        )
      end)
      |> assign_curriculum_items()
      |> assign_show_curriculum_item_form(params)

    component = socket.assigns.curriculum_component
    page_title = "#{component.name} • #{component.curriculum.name}"

    socket =
      socket
      |> assign(:page_title, page_title)

    {:noreply, socket}
  end

  defp assign_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_curriculum_items(
        socket.assigns.current_scope,
        components_ids: [socket.assigns.curriculum_component.id],
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids
      )
      |> Enum.map(&Map.take(&1, [:id, :code, :name, :subjects, :years]))

    socket
    |> assign(:curriculum_items, curriculum_items)
    |> assign(:curriculum_items_count, length(curriculum_items))
  end

  defp assign_show_curriculum_item_form(socket, %{"is_creating_curriculum_item" => "true"}) do
    socket
    |> assign(:curriculum_item, %CurriculumItem{
      curriculum_component_id: socket.assigns.curriculum_component.id,
      subjects: socket.assigns.selected_subjects,
      years: socket.assigns.selected_years
    })
    |> assign(:form_overlay_title, gettext("Add curriculum item"))
    |> assign(:show_curriculum_item_form, true)
  end

  defp assign_show_curriculum_item_form(socket, %{"is_editing_curriculum_item" => id}) do
    curriculum_component_id = socket.assigns.curriculum_component.id

    if String.match?(id, ~r/[0-9]+/) do
      case Curricula.get_curriculum_item(socket.assigns.current_scope, id,
             preloads: [:subjects, :years]
           ) do
        %CurriculumItem{curriculum_component_id: ^curriculum_component_id} = curriculum_item ->
          socket
          |> assign(:form_overlay_title, gettext("Edit curriculum item"))
          |> assign(:curriculum_item, curriculum_item)
          |> assign(:show_curriculum_item_form, true)

        _ ->
          assign(socket, :show_curriculum_item_form, false)
      end
    else
      assign(socket, :show_curriculum_item_form, false)
    end
  end

  defp assign_show_curriculum_item_form(socket, _),
    do: assign(socket, :show_curriculum_item_form, false)

  @impl true
  def handle_event("edit_curriculum_item", %{"id" => id}, socket) do
    patch =
      ~p"/curriculum/component/#{socket.assigns.curriculum_component}?is_editing_curriculum_item=#{id}"

    {:noreply, push_patch(socket, to: patch)}
  end

  def handle_event("delete_curriculum_item", _params, socket) do
    case Curricula.delete_curriculum_item(
           socket.assigns.current_scope,
           socket.assigns.curriculum_item
         ) do
      {:ok, _curriculum_item} ->
        socket =
          socket
          |> put_flash(:info, gettext("Curriculum item deleted"))
          |> push_navigate(to: ~p"/curriculum/component/#{socket.assigns.curriculum_component}")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting curriculum item"))

        {:noreply, socket}
    end
  end
end
