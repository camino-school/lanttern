defmodule LantternWeb.LearningContext.MomentFormComponent do
  @moduledoc """
  Renders a `Moment` form

  When `on_cancel` is provided, the form renders its own Delete/Cancel/Save buttons.
  Otherwise (e.g. inside a slide_over with its own `:actions` slot), no buttons are rendered.

  ## Navigation

  After successful save or delete, the component uses `handle_navigation/2` with a tagged tuple:

  - `{:created, moment}` — after creation
  - `{:updated, moment}` — after update
  - `{:deleted, moment}` — after deletion

  The `navigate` (or `patch`) callback receives the tuple and can route accordingly.
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:strand_id]} type="hidden" />
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.error_block :if={@error} role="alert" class="mb-6 text-sm text-ltrn-error">
          {@error}
        </.error_block>
        <div :if={@on_cancel} class="mt-10">
          <div class="flex justify-between gap-2">
            <div>
              <.button
                :if={@form.source.data.id}
                type="button"
                theme="ghost"
                phx-click="delete"
                phx-target={@myself}
                data-confirm={gettext("Are you sure?")}
              >
                {gettext("Delete")}
              </.button>
            </div>
            <div class="flex gap-2">
              <.button type="button" theme="ghost" phx-click={@on_cancel}>
                {gettext("Cancel")}
              </.button>
              <.button type="submit">
                {gettext("Save")}
              </.button>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:on_cancel, nil)
     |> assign(:save_preloads, [])
     |> assign(:error, nil)}
  end

  @impl true
  def update(%{moment: moment} = assigns, socket) do
    changeset = LearningContext.change_moment(moment)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"moment" => moment_params}, socket) do
    changeset =
      socket.assigns.moment
      |> LearningContext.change_moment(moment_params)
      |> Map.put(:action, :validate)

    {:noreply, socket |> assign(:error, nil) |> assign_form(changeset)}
  end

  def handle_event("delete", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, moment} ->
        notify(__MODULE__, {:deleted, moment}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment deleted"))
         |> handle_navigation({:deleted, moment})}

      {:error, _changeset} ->
        {:noreply,
         assign(
           socket,
           :error,
           gettext("Moment has linked assessments. Deleting it would cause some data loss.")
         )}
    end
  end

  def handle_event("save", %{"moment" => moment_params}, socket) do
    save_moment(socket, socket.assigns.moment.id, moment_params)
  end

  defp save_moment(socket, nil, moment_params) do
    case LearningContext.create_moment(moment_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, moment} ->
        notify(__MODULE__, {:created, moment}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment created successfully"))
         |> handle_navigation({:created, moment})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_moment(socket, _id, moment_params) do
    case LearningContext.update_moment(socket.assigns.moment, moment_params,
           preloads: socket.assigns.save_preloads
         ) do
      {:ok, moment} ->
        notify(__MODULE__, {:updated, moment}, socket.assigns)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Moment updated successfully"))
         |> handle_navigation({:updated, moment})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
