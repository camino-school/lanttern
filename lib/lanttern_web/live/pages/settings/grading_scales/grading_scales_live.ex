defmodule LantternWeb.GradingScalesLive do
  @moduledoc """
  Live view for managing grading scales with CRUD operations.
  """

  use LantternWeb, :live_view

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale
  alias Lanttern.Identity.Scope

  # page components
  alias __MODULE__.GradingScaleCardComponent
  alias __MODULE__.OrdinalValueFormComponent

  # shared components
  alias LantternWeb.Grading.GradingScaleFormComponent

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Grading Scales"))
      |> assign(:scale, nil)
      |> assign(:selected_scale_id, nil)
      |> assign(:ordinal_value, nil)
      |> assign_scales()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    if Scope.has_permission?(socket.assigns.current_scope, "assessment_management"),
      do: socket,
      else: raise(LantternWeb.NotFoundError)
  end

  defp assign_scales(socket) do
    scales = Grading.list_scales(socket.assigns.current_scope, preloads: :ordinal_values)
    active_scales = Enum.filter(scales, &is_nil(&1.deactivated_at))
    deactivated_scales = Enum.filter(scales, &(!is_nil(&1.deactivated_at)))

    socket
    |> assign(:scales_ids, Enum.map(scales, &"#{&1.id}"))
    |> assign(:active_scales, active_scales)
    |> assign(:deactivated_scales, deactivated_scales)
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, update_selected_scale_components(socket, params)}

  defp update_selected_scale_components(socket, params) do
    prev_id = socket.assigns.selected_scale_id

    selected_scale_id =
      case params do
        %{"id" => id} -> if id in socket.assigns.scales_ids, do: id, else: nil
        _ -> nil
      end

    # Re-send update only to the lesson tags that need to toggle (previous and current selection)
    ids_to_update =
      [prev_id, selected_scale_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    Enum.each(ids_to_update, fn id ->
      send_update(GradingScaleCardComponent,
        id: "grading-scales-#{id}",
        selected_scale_id: selected_scale_id
      )
    end)

    assign(socket, :selected_scale_id, selected_scale_id)
  end

  @impl true
  def handle_event("new_scale", params, socket) do
    type = params["type"]
    {:noreply, assign(socket, :scale, %Scale{type: type})}
  end

  def handle_event("close_scale_form", _params, socket),
    do: {:noreply, assign(socket, :scale, nil)}

  def handle_event("close_ordinal_value_form", _params, socket) do
    {:noreply, assign(socket, :ordinal_value, nil)}
  end

  def handle_event("sortable_update", %{"oldIndex" => old_index, "newIndex" => new_index}, socket) do
    active_scales = socket.assigns.active_scales

    {moved_scale, rest} = List.pop_at(active_scales, old_index)
    reordered_scales = List.insert_at(rest, new_index, moved_scale)

    reordered_ids = Enum.map(reordered_scales, & &1.id)
    Grading.update_scale_positions(socket.assigns.current_scope, reordered_ids)

    {:noreply, assign(socket, :active_scales, reordered_scales)}
  end

  @impl true
  def handle_info({GradingScaleCardComponent, {:edit_scale, id}}, socket) do
    socket =
      if "#{id}" in socket.assigns.scales_ids do
        scale = Grading.get_scale!(socket.assigns.current_scope, id)

        assign(socket, :scale, scale)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({GradingScaleCardComponent, {:edit_ordinal_value, id}}, socket) do
    ordinal_value = Grading.get_ordinal_value!(id)
    {:noreply, assign(socket, :ordinal_value, ordinal_value)}
  end

  def handle_info({GradingScaleCardComponent, {:new_ordinal_value, scale_id}}, socket) do
    ordinal_value = %OrdinalValue{scale_id: scale_id}
    {:noreply, assign(socket, :ordinal_value, ordinal_value)}
  end

  def handle_info({OrdinalValueFormComponent, {action, _ordinal_value}}, socket) do
    message =
      case action do
        :created -> gettext("Ordinal value created")
        :updated -> gettext("Ordinal value updated")
        :deleted -> gettext("Ordinal value deleted")
      end

    socket =
      socket
      |> assign(:ordinal_value, nil)
      |> assign_scales()
      |> put_flash(:info, message)

    {:noreply, socket}
  end

  def handle_info({GradingScaleCardComponent, {:activate_scale, id}}, socket) do
    scale = Grading.get_scale!(socket.assigns.current_scope, id)
    {:ok, _} = Grading.activate_scale(socket.assigns.current_scope, scale)

    socket =
      socket
      |> put_flash(:info, gettext("Scale reactivated"))
      |> assign_scales()

    {:noreply, socket}
  end

  def handle_info({GradingScaleCardComponent, {:deactivate_scale, id}}, socket) do
    scale = Grading.get_scale!(socket.assigns.current_scope, id)
    {:ok, _} = Grading.deactivate_scale(socket.assigns.current_scope, scale)

    socket =
      socket
      |> put_flash(:info, gettext("Scale deactivated"))
      |> assign_scales()

    {:noreply, socket}
  end
end
