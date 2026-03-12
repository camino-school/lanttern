defmodule LantternWeb.GradingScalesLive do
  @moduledoc """
  Live view for managing grading scales with CRUD operations.
  """

  use LantternWeb, :live_view

  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  # page components
  alias __MODULE__.GradingScaleCardComponent
  alias __MODULE__.OrdinalValueFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Grading Scales"))
      |> assign(:selected_scale_id, nil)
      |> assign(:scale, nil)
      |> assign(:changeset, nil)
      |> assign(:ordinal_value, nil)
      |> assign_scales()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "assessment_management" in socket.assigns.current_user.current_profile.permissions

    if has_access do
      socket
    else
      socket
      |> push_navigate(to: ~p"/dashboard", replace: true)
      |> put_flash(:error, gettext("You don't have access to grading scales page"))
    end
  end

  defp assign_scales(socket) do
    scales = Grading.list_scales(preloads: :ordinal_values)

    socket
    |> assign(:scales, scales)
    |> assign(:has_scales, scales != [])
    |> assign(:scales_ids, Enum.map(scales, &"#{&1.id}"))
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case socket.assigns.live_action do
      :show ->
        {:noreply, update_selected_scale_components(socket, id)}

      :edit ->
        scale = Grading.get_scale!(id)
        changeset = Grading.change_scale(scale)
        {:noreply, assign(socket, scale: scale, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    case socket.assigns.live_action do
      :index ->
        socket =
          socket
          |> assign_scales()
          |> update_selected_scale_components(nil)

        {:noreply, socket}

      :new ->
        changeset = Grading.change_scale(%Scale{})
        {:noreply, assign(socket, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  defp update_selected_scale_components(socket, new_id) do
    prev_id = socket.assigns.selected_scale_id

    selected_scale_id =
      if new_id && new_id in socket.assigns.scales_ids, do: new_id, else: nil

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

  @impl Phoenix.LiveView
  def handle_event("new_scale", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales/new")}
  end

  def handle_event("close_scale_form", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales")}
  end

  def handle_event("close_ordinal_value_form", _params, socket) do
    {:noreply, assign(socket, :ordinal_value, nil)}
  end

  @impl Phoenix.LiveView
  def handle_info({GradingScaleCardComponent, {:edit_scale, id}}, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales/#{id}/edit")}
  end

  def handle_info({GradingScaleCardComponent, {:delete_scale, id}}, socket) do
    scale = Grading.get_scale!(id)
    {:ok, _} = Grading.delete_scale(scale)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Scale deleted successfully."))
     |> assign_scales()
     |> assign(:selected_scale_id, nil)}
  end

  def handle_info({GradingScaleCardComponent, {:edit_ordinal_value, id}}, socket) do
    ordinal_value = Grading.get_ordinal_value!(id)
    {:noreply, assign(socket, :ordinal_value, ordinal_value)}
  end

  def handle_info({GradingScaleCardComponent, {:new_ordinal_value, scale_id}}, socket) do
    ordinal_value = %OrdinalValue{scale_id: scale_id}
    {:noreply, assign(socket, :ordinal_value, ordinal_value)}
  end

  def handle_info({OrdinalValueFormComponent, {:saved, _ordinal_value}}, socket) do
    {:noreply,
     socket
     |> assign(:ordinal_value, nil)
     |> assign_scales()}
  end
end
