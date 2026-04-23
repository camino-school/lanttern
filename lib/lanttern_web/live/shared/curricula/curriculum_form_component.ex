defmodule LantternWeb.Curricula.CurriculumFormComponent do
  @moduledoc """
  Form component for creating and editing curricula.
  """

  use LantternWeb, :live_component

  alias Lanttern.Curricula

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Curriculum name")}
          class="mb-6"
          phx-debounce="500"
        />
        <.input
          field={@form[:code]}
          type="text"
          label={gettext("Code")}
          class="mb-6"
          phx-debounce="500"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          class="mb-6"
          phx-debounce="500"
        />
        <.error_block
          :if={@delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{@delete_error}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@curriculum.id}
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
            <.button
              type="button"
              theme="ghost"
              phx-click={@on_cancel}
            >
              {gettext("Cancel")}
            </.button>
            <.button type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:delete_error, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{curriculum: curriculum} = assigns, socket) do
    changeset = Curricula.change_curriculum(assigns.current_scope, curriculum)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"curriculum" => params}, socket) do
    changeset =
      Curricula.change_curriculum(
        socket.assigns.current_scope,
        socket.assigns.curriculum,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Curricula.delete_curriculum(
             socket.assigns.current_scope,
             socket.assigns.curriculum
           ) do
        {:ok, curriculum} ->
          message = {:deleted, curriculum}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Curriculum deleted"))
          |> handle_navigation(message)

        {:error, changeset} ->
          delete_error =
            Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
            |> Enum.map_join(" ", fn {_field, msg} -> msg end)

          assign(socket, :delete_error, delete_error)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :delete_error, nil)}

  def handle_event("save", %{"curriculum" => params}, socket) do
    save(socket, socket.assigns.curriculum.id, params)
  end

  defp save(socket, nil, params) do
    case Curricula.create_curriculum(socket.assigns.current_scope, params) do
      {:ok, curriculum} ->
        message = {:created, curriculum}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Curriculum created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save(socket, _id, params) do
    case Curricula.update_curriculum(
           socket.assigns.current_scope,
           socket.assigns.curriculum,
           params
         ) do
      {:ok, curriculum} ->
        message = {:updated, curriculum}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Curriculum updated"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
