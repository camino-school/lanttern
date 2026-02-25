defmodule LantternWeb.LessonLive do
  use LantternWeb, :live_view

  alias Lanttern.Identity.Scope
  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Lessons

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.LearningContext.MomentDetailsOverlayComponent
  alias LantternWeb.Lessons.LessonFormComponent
  alias LantternWeb.Lessons.LessonsSideNavComponent

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_lesson(params)
      |> assign_strand()
      |> assign(:is_editing, false)
      |> assign(:description_form, nil)
      |> assign(:teacher_notes_form, nil)
      |> assign(:differentiation_form, nil)
      |> assign(:moment_id, nil)
      |> assign(
        :has_agents_management_permission,
        Scope.has_permission?(socket.assigns.current_scope, "agents_management")
      )

    {:ok, socket}
  end

  defp assign_lesson(socket, %{"id" => id}) do
    Lessons.get_lesson(id, preloads: [:moment, :subjects, :tags])
    |> case do
      lesson when is_nil(lesson) ->
        raise(LantternWeb.NotFoundError)

      lesson ->
        socket
        |> assign(:lesson, lesson)
        |> assign(:page_title, lesson.name)
    end
  end

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.lesson.strand_id,
        preloads: [:subjects, :years, :moments]
      )

    socket
    |> assign(:strand, strand)
  end

  # event handlers

  @impl true
  def handle_event("edit", _params, socket),
    do: {:noreply, assign(socket, :is_editing, true)}

  def handle_event("cancel_edit", _params, socket),
    do: {:noreply, assign(socket, :is_editing, false)}

  def handle_event("publish", _params, socket) do
    socket =
      Lessons.update_lesson(socket.assigns.current_scope, socket.assigns.lesson, %{
        is_published: true
      })
      |> case do
        {:ok, lesson} ->
          socket
          |> push_navigate(to: ~p"/strands/lesson/#{lesson}")
          |> put_flash(:info, gettext("Lesson published"))

        # missing description validation
        {:error, %Ecto.Changeset{errors: [description: {error, []}]}} ->
          put_flash(socket, :error, error)

        {:error, _changeset} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end

  def handle_event("unpublish", _params, socket) do
    socket =
      Lessons.update_lesson(socket.assigns.current_scope, socket.assigns.lesson, %{
        is_published: false
      })
      |> case do
        {:ok, lesson} ->
          socket
          |> assign(:lesson, lesson)
          |> put_flash(:info, gettext("Lesson unpublished"))

        {:error, _changeset} ->
          put_flash(socket, :error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end

  # -- description

  def handle_event("edit_description", _params, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson)
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("cancel_description_edit", _params, socket),
    do: {:noreply, assign(socket, :description_form, nil)}

  def handle_event("validate_description", %{"lesson" => params}, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson, params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :description_form, form)}
  end

  def handle_event("save_description", %{"lesson" => params}, socket) do
    case Lessons.update_lesson(socket.assigns.current_scope, socket.assigns.lesson, params) do
      {:ok, lesson} ->
        socket =
          socket
          |> assign(:lesson, lesson)
          |> assign(:description_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :description_form, to_form(changeset))}
    end
  end

  # -- teacher notes

  def handle_event("edit_teacher_notes", _params, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson)
      |> to_form()

    {:noreply, assign(socket, :teacher_notes_form, form)}
  end

  def handle_event("cancel_teacher_notes_edit", _params, socket),
    do: {:noreply, assign(socket, :teacher_notes_form, nil)}

  def handle_event("validate_teacher_notes", %{"lesson" => params}, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson, params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :teacher_notes_form, form)}
  end

  def handle_event("save_teacher_notes", %{"lesson" => params}, socket) do
    case Lessons.update_lesson(socket.assigns.current_scope, socket.assigns.lesson, params) do
      {:ok, lesson} ->
        socket =
          socket
          |> assign(:lesson, lesson)
          |> assign(:teacher_notes_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :teacher_notes_form, to_form(changeset))}
    end
  end

  # -- differentiation

  def handle_event("edit_differentiation", _params, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson)
      |> to_form()

    {:noreply, assign(socket, :differentiation_form, form)}
  end

  def handle_event("cancel_differentiation_edit", _params, socket),
    do: {:noreply, assign(socket, :differentiation_form, nil)}

  def handle_event("validate_differentiation", %{"lesson" => params}, socket) do
    form =
      Lessons.change_lesson(socket.assigns.current_scope, socket.assigns.lesson, params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :differentiation_form, form)}
  end

  def handle_event("save_differentiation", %{"lesson" => params}, socket) do
    case Lessons.update_lesson(socket.assigns.current_scope, socket.assigns.lesson, params) do
      {:ok, lesson} ->
        socket =
          socket
          |> assign(:lesson, lesson)
          |> assign(:differentiation_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :differentiation_form, to_form(changeset))}
    end
  end

  # -- moment details

  def handle_event("view_moment_details", %{"moment_id" => moment_id}, socket) do
    with %Moment{} = moment <- LearningContext.get_moment(moment_id),
         true <- moment.strand_id == socket.assigns.strand.id do
      {:noreply, assign(socket, :moment_id, moment.id)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("close_moment_details", _params, socket),
    do: {:noreply, assign(socket, :moment_id, nil)}
end
