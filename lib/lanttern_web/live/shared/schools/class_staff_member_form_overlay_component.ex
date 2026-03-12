defmodule LantternWeb.Schools.ClassStaffMemberFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `ClassStaffMember` edit form

  ### Attrs

      attr :class_staff_member, ClassStaffMember, required: true, doc: "requires class preloaded"
      attr :current_scope, :map, required: true
      attr :on_cancel, JS, required: true
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id={@id}
        show
        on_cancel={@on_cancel}
      >
        <:title>{gettext("Edit class link")}</:title>
        <.form
          for={@form}
          phx-submit="save"
          phx-target={@myself}
        >
          <.input
            field={@form[:role]}
            label={gettext("Teacher role in %{class}", class: @class_staff_member.class.name)}
            placeholder={gettext("e.g., Lead Teacher, Assistant, etc.")}
            phx-debounce="blur"
          />
          <.input type="hidden" field={@form[:id]} />
          <div class="flex gap-4 mt-6 justify-between">
            <.button
              type="button"
              phx-click={JS.push("unlink", target: @myself)}
              theme="ghost"
              data-confirm={gettext("Are you sure?")}
            >
              {gettext("Unlink")}
            </.button>
            <div class="flex gap-2">
              <.button
                type="button"
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                theme="ghost"
              >
                {gettext("Cancel")}
              </.button>
              <.button type="submit">{gettext("Save")}</.button>
            </div>
          </div>
        </.form>
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()

    {:ok, socket}
  end

  defp assign_form(socket) do
    form =
      socket.assigns.class_staff_member
      |> Ecto.Changeset.change(%{})
      |> to_form()

    assign(socket, :form, form)
  end

  # event handlers

  @impl true
  def handle_event("save", %{"class_staff_member" => params}, socket) do
    case Schools.update_class_staff_member(
           socket.assigns.current_scope,
           socket.assigns.class_staff_member,
           params
         ) do
      {:ok, updated_csm} ->
        updated_csm =
          Schools.get_class_staff_member!(
            socket.assigns.current_scope,
            updated_csm.id,
            preloads: [class: [:cycle]]
          )

        notify(__MODULE__, {:updated, updated_csm}, socket.assigns)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("unlink", _params, socket) do
    case Schools.delete_class_staff_member(
           socket.assigns.current_scope,
           socket.assigns.class_staff_member
         ) do
      {:ok, csm} ->
        notify(__MODULE__, {:deleted, csm}, socket.assigns)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to remove from class"))}
    end
  end
end
