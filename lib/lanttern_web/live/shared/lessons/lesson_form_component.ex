defmodule LantternWeb.Lessons.LessonFormComponent do
  @moduledoc """
  Renders a `Lesson` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Lessons

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id="lesson-form" phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input field={@form[:strand_id]} type="hidden" />

        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Lesson name")}
          class="mb-6"
          phx-debounce="1500"
        />

        <div class="mb-6">
          <.label>{gettext("Moment (optional)")}</.label>
          <p class="text-sm text-ltrn-subtle mb-2">
            {gettext(
              "Select a moment to attach this lesson to, or leave unselected for a strand-level lesson"
            )}
          </p>
          <.badge_button_picker
            items={@moments}
            selected_ids={if @selected_moment_id, do: [@selected_moment_id], else: []}
            on_select={&JS.push("select_moment", value: %{moment_id: &1}, target: @myself)}
          />
        </div>
        <.error_block
          :if={@has_delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{gettext("Something went wrong when trying to delete the lesson")}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@lesson.id}
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
  def update(%{lesson: lesson} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:selected_moment_id, lesson.moment_id)
      |> assign_form(Lessons.change_lesson(lesson))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"lesson" => lesson_params}, socket) do
    changeset =
      socket.assigns.lesson
      |> Lessons.change_lesson(lesson_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("select_moment", %{"moment_id" => moment_id}, socket) do
    # Toggle selection: if already selected, deselect
    selected_moment_id =
      if socket.assigns.selected_moment_id == moment_id,
        do: nil,
        else: moment_id

    {:noreply, assign(socket, :selected_moment_id, selected_moment_id)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Lessons.delete_lesson(socket.assigns.lesson) do
        {:ok, lesson} ->
          socket
          |> put_flash(:info, gettext("Lesson deleted"))
          |> handle_navigation(lesson)

        {:error, _changeset} ->
          # put_flash!(socket, :error, gettext("Something went wrong."))
          assign(socket, :has_delete_error, true)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :has_delete_error, false)}

  def handle_event("save", %{"lesson" => lesson_params}, socket) do
    # Add selected moment_id to params
    lesson_params = Map.put(lesson_params, "moment_id", socket.assigns.selected_moment_id)

    save_lesson(socket, socket.assigns.lesson.id, lesson_params)
  end

  defp save_lesson(socket, nil, lesson_params) do
    case Lessons.create_lesson(lesson_params) do
      {:ok, lesson} ->
        socket =
          socket
          |> put_flash(:info, gettext("Lesson created successfully"))
          |> handle_navigation(lesson)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_lesson(socket, _id, lesson_params) do
    case Lessons.update_lesson(socket.assigns.lesson, lesson_params) do
      {:ok, lesson} ->
        socket =
          socket
          |> put_flash(:info, gettext("Lesson updated successfully"))
          |> handle_navigation(lesson)

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
