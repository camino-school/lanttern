defmodule LantternWeb.MomentQuizzesLive.Index do
  use LantternWeb, :live_view

  alias Lanttern.Quizzes
  alias Lanttern.Quizzes.Quiz

  # page components
  alias LantternWeb.MomentPageComponent

  # shared components
  alias LantternWeb.Quizzes.QuizFormComponent
  import LantternWeb.QuizzesComponents

  # lifecycle

  on_mount MomentPageComponent

  @impl true
  def mount(params, _session, socket) do
    base_path = ~p"/strands/moment/#{socket.assigns.moment}/quizzes"

    socket =
      socket
      |> assign(:base_path, base_path)
      |> assign(:quiz, nil)
      |> assign(:select_classes_overlay_title, gettext("Select class"))
      |> assign(:select_classes_overlay_navigate, base_path)
      |> stream_quizzes(params)

    {:ok, socket}
  end

  defp stream_quizzes(socket, %{"id" => moment_id}) do
    quizzes = Quizzes.list_quizzes(moment_id: moment_id)

    socket
    |> stream(:quizzes, quizzes)
    |> assign(:quizzes_ids, Enum.map(quizzes, &"#{&1.id}"))
  end

  # handle params

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Quizzes")
    |> assign(:quiz, nil)
  end

  defp apply_action(socket, :new, params) do
    quiz = %Quiz{moment_id: params["id"]}

    socket
    |> assign(:page_title, "New quiz")
    |> assign(:quiz, quiz)
  end

  defp apply_action(socket, :edit, params) do
    quiz_id = params["quiz_id"]

    quiz =
      if quiz_id in socket.assigns.quizzes_ids,
        do: Quizzes.get_quiz(quiz_id),
        else: nil

    socket
    |> assign(:page_title, "Edit quiz")
    |> assign(:quiz, quiz)
  end

  # event handlers

  @impl true
  def handle_event("delete_quiz", %{"id" => id}, socket) do
    with true <- "#{id}" in socket.assigns.quizzes_ids,
         %Quiz{} = quiz <- Quizzes.get_quiz(id),
         {:ok, _quiz} <- Quizzes.delete_quiz(quiz) do
      socket =
        socket
        |> push_navigate(to: socket.assigns.base_path)
        |> put_flash(:info, gettext("Quiz deleted successfully"))

      {:noreply, socket}
    else
      _ ->
        {:noreply, socket}
    end
  end

  # info handlers

  @impl true
  def handle_info({QuizFormComponent, {action, _quiz}}, socket)
      when action in [:created, :updated] do
    msg =
      case action do
        :created -> gettext("Quiz created successfully")
        :updated -> gettext("Quiz updated successfully")
      end

    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)
      |> put_flash(:info, msg)

    {:noreply, socket}
  end
end
