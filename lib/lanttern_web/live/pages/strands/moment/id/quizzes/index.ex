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
    |> assign(:quizzes_count, length(quizzes))
  end

  # handle params

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:quiz, nil)
      |> assign(:sortable_quizzes, [])
      |> assign(:is_sorted, false)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Quizzes")
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

  defp apply_action(socket, :sort, %{"id" => moment_id}) do
    quizzes = Quizzes.list_quizzes(moment_id: moment_id)

    socket
    |> assign(:page_title, "Sort quizzes")
    |> assign(:sortable_quizzes, quizzes)
    |> assign(:sortable_quizzes_ids, Enum.map(quizzes, & &1.id))
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

  def handle_event("sortable_update", %{"groupId" => "quizzes"} = payload, socket) do
    %{"oldIndex" => old_index, "newIndex" => new_index} = payload
    quizzes_ids = socket.assigns.sortable_quizzes_ids
    {changed_id, rest} = List.pop_at(quizzes_ids, old_index)
    quizzes_ids = List.insert_at(rest, new_index, changed_id)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    Quizzes.update_quizzes_positions(quizzes_ids)

    socket =
      socket
      |> assign(:sortable_quizzes_ids, quizzes_ids)
      |> assign(:is_sorted, true)

    {:noreply, socket}
  end

  def handle_event("close_sortable", _params, socket) do
    socket =
      case socket.assigns do
        %{is_sorted: true} ->
          push_navigate(socket, to: socket.assigns.base_path)

        _ ->
          push_patch(socket, to: socket.assigns.base_path)
      end

    {:noreply, socket}
  end

  # info handlers

  @impl true
  def handle_info({QuizFormComponent, {:created, quiz}}, socket) do
    socket =
      socket
      |> push_navigate(to: "#{socket.assigns.base_path}/#{quiz.id}")
      |> put_flash(:info, gettext("Quiz created successfully"))

    {:noreply, socket}
  end

  def handle_info({QuizFormComponent, {:updated, _quiz}}, socket) do
    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)
      |> put_flash(:info, gettext("Quiz updated successfully"))

    {:noreply, socket}
  end
end
