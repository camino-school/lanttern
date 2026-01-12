defmodule LantternWeb.LessonTemplates.LessonTemplateFormComponent do
  @moduledoc """
  Renders a `LessonTemplate` form
  """

  use LantternWeb, :live_component

  alias Lanttern.LessonTemplates

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Template name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.error_block
          :if={@has_delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{gettext("Something went wrong when trying to delete the lesson template")}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@lesson_template.id}
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
      |> assign(:has_delete_error, false)

    {:ok, socket}
  end

  @impl true
  def update(%{lesson_template: lesson_template} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(
        LessonTemplates.change_lesson_template(assigns.current_scope, lesson_template)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"lesson_template" => lesson_template_params}, socket) do
    changeset =
      LessonTemplates.change_lesson_template(
        socket.assigns.current_scope,
        socket.assigns.lesson_template,
        lesson_template_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case LessonTemplates.delete_lesson_template(
             socket.assigns.current_scope,
             socket.assigns.lesson_template
           ) do
        {:ok, lesson_template} ->
          message = {:deleted, lesson_template}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Lesson template deleted"))
          |> handle_navigation(message)

        {:error, _changeset} ->
          assign(socket, :has_delete_error, true)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :has_delete_error, false)}

  def handle_event("save", %{"lesson_template" => lesson_template_params}, socket) do
    save_lesson_template(socket, socket.assigns.lesson_template.id, lesson_template_params)
  end

  defp save_lesson_template(socket, nil, lesson_template_params) do
    case LessonTemplates.create_lesson_template(
           socket.assigns.current_scope,
           lesson_template_params
         ) do
      {:ok, lesson_template} ->
        message = {:created, lesson_template}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Lesson template created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_lesson_template(socket, _id, lesson_template_params) do
    case LessonTemplates.update_lesson_template(
           socket.assigns.current_scope,
           socket.assigns.lesson_template,
           lesson_template_params
         ) do
      {:ok, lesson_template} ->
        message = {:updated, lesson_template}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Lesson template updated"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
