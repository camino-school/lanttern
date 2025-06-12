defmodule LantternWeb.MomentQuizzesLive.Show do
  use LantternWeb, :live_view

  alias Lanttern.Quizzes
  alias Lanttern.Quizzes.QuizItem

  # page components
  alias LantternWeb.MomentPageComponent

  # shared components
  alias LantternWeb.Quizzes.QuizFormComponent
  alias LantternWeb.Quizzes.QuizItemFormComponent
  import LantternWeb.QuizzesComponents

  # lifecycle

  on_mount MomentPageComponent

  @impl true
  def mount(params, _session, socket) do
    base_path =
      ~p"/strands/moment/#{socket.assigns.moment}/quizzes/#{params["quiz_id"]}"

    socket =
      socket
      |> assign(:base_path, base_path)
      |> assign(:select_classes_overlay_title, gettext("Select class"))
      |> assign(:select_classes_overlay_navigate, base_path)
      |> assign_quiz(params)
      |> stream_quiz_items()

    {:ok, socket}
  end

  defp assign_quiz(socket, %{"quiz_id" => quiz_id}) do
    quiz = Quizzes.get_quiz(quiz_id)

    socket
    |> assign(:quiz, quiz)
  end

  defp stream_quiz_items(%{assigns: %{quiz: %{id: quiz_id}}} = socket) do
    quiz_items = Quizzes.list_quiz_items(quiz_id: quiz_id)

    socket
    |> stream(:quiz_items, quiz_items)
    |> assign(:quiz_items_ids, Enum.map(quiz_items, &"#{&1.id}"))
    |> assign(:quiz_items_count, length(quiz_items))
  end

  defp stream_quiz_items(socket), do: socket

  # handle params

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> assign(:quiz_item, nil)
      |> assign(:sortable_quiz_items, [])
      |> assign(:is_sorted, false)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "Quiz detail")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit quiz")
  end

  defp apply_action(socket, :new_quiz_item, params) do
    quiz_item = %QuizItem{quiz_id: params["quiz_id"]}

    socket
    |> assign(:page_title, "New quiz item")
    |> assign(:quiz_item, quiz_item)
  end

  defp apply_action(socket, :edit_quiz_item, params) do
    quiz_item_id = params["quiz_item_id"]

    quiz_item =
      if quiz_item_id in socket.assigns.quiz_items_ids,
        do: Quizzes.get_quiz_item(quiz_item_id),
        else: nil

    socket
    |> assign(:page_title, "Edit quiz item")
    |> assign(:quiz_item, quiz_item)
  end

  defp apply_action(socket, :sort_quiz_items, %{"quiz_id" => quiz_id}) do
    quiz_items = Quizzes.list_quiz_items(quiz_id: quiz_id)

    socket
    |> assign(:sortable_quiz_items, quiz_items)
    |> assign(:sortable_quiz_items_ids, Enum.map(quiz_items, & &1.id))
  end

  # event handlers

  @impl true
  def handle_event("delete_quiz", _, socket) do
    case Quizzes.delete_quiz(socket.assigns.quiz) do
      {:ok, _quiz} ->
        socket =
          socket
          |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}/quizzes")
          |> put_flash(:info, gettext("Quiz deleted successfully"))

        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("delete_quiz_item", %{"id" => id}, socket) do
    with true <- "#{id}" in socket.assigns.quiz_items_ids,
         %QuizItem{} = quiz_item <- Quizzes.get_quiz_item(id),
         {:ok, _quiz_item} <- Quizzes.delete_quiz_item(quiz_item) do
      socket =
        socket
        |> push_navigate(to: socket.assigns.base_path)
        |> put_flash(:info, gettext("Quiz item deleted successfully"))

      {:noreply, socket}
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("sortable_update", %{"groupId" => "quiz-items"} = payload, socket) do
    %{"oldIndex" => old_index, "newIndex" => new_index} = payload
    quiz_items_ids = socket.assigns.sortable_quiz_items_ids
    {changed_id, rest} = List.pop_at(quiz_items_ids, old_index)
    quiz_items_ids = List.insert_at(rest, new_index, changed_id)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    Quizzes.update_quiz_items_positions(quiz_items_ids)

    socket =
      socket
      |> assign(:sortable_quiz_items_ids, quiz_items_ids)
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
  def handle_info({QuizFormComponent, {:updated, _quiz}}, socket) do
    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)
      |> put_flash(:info, gettext("Quiz updated successfully"))

    {:noreply, socket}
  end

  def handle_info({QuizItemFormComponent, {:created, _quiz_item}}, socket) do
    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)
      |> put_flash(:info, gettext("Quiz item created successfully"))

    {:noreply, socket}
  end

  def handle_info({QuizItemFormComponent, {:updated, _quiz_item}}, socket) do
    socket =
      socket
      |> push_navigate(to: socket.assigns.base_path)
      |> put_flash(:info, gettext("Quiz item updated successfully"))

    {:noreply, socket}
  end
end
