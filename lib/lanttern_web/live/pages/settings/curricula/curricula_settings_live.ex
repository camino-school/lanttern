defmodule LantternWeb.CurriculaSettingsLive do
  @moduledoc """
  Live view for managing curricula with CRUD operations.
  """

  use LantternWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias Lanttern.Curricula
  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Identity.Scope

  # page components
  alias __MODULE__.CurriculumCardComponent
  alias __MODULE__.CurriculumComponentFormComponent

  # shared components
  alias LantternWeb.Curricula.CurriculumFormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Curricula"))
      |> assign(:curriculum, nil)
      |> assign(:selected_curriculum_id, nil)
      |> assign(:curriculum_component, nil)
      |> assign_curricula()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    if Scope.has_permission?(socket.assigns.current_scope, "curriculum_management"),
      do: socket,
      else: raise(LantternWeb.NotFoundError)
  end

  defp assign_curricula(socket) do
    curricula =
      Curricula.list_curricula(
        socket.assigns.current_scope,
        preloads: [
          curriculum_components: from(cc in CurriculumComponent, order_by: cc.position)
        ]
      )

    active_curricula = Enum.filter(curricula, &is_nil(&1.deactivated_at))
    deactivated_curricula = Enum.filter(curricula, &(!is_nil(&1.deactivated_at)))

    socket
    |> assign(:curricula_ids, Enum.map(curricula, &"#{&1.id}"))
    |> assign(:active_curricula, active_curricula)
    |> assign(:deactivated_curricula, deactivated_curricula)
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, update_selected_curriculum_components(socket, params)}

  defp update_selected_curriculum_components(socket, params) do
    prev_id = socket.assigns.selected_curriculum_id

    selected_curriculum_id =
      case params do
        %{"id" => id} -> if id in socket.assigns.curricula_ids, do: id, else: nil
        _ -> nil
      end

    ids_to_update =
      [prev_id, selected_curriculum_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    Enum.each(ids_to_update, fn id ->
      send_update(CurriculumCardComponent,
        id: "curricula-#{id}",
        selected_curriculum_id: selected_curriculum_id
      )
    end)

    assign(socket, :selected_curriculum_id, selected_curriculum_id)
  end

  @impl true
  def handle_event("new_curriculum", _params, socket) do
    {:noreply, assign(socket, :curriculum, %Curriculum{})}
  end

  def handle_event("close_curriculum_form", _params, socket),
    do: {:noreply, assign(socket, :curriculum, nil)}

  def handle_event("close_curriculum_component_form", _params, socket) do
    {:noreply, assign(socket, :curriculum_component, nil)}
  end

  @impl true
  def handle_info({CurriculumCardComponent, {:edit_curriculum, id}}, socket) do
    socket =
      if "#{id}" in socket.assigns.curricula_ids do
        curriculum = Curricula.get_curriculum!(socket.assigns.current_scope, id)

        assign(socket, :curriculum, curriculum)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({CurriculumCardComponent, {:edit_curriculum_component, id}}, socket) do
    curriculum_component =
      Curricula.get_curriculum_component!(socket.assigns.current_scope, id)

    {:noreply, assign(socket, :curriculum_component, curriculum_component)}
  end

  def handle_info({CurriculumCardComponent, {:new_curriculum_component, curriculum_id}}, socket) do
    curriculum_component = %CurriculumComponent{curriculum_id: curriculum_id}
    {:noreply, assign(socket, :curriculum_component, curriculum_component)}
  end

  def handle_info({CurriculumComponentFormComponent, {action, _curriculum_component}}, socket) do
    message =
      case action do
        :created -> gettext("Component created")
        :updated -> gettext("Component updated")
        :deleted -> gettext("Component deleted")
      end

    socket =
      socket
      |> assign(:curriculum_component, nil)
      |> assign_curricula()
      |> put_flash(:info, message)

    {:noreply, socket}
  end

  def handle_info({CurriculumCardComponent, {:reorder_curriculum_components, ids}}, socket) do
    Curricula.update_curriculum_component_positions(socket.assigns.current_scope, ids)
    {:noreply, socket}
  end

  def handle_info({CurriculumCardComponent, {:activate_curriculum, id}}, socket) do
    curriculum = Curricula.get_curriculum!(socket.assigns.current_scope, id)
    {:ok, _} = Curricula.activate_curriculum(socket.assigns.current_scope, curriculum)

    socket =
      socket
      |> put_flash(:info, gettext("Curriculum reactivated"))
      |> assign_curricula()

    {:noreply, socket}
  end

  def handle_info({CurriculumCardComponent, {:deactivate_curriculum, id}}, socket) do
    curriculum = Curricula.get_curriculum!(socket.assigns.current_scope, id)
    {:ok, _} = Curricula.deactivate_curriculum(socket.assigns.current_scope, curriculum)

    socket =
      socket
      |> put_flash(:info, gettext("Curriculum deactivated"))
      |> assign_curricula()

    {:noreply, socket}
  end
end
