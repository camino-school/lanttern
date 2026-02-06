defmodule LantternWeb.Lessons.LessonTagFormComponent do
  @moduledoc """
  Renders a `Lessons.Tag` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Lessons

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Lesson tag name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:bg_color]}
          type="text"
          label={gettext("Background color (hex)")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:text_color]}
          type="text"
          label={gettext("Text color (hex)")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.card_base class="p-6 mb-6">
          <p class="mb-4 text-ltrn-subtle">{gettext("Preview")}</p>
          <.badge color_map={
            %{bg_color: @form[:bg_color].value, text_color: @form[:text_color].value}
          }>
            {@form[:name].value}
          </.badge>
        </.card_base>
        <.error_block
          :if={@has_delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{gettext("Something went wrong when trying to delete the lesson tag")}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@lesson_tag.id}
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
  def update(%{lesson_tag: lesson_tag} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(Lessons.change_tag(assigns.current_scope, lesson_tag))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      Lessons.change_tag(
        socket.assigns.current_scope,
        socket.assigns.lesson_tag,
        tag_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Lessons.delete_tag(
             socket.assigns.current_scope,
             socket.assigns.lesson_tag
           ) do
        {:ok, lesson_tag} ->
          message = {:deleted, lesson_tag}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Lesson tag deleted"))
          |> handle_navigation(message)

        {:error, _changeset} ->
          assign(socket, :has_delete_error, true)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :has_delete_error, false)}

  def handle_event("save", %{"tag" => tag_params}, socket) do
    save_lesson_tag(socket, socket.assigns.lesson_tag.id, tag_params)
  end

  defp save_lesson_tag(socket, nil, tag_params) do
    case Lessons.create_tag(
           socket.assigns.current_scope,
           tag_params
         ) do
      {:ok, lesson_tag} ->
        message = {:created, lesson_tag}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Lesson tag created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_lesson_tag(socket, _id, tag_params) do
    case Lessons.update_tag(
           socket.assigns.current_scope,
           socket.assigns.lesson_tag,
           tag_params
         ) do
      {:ok, lesson_tag} ->
        message = {:updated, lesson_tag}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Lesson tag updated"))
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
