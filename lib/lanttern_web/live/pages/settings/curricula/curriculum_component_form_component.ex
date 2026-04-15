defmodule LantternWeb.CurriculaSettingsLive.CurriculumComponentFormComponent do
  @moduledoc """
  Form component for creating and editing curriculum components within a curriculum.
  """

  use LantternWeb, :live_component

  alias Lanttern.Curricula
  alias Lanttern.Curricula.CurriculumComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <div class="flex items-start gap-4 mb-6">
          <.input field={@form[:name]} type="text" label={gettext("Name")} class="flex-2" />
          <.input field={@form[:code]} type="text" label={gettext("Code")} class="flex-1" />
        </div>
        <.input field={@form[:curriculum_id]} type="hidden" />
        <div class="flex gap-4 mb-6">
          <.input
            field={@form[:bg_color]}
            type="color"
            label={gettext("Background color")}
            class="flex-1"
          />
          <.input
            field={@form[:text_color]}
            type="color"
            label={gettext("Text color")}
            class="flex-1"
          />
        </div>
        <.card_base class="flex items-center gap-2 p-6 mb-6">
          <p class="text-ltrn-subtle">{gettext("Preview")}</p>
          <.badge color_map={
            %{bg_color: @form[:bg_color].value, text_color: @form[:text_color].value}
          }>
            {@form[:name].value}
          </.badge>
        </.card_base>
        <.error_block
          :if={@delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{@delete_error}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@curriculum_component.id}
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
  def update(%{curriculum_component: curriculum_component} = assigns, socket) do
    changeset =
      Curricula.change_curriculum_component(assigns.current_scope, curriculum_component)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"curriculum_component" => params}, socket) do
    changeset =
      Curricula.change_curriculum_component(
        socket.assigns.current_scope,
        socket.assigns.curriculum_component,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Curricula.delete_curriculum_component(
             socket.assigns.current_scope,
             socket.assigns.curriculum_component
           ) do
        {:ok, curriculum_component} ->
          message = {:deleted, curriculum_component}

          notify(__MODULE__, message, socket.assigns)

          socket
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

  def handle_event("save", %{"curriculum_component" => params}, socket) do
    save(socket, socket.assigns.curriculum_component, params)
  end

  defp save(socket, %CurriculumComponent{id: nil}, params) do
    case Curricula.create_curriculum_component(socket.assigns.current_scope, params) do
      {:ok, curriculum_component} ->
        message = {:created, curriculum_component}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save(socket, %CurriculumComponent{} = curriculum_component, params) do
    case Curricula.update_curriculum_component(
           socket.assigns.current_scope,
           curriculum_component,
           params
         ) do
      {:ok, curriculum_component} ->
        message = {:updated, curriculum_component}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
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
