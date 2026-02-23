defmodule LantternWeb.LearningContext.MomentDetailsOverlayComponent do
  @moduledoc """
  A live component that renders a moment's details in a modal overlay,
  allowing users to view and edit the moment's description.

  ## Required attributes

  - `id` - Component identifier
  - `moment_id` - The ID of the moment to display
  - `on_cancel` - JS command to execute when the modal is dismissed

  ## Optional attributes

  - `notify_parent` - When `true`, sends notifications to the parent live view
  - `notify_component` - A `Phoenix.LiveComponent.CID` to send notifications to
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal
        id={@id}
        show={true}
        on_cancel={@on_cancel}
      >
        <h1 class="font-display font-black text-2xl">{@moment.name}</h1>
        <section id="moment-description" class="mt-10">
          <.markdown :if={!@description_form && @moment.description} text={@moment.description} />
          <div :if={!@description_form} class="flex gap-4">
            <.button
              :if={!@moment.description}
              phx-click="edit_description"
              phx-target={@myself}
              theme="primary"
              icon_name="hero-plus-mini"
            >
              {gettext("Add description")}
            </.button>
            <.button
              :if={@moment.description}
              phx-click="edit_description"
              phx-target={@myself}
              class="mt-4"
              size="sm"
            >
              {gettext("Edit description")}
            </.button>
          </div>
          <.form
            :if={@description_form}
            for={@description_form}
            phx-submit="save_description"
            phx-change="validate_description"
            phx-target={@myself}
            id="moment-description-form"
          >
            <.input
              field={@description_form[:description]}
              type="markdown"
              label={gettext("Moment description")}
              label_is_sr_only
              phx-debounce="1500"
            />
            <div class="flex justify-end gap-2 mt-2">
              <.button
                type="button"
                theme="ghost"
                phx-click="cancel_description_edit"
                phx-target={@myself}
              >
                {gettext("Cancel")}
              </.button>
              <.button type="submit" theme="primary">{gettext("Save")}</.button>
            </div>
          </.form>
        </section>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:description_form, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_moment()

    {:ok, socket}
  end

  defp assign_moment(%{assigns: %{moment_id: id}} = socket) do
    case LearningContext.get_moment(id) do
      nil ->
        socket
        |> put_flash(:error, gettext("Couldn't find moment"))

      # |> redirect(to: ~p"/strands")

      moment ->
        socket
        |> assign(:moment, moment)
    end
  end

  # event handlers

  @impl true

  # -- description

  def handle_event("edit_description", _params, socket) do
    form =
      socket.assigns.moment
      |> LearningContext.change_moment()
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("cancel_description_edit", _params, socket),
    do: {:noreply, assign(socket, :description_form, nil)}

  def handle_event("validate_description", %{"moment" => params}, socket) do
    form =
      socket.assigns.moment
      |> LearningContext.change_moment(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("save_description", %{"moment" => params}, socket) do
    case LearningContext.update_moment(socket.assigns.moment, params) do
      {:ok, moment} ->
        notify(__MODULE__, {:updated, moment}, socket.assigns)

        socket =
          socket
          |> assign(:moment, moment)
          |> assign(:description_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :description_form, to_form(changeset))}
    end
  end
end
