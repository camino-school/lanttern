defmodule LantternWeb.LessonTemplatesLive do
  use LantternWeb, :live_view

  alias Lanttern.LessonTemplates
  alias Lanttern.LessonTemplates.LessonTemplate

  # page components
  alias __MODULE__.LessonTemplateCardComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("Lesson Templates"))
      |> assign(:lesson_template, nil)
      |> assign(:selected_lesson_template_id, nil)
      |> stream_lesson_templates()

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
      |> put_flash(:error, gettext("You don't have access to lesson templates page"))
    end
  end

  defp stream_lesson_templates(socket) do
    lesson_templates = LessonTemplates.list_lesson_templates(socket.assigns.current_scope)

    socket
    |> stream(:lesson_templates, lesson_templates)
    |> assign(:has_lesson_templates, length(lesson_templates) > 0)
    |> assign(:lesson_templates_ids, Enum.map(lesson_templates, &"#{&1.id}"))
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, update_selected_lesson_template_components(socket, params)}

  defp update_selected_lesson_template_components(socket, params) do
    prev_id = socket.assigns.selected_lesson_template_id

    selected_lesson_template_id =
      case params do
        %{"id" => id} -> if id in socket.assigns.lesson_templates_ids, do: id, else: nil
        _ -> nil
      end

    # Re-stream only the lesson templates that need to toggle (previous and current selection)
    ids_to_update =
      [prev_id, selected_lesson_template_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    Enum.each(ids_to_update, fn id ->
      send_update(LessonTemplateCardComponent,
        id: "lesson_templates-#{id}",
        selected_lesson_template_id: selected_lesson_template_id
      )
    end)

    assign(socket, :selected_lesson_template_id, selected_lesson_template_id)
  end

  # event handlers

  @impl true
  def handle_event("new_lesson_template", _params, socket) do
    lesson_template = %LessonTemplate{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket =
      socket
      |> assign(:lesson_template, lesson_template)
      |> assign(:lesson_template_overlay_title, gettext("New lesson template"))

    {:noreply, socket}
  end

  def handle_event("close_lesson_template_form", _params, socket),
    do: {:noreply, assign(socket, :lesson_template, nil)}

  # info handlers

  @impl true
  def handle_info(
        {LessonTemplateCardComponent, {:edit_lesson_template, lesson_template_id}},
        socket
      ) do
    {:noreply, open_lesson_template_form(socket, lesson_template_id)}
  end

  defp open_lesson_template_form(socket, lesson_template_id) do
    if "#{lesson_template_id}" in socket.assigns.lesson_templates_ids do
      lesson_template =
        LessonTemplates.get_lesson_template!(socket.assigns.current_scope, lesson_template_id)

      socket
      |> assign(:lesson_template, lesson_template)
      |> assign(:lesson_template_overlay_title, gettext("Edit lesson template"))
    else
      socket
    end
  end
end
