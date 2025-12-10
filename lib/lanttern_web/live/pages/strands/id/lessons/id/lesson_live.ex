defmodule LantternWeb.LessonLive do
  use LantternWeb, :live_view

  alias Lanttern.LearningContext
  alias Lanttern.Lessons

  # shared components
  import LantternWeb.LearningContextComponents, only: [mini_strand_card: 1]

  # lifecycle

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign_lesson(params)
      |> assign_strand()

    {:ok, socket}
  end

  defp assign_lesson(socket, %{"id" => id}) do
    Lessons.get_lesson(id, preloads: [:moment, :subjects])
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
      LearningContext.get_strand(socket.assigns.lesson.strand_id, preloads: [:subjects, :years])

    socket
    |> assign(:strand, strand)
  end
end
