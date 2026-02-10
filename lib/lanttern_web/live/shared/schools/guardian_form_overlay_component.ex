defmodule LantternWeb.Schools.GuardianFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Guardian` form

  ### Attrs

      attr :guardian, Guardian, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
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
            onclick="return confirm('Are you sure?')"
          >
            {gettext("Delete")}
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="ghost"
            phx-click={JS.exec("phx-remove", to: "##{@id}")}
          >
            {gettext("Cancel")}
          </.action>
          <.action
            type="button"
            theme="primary"
            phx-click={JS.push("save", target: ~s(#guardian-form))}
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
    changeset = Schools.change_guardian(guardian)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"guardian" => params}, socket) do
    changeset =
      socket.assigns.guardian
      |> Schools.change_guardian(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", _params, socket) do
    save_guardian(socket, socket.assigns.guardian.id)
  end

  def handle_event("delete", _params, socket) do
    case Schools.delete_guardian(socket.assigns.guardian) do
      {:ok, guardian} ->
        notify_parent(socket, {:deleted, guardian})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp save_guardian(socket, nil) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset)

    case Schools.create_guardian(params) do
      {:ok, guardian} ->
        notify_parent(socket, {:created, guardian})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_guardian(socket, _id) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset)

    case Schools.update_guardian(socket.assigns.guardian, params) do
      {:ok, guardian} ->
        notify_parent(socket, {:updated, guardian})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp changeset_to_params(changeset) do
    data = changeset.data

    %{
      name: Ecto.Changeset.get_field(changeset, :name, data.name),
      school_id: Ecto.Changeset.get_field(changeset, :school_id, data.school_id)
    }
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(socket, msg) do
    send_update(socket.assigns.notify_component, action: {__MODULE__, msg})
  end
end
