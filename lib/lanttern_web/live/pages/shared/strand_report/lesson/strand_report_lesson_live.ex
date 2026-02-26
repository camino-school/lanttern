defmodule LantternWeb.StrandReportLessonLive do
  use LantternWeb, :live_view

  alias Lanttern.Attachments
  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Lessons

  # shared components
  alias LantternWeb.Lessons.LessonsSideNavComponent
  import LantternWeb.AttachmentsComponents, only: [attachments_list: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_lesson(params)
      |> assign_attachments()
      |> assign_strand()
      |> assign(:moment, nil)
      |> assign_base_path(params)

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

  defp assign_attachments(socket) do
    attachments =
      Attachments.list_attachments(
        lesson_id: socket.assigns.lesson.id,
        is_teacher_only_resource: false
      )

    assign(socket, :attachments, attachments)
  end

  defp assign_strand(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.lesson.strand_id,
        preloads: [:subjects, :years, :moments]
      )

    socket
    |> assign(:strand, strand)
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
