defmodule LantternWeb.LessonTagsLive do
  use LantternWeb, :live_view

  alias Lanttern.Lessons
  alias Lanttern.Lessons.Tag

  # page components
  alias __MODULE__.LessonTagCardComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Lesson Tags"))
      |> assign(:lesson_tag, nil)
      |> assign(:selected_lesson_tag_id, nil)
      |> assign_lesson_tags()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "content_management" in socket.assigns.current_user.current_profile.permissions

    if has_access do
      socket
    else
      socket
      |> push_navigate(to: ~p"/dashboard", replace: true)
      |> put_flash(:error, gettext("You don't have access to lesson tags page"))
    end
  end

  defp assign_lesson_tags(socket) do
    lesson_tags = Lessons.list_lesson_tags(socket.assigns.current_scope)

    socket
    |> assign(:lesson_tags, lesson_tags)
    |> assign(:has_lesson_tags, length(lesson_tags) > 0)
    |> assign(:lesson_tags_ids, Enum.map(lesson_tags, &"#{&1.id}"))
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, update_selected_lesson_tag_components(socket, params)}

  defp update_selected_lesson_tag_components(socket, params) do
    prev_id = socket.assigns.selected_lesson_tag_id

    selected_lesson_tag_id =
      case params do
        %{"id" => id} -> if id in socket.assigns.lesson_tags_ids, do: id, else: nil
        _ -> nil
      end

    # Re-send update only to the lesson tags that need to toggle (previous and current selection)
    ids_to_update =
      [prev_id, selected_lesson_tag_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    Enum.each(ids_to_update, fn id ->
      send_update(LessonTagCardComponent,
        id: "lesson-tags-#{id}",
        selected_lesson_tag_id: selected_lesson_tag_id
      )
    end)

    assign(socket, :selected_lesson_tag_id, selected_lesson_tag_id)
  end

  # event handlers

  @impl true
  def handle_event("new_lesson_tag", _params, socket) do
    lesson_tag = %Tag{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket =
      socket
      |> assign(:lesson_tag, lesson_tag)
      |> assign(:lesson_tag_overlay_title, gettext("New lesson tag"))

    {:noreply, socket}
  end

  def handle_event("close_lesson_tag_form", _params, socket),
    do: {:noreply, assign(socket, :lesson_tag, nil)}

  def handle_event("sortable_update", %{"oldIndex" => old_index, "newIndex" => new_index}, socket) do
    lesson_tags = socket.assigns.lesson_tags

    {moved_tag, rest} = List.pop_at(lesson_tags, old_index)
    reordered_tags = List.insert_at(rest, new_index, moved_tag)

    reordered_ids = Enum.map(reordered_tags, & &1.id)
    Lessons.update_lesson_tag_positions(reordered_ids)

    {:noreply, assign(socket, :lesson_tags, reordered_tags)}
  end

  # info handlers

  @impl true
  def handle_info(
        {LessonTagCardComponent, {:edit_lesson_tag, lesson_tag_id}},
        socket
      ) do
    {:noreply, open_lesson_tag_form(socket, lesson_tag_id)}
  end

  defp open_lesson_tag_form(socket, lesson_tag_id) do
    if "#{lesson_tag_id}" in socket.assigns.lesson_tags_ids do
      lesson_tag =
        Lessons.get_tag!(socket.assigns.current_scope, lesson_tag_id)

      socket
      |> assign(:lesson_tag, lesson_tag)
      |> assign(:lesson_tag_overlay_title, gettext("Edit lesson tag"))
    else
      socket
    end
  end
end
