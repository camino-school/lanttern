defmodule LantternWeb.GradingScalesLive do
  @moduledoc """
  Live view for managing grading scales with CRUD operations.
  """

  use LantternWeb, :live_view

  alias Lanttern.Grading
  alias Lanttern.Grading.Scale

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    scales = Grading.list_scales()

    {:ok,
     socket
     |> check_if_user_has_access()
     |> assign(:page_title, gettext("Grading Scales"))
     |> assign(:scales, scales)
     |> assign(:changeset, nil)
     |> assign(:scale, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _uri, socket) do
    case socket.assigns.live_action do
      :show ->
        scale = Grading.get_scale!(id)
        {:noreply, assign(socket, scale: scale)}

      :edit ->
        scale = Grading.get_scale!(id)
        changeset = Grading.change_scale(scale)
        {:noreply, assign(socket, scale: scale, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
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

  def handle_params(_params, _uri, socket) do
    case socket.assigns.live_action do
      :index ->
        scales = Grading.list_scales()
        {:noreply, assign(socket, scales: scales)}

      :new ->
        changeset = Grading.change_scale(%Scale{})
        {:noreply, assign(socket, changeset: changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("new_scale", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales/new")}
  end

  def handle_event("edit_scale", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales/#{id}/edit")}
  end

  def handle_event("show_scale", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales/#{id}")}
  end

  def handle_event("close_scale_form", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/settings/grading_scales")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    scale = Grading.get_scale!(id)
    {:ok, _} = Grading.delete_scale(scale)

    scales = Grading.list_scales()

    {:noreply,
     socket
     |> put_flash(:info, "Scale deleted successfully.")
     |> assign(scales: scales)}
  end
end
