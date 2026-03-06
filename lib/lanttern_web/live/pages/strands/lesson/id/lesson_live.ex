defmodule LantternWeb.LessonLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Identity.Scope
  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Lessons

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  alias LantternWeb.Attachments.AttachmentAreaComponent
  alias LantternWeb.LearningContext.MomentDetailsOverlayComponent
  alias LantternWeb.Lessons.LessonFormComponent
  alias LantternWeb.Lessons.LessonsSideNavComponent

  # page components

  attr :id, :string, required: true
  attr :assessment_point, :map, required: true

  defp assessment_point_card(assigns) do
    ~H"""
    <.card_base id={@id} class="flex items-center gap-4 p-6 mt-2">
      <div class="flex-1 space-y-4">
        <button
          type="button"
          phx-click={JS.push("edit_assessment_point", value: %{"id" => @assessment_point.id})}
          class="flex-1 font-bold text-left text-ltrn-darkest hover:text-ltrn-subtle"
        >
          {@assessment_point.name}
        </button>
        <.markdown
          :if={@assessment_point.report_info}
          text={@assessment_point.report_info}
          class="line-clamp-2"
        />
        <div class="flex items-center gap-2">
          <div :if={@assessment_point.rubric_id}>
            <.icon name="hero-view-columns" />
            <.tooltip id={"ap-#{@assessment_point.id}-rubric-tooltip"}>
              {gettext("Uses rubric in assessment")}
            </.tooltip>
          </div>
          <.badge :if={@assessment_point.is_differentiation} theme="diff" class="shrink-0">
            {gettext("Differentiation")}
          </.badge>
          <.badge class="shrink-0">{@assessment_point.scale.name}</.badge>
          <%!-- render curriculum only for moment assessment point --%>
          <div class="flex-1 min-w-0">
            <p class="max-w-sm font-sans text-sm text-ltrn-subtle truncate">
              {@assessment_point.curriculum_item.name}
            </p>
            <.tooltip id={"ap-#{@assessment_point.id}-curriculum-tooltip"}>
              ({@assessment_point.curriculum_item.curriculum_component.name}) {@assessment_point.curriculum_item.name}
            </.tooltip>
          </div>
        </div>
      </div>
      <.button
        type="button"
        theme="ghost"
        phx-click={
          JS.push("unlink_assessment_point", value: %{"assessment_point_id" => @assessment_point.id})
        }
      >
        {gettext("Unlink")}
      </.button>
    </.card_base>
    """
  end

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
      |> assign(:strand_assessment_points, nil)
      |> assign(:unlinking_from_lesson, nil)
      |> assign(:assessment_point, nil)
      |> assign(:assessment_point_overlay_title, nil)
      |> stream_lesson_assessment_points()
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

  defp stream_lesson_assessment_points(socket) do
    lesson_assessment_points =
      Assessments.list_assessment_points(
        lesson_id: socket.assigns.lesson.id,
        preloads: [:scale, curriculum_item: :curriculum_component]
      )

    stream(socket, :lesson_assessment_points, lesson_assessment_points, reset: true)
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

  # -- linked assessment points

  def handle_event("load_strand_assessment_points", _params, socket) do
    socket =
      if is_nil(socket.assigns.strand_assessment_points) do
        moments_ids = Enum.map(socket.assigns.strand.moments, & &1.id)

        assessment_points =
          Assessments.list_assessment_points(moments_ids: moments_ids)
          |> Enum.filter(&(&1.lesson_id != socket.assigns.lesson.id))

        assign(socket, :strand_assessment_points, assessment_points)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("link_assessment_point", %{"assessment_point_id" => ap_id}, socket) do
    ap = Assessments.get_assessment_point!(ap_id)

    socket =
      if ap.lesson_id do
        linked_lesson = Lessons.get_lesson!(ap.lesson_id)

        socket
        |> assign(:unlinking_from_lesson, linked_lesson)
        |> assign(:linking_to_assessment_point, ap)
      else
        update_assessment_point_lesson_link(socket, ap, socket.assigns.lesson.id)
      end

    {:noreply, socket}
  end

  def handle_event("unlink_assessment_point", %{"assessment_point_id" => ap_id}, socket) do
    ap = Assessments.get_assessment_point!(ap_id)
    {:noreply, update_assessment_point_lesson_link(socket, ap, nil)}
  end

  def handle_event("confirm_assessment_point_link", _params, socket) do
    ap = socket.assigns.linking_to_assessment_point
    {:noreply, update_assessment_point_lesson_link(socket, ap, socket.assigns.lesson.id)}
  end

  def handle_event("cancel_assessment_point_link", _params, socket) do
    socket =
      socket
      |> assign(:unlinking_from_lesson, nil)
      |> assign(:linking_to_assessment_point, nil)

    {:noreply, socket}
  end

  # -- assessment point form

  def handle_event("edit_assessment_point", %{"id" => ap_id}, socket) do
    ap = Assessments.get_assessment_point!(ap_id)

    socket =
      socket
      |> assign(:assessment_point, ap)
      |> assign(:assessment_point_overlay_title, gettext("Edit assessment point"))

    {:noreply, socket}
  end

  def handle_event("close_assessment_point_form", _params, socket),
    do: {:noreply, assign(socket, :assessment_point, nil)}

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

  # handle_event helpers

  defp update_assessment_point_lesson_link(socket, ap, lesson_id) do
    case Assessments.update_assessment_point(ap, %{lesson_id: lesson_id}) do
      {:ok, _} ->
        socket
        |> stream_lesson_assessment_points()
        |> assign(:strand_assessment_points, nil)
        |> assign(:unlinking_from_lesson, nil)
        |> assign(:linking_to_assessment_point, nil)

      {:error, _} ->
        error_msg =
          if lesson_id,
            do: gettext("Could not link assessment point"),
            else: gettext("Could not unlink assessment point")

        put_flash(socket, :error, error_msg)
    end
  end

  # info handlers

  @impl true
  def handle_info({AssessmentPointFormOverlayComponent, {:updated, _ap}}, socket) do
    socket =
      socket
      |> stream_lesson_assessment_points()
      |> assign(:assessment_point, nil)
      |> put_flash(:info, gettext("Assessment point updated"))

    {:noreply, socket}
  end

  def handle_info(
        {AssessmentPointFormOverlayComponent, {action, _ap}},
        socket
      )
      when action in [:deleted, :deleted_with_entries] do
    socket =
      socket
      |> stream_lesson_assessment_points()
      |> assign(:assessment_point, nil)
      |> assign(:strand_assessment_points, nil)
      |> put_flash(:info, gettext("Assessment point deleted"))

    {:noreply, socket}
  end
end
