defmodule LantternWeb.StrandReportLessonLive do
  use LantternWeb, :live_view

  alias Lanttern.Attachments
  alias Lanttern.Identity.Scope
  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Lessons
  alias Lanttern.Reporting

  # shared components
  alias LantternWeb.Lessons.LessonsSideNavComponent
  import LantternWeb.AttachmentsComponents, only: [attachments_list: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_student_report_card(params)
      |> check_if_user_has_access()
      |> assign_strand(params)
      |> assign_lesson(params)
      |> assign_attachments()
      |> assign(:moment, nil)
      |> assign_base_path(params)

    {:ok, socket}
  end

  defp assign_student_report_card(socket, params) do
    %{"strand_report_id" => strand_report_id} = params

    student_report_card =
      case params do
        %{"student_report_card_id" => id} ->
          Reporting.get_student_report_card!(id,
            preloads: [
              :student,
              report_card: :school_cycle
            ]
          )

        _ ->
          # don't need to worry with other profile types
          # (handled by :ensure_authenticated_student_or_guardian in router)
          Reporting.get_student_report_card_by_student_and_strand_report(
            socket.assigns.current_scope.student_id,
            strand_report_id,
            preloads: [
              :student,
              report_card: :school_cycle
            ]
          )
      end

    assign(socket, :student_report_card, student_report_card)
  end

  defp check_if_user_has_access(%{assigns: %{student_report_card: nil}} = _socket),
    do: raise(LantternWeb.NotFoundError)

  defp check_if_user_has_access(socket) do
    %{current_scope: current_scope, student_report_card: student_report_card} = socket.assigns
    # check if user can view the student strand report
    # guardian and students can only view their own reports
    # staff members can view only reports from their school

    report_card_student_id = student_report_card.student_id
    report_card_student_school_id = student_report_card.student.school_id

    case current_scope do
      %Scope{profile_type: "guardian", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Scope{profile_type: "student", student_id: student_id}
      when student_id == report_card_student_id ->
        nil

      %Scope{profile_type: "staff", school_id: school_id}
      when school_id == report_card_student_school_id ->
        nil

      _ ->
        raise LantternWeb.NotFoundError
    end

    socket
  end

  defp assign_strand(socket, %{"strand_report_id" => strand_report_id}) do
    Reporting.get_strand_report(
      strand_report_id,
      preloads: [strand: [:subjects, :years]]
    )
    |> case do
      %{strand: %Strand{} = strand} -> assign(socket, :strand, strand)
      _ -> raise(LantternWeb.NotFoundError)
    end
  end

  defp assign_lesson(socket, %{"id" => id}) do
    strand_id = socket.assigns.strand.id

    Lessons.get_lesson(id, preloads: [:moment, :subjects, :tags])
    |> case do
      # prevent access to lessons from different contexts and unpublished lessons
      %{strand_id: lesson_strand_id, is_published: true} = lesson
      when lesson_strand_id == strand_id ->
        socket
        |> assign(:lesson, lesson)
        |> assign(:page_title, lesson.name)

      _ ->
        raise(LantternWeb.NotFoundError)
    end
  end

  defp assign_attachments(socket) do
    attachments =
      Attachments.list_attachments(
        lesson_id: socket.assigns.lesson.id,
        is_teacher_only_resource: false
      )

    assign(socket, :attachments, attachments)
  end

  defp assign_base_path(socket, params) do
    strand_report_id = params["strand_report_id"]

    base_path =
      case Map.get(params, "student_report_card_id") do
        nil ->
          "/strand_report/#{strand_report_id}"

        report_card_id ->
          "/student_report_cards/#{report_card_id}/strand_report/#{strand_report_id}"
      end

    assign(socket, :base_path, base_path)
  end

  # event handlers

  @impl true

  # -- moment details

  def handle_event("view_moment_details", %{"moment_id" => moment_id}, socket) do
    with %Moment{} = moment <- LearningContext.get_moment(moment_id),
         true <- moment.strand_id == socket.assigns.strand.id do
      {:noreply, assign(socket, :moment, moment)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("close_moment_details", _params, socket),
    do: {:noreply, assign(socket, :moment, nil)}
end
