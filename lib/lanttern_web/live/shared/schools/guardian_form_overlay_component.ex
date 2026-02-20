defmodule LantternWeb.Schools.GuardianFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Guardian` form

  ### Attrs

      attr :guardian, Guardian, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :close_path, :string, required: true, doc: "Path to navigate to after successful save"
      attr :current_user, required: true
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id="guardian-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            {gettext("Oops, something went wrong! Please check the errors below.")}
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
        </.form>
        <:actions_left :if={@guardian.id}>
          <.action
            type="button"
            theme="subtle"
            icon_name="hero-trash-mini"
            phx-click={
              JS.push("delete", target: @myself)
              |> JS.exec("phx-remove", to: "##{@id}")
            }
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="ghost"
            phx-click={@on_cancel}
          >
            {gettext("Cancel")}
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="guardian-form"
          >
            {gettext("Save")}
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def update(%{guardian: guardian} = assigns, socket) do
    changeset = Schools.change_guardian(assigns.current_user.current_profile, guardian)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"guardian" => params}, socket) do
    changeset =
      Schools.change_guardian(socket.assigns.current_user.current_profile, socket.assigns.guardian, params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"guardian" => params}, socket) do
    save_guardian(socket, socket.assigns.guardian.id, params)
  end

  def handle_event("delete", _params, socket) do
    case Schools.delete_guardian(socket.assigns.current_user.current_profile, socket.assigns.guardian) do
      {:ok, guardian} ->
        notify_parent(socket.assigns.notify_component, {:deleted, guardian})
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, gettext("You don't have permission to delete guardians"))}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp save_guardian(socket, nil, params) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset, params)
    scope = socket.assigns.current_user.current_profile

    case Schools.create_guardian(scope, params) do
      {:ok, guardian} ->
        notify_parent(socket.assigns.notify_component, {:created, guardian})
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, :unauthorized} ->
        socket = put_flash(socket, :error, gettext("You don't have permission to create guardians"))
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_guardian(socket, _id, params) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset, params)
    scope = socket.assigns.current_user.current_profile

    case Schools.update_guardian(scope, socket.assigns.guardian, params) do
      {:ok, guardian} ->
        notify_parent(socket.assigns.notify_component, {:updated, guardian})
        {:noreply, push_patch(socket, to: socket.assigns.close_path)}

      {:error, :unauthorized} ->
        socket = put_flash(socket, :error, gettext("You don't have permission to update guardians"))
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp changeset_to_params(%Ecto.Changeset{} = changeset, params) do
    data = changeset.data

    %{
      name: Ecto.Changeset.get_field(changeset, :name, params["name"] || data.name)
    }
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(component_cid, message) do
    send_update(component_cid, action: {__MODULE__, message})
  end
end
