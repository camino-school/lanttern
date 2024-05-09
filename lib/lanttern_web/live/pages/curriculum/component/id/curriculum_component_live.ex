defmodule LantternWeb.CurriculumComponentLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumItem

  import LantternWeb.FiltersHelpers

  # shared components
  alias LantternWeb.Curricula.CurriculumItemFormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign_user_filters([:subjects, :years], socket.assigns.current_user)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign_new(:curriculum_component, fn ->
        Curricula.get_curriculum_component!(params["id"], preloads: :curriculum)
      end)
      |> stream_curriculum_items()
      |> assign_show_curriculum_item_form(params)

    component = socket.assigns.curriculum_component
    page_title = "#{component.name} • #{component.curriculum.name}"

    socket =
      socket
      |> assign(:page_title, page_title)

    {:noreply, socket}
  end

  defp stream_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_curriculum_items(
        components_ids: [socket.assigns.curriculum_component.id],
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids
      )

    socket
    |> stream(
      :curriculum_items,
      curriculum_items,
      reset: true
    )
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
      case Curricula.get_curriculum_item(id, preloads: [:subjects, :years]) do
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
  def handle_event("delete_curriculum_item", _params, socket) do
    case Curricula.delete_curriculum_item(socket.assigns.curriculum_item) do
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
