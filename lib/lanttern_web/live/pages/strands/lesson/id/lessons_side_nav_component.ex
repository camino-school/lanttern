defmodule LantternWeb.LessonLive.LessonsSideNavComponent do
  @moduledoc """
  A live component that renders a side navigation listing all lessons in a
  strand, grouped by moment, with drag-and-drop reordering support.

  ## Attributes

  Required:

    * `id` - Component identifier
    * `strand_id` - The strand whose lessons and moments to display
    * `lesson_id` - The currently active lesson ID (used for visual highlighting)
    * `current_scope` - The current user scope for authorization

  ## Streams

  This component manages multiple streams internally:

    * `:unattached_lessons` - Lessons not associated with any moment
    * `:moments` - The strand's moments in order
    * `"moment_{id}_lessons"` - Dynamic per-moment lesson streams

  ## Drag-and-drop

  Uses the `Sortable` JS hook to support:

    * Reordering moments within the strand
    * Reordering lessons within a moment
    * Moving lessons between moments (including to/from the unattached group)

  Position changes are persisted optimistically — the UI updates immediately
  and the backend saves the new order asynchronously.

  ## Example

      <.live_component
        module={LessonsSideNavComponent}
        id="lessons-side-nav"
        strand_id={@strand.id}
        lesson_id={@lesson.id}
        current_scope={@current_scope}
      />
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.Lessons

  import Lanttern.Utils, only: [reorder: 3]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div
        id="unattached-strand-lessons"
        phx-update="stream"
        phx-hook="Sortable"
        data-sortable-handle=".drag-handle"
        data-sortable-event="sortable_update"
        data-moment-id="unattached"
        data-sortable-group="lessons"
      >
        <.lesson_entry
          :for={{dom_id, lesson} <- @streams.unattached_lessons}
          lesson={lesson}
          current_lesson_id={@lesson_id}
          on_edit={JS.push("edit_lesson", value: %{id: lesson.id}, target: @myself)}
          id={dom_id}
          class="mt-2 last:mb-10"
        />
      </div>
      <div
        :if={!Enum.empty?(@moments_ids)}
        id="strand-moments"
        phx-update="stream"
        phx-hook="Sortable"
        data-sortable-handle=".drag-handle"
        data-sortable-event="sortable_update"
        data-sortable-group="moments"
        class="space-y-10"
      >
        <div
          :for={{dom_id, moment} <- @streams.moments}
          id={dom_id}
        >
          <%!-- moment --%>
          <div class="flex items-stretch gap-6 pr-10">
            <div class="flex items-center hover:cursor-move drag-handle">
              <hr class="w-4 h-1 border-0 rounded-r-full bg-ltrn-dark" />
            </div>
            <div class="flex-1">
              <div class="flex items-center gap-4">
                <.link
                  navigate={~p"/strands/moment/#{moment.id}"}
                  class="font-display font-bold text-sm hover:text-ltrn-subtle"
                >
                  {moment.name}
                </.link>
              </div>
            </div>
          </div>
          <%!-- lessons --%>
          <div
            id={"moment-#{moment.id}-lessons"}
            phx-hook="Sortable"
            data-sortable-handle=".drag-handle"
            data-sortable-event="sortable_update"
            phx-update="stream"
            data-moment-id={moment.id}
            data-sortable-group="lessons"
          >
            <.lesson_entry
              :for={{dom_id, lesson} <- @streams["moment_#{moment.id}_lessons"] || []}
              lesson={lesson}
              current_lesson_id={@lesson_id}
              on_edit={JS.push("edit_lesson", value: %{id: lesson.id}, target: @myself)}
              id={dom_id}
              class="mt-2"
            />
            <.empty_state_simple
              class="p-4 mt-2 mx-6 hidden only:block"
              id={"moment-#{moment.id}-lessons-empty"}
            >
              {gettext("No lessons for this moment yet")}
            </.empty_state_simple>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :lesson, :map, required: true
  attr :current_lesson_id, :integer, required: true
  attr :on_edit, :any, required: true
  attr :class, :any, default: nil

  defp lesson_entry(assigns) do
    link_style =
      cond do
        assigns.lesson.id == assigns.current_lesson_id -> "text-ltrn-darkest font-bold"
        !assigns.lesson.is_published -> "text-ltrn-subtle"
        true -> ""
      end

    assigns = assign(assigns, :link_style, link_style)

    ~H"""
    <div
      class={["relative flex items-stretch gap-6 max-w-full pr-10", @class]}
      id={@id}
    >
      <div class="flex items-center hover:cursor-move drag-handle">
        <hr class="w-4 h-0.5 border-0 rounded-r-full bg-ltrn-subtle" />
      </div>
      <.link
        navigate={~p"/strands/lesson/#{@lesson.id}"}
        class={[
          "flex-1 truncate hover:text-ltrn-subtle",
          @link_style
        ]}
      >
        {@lesson.name}
      </.link>
      <.tooltip id={"lesson-#{@lesson.id}-details-tooltip"}>
        {"#{@lesson.name}#{if(!@lesson.is_published, do: gettext(" (Draft)"))}"}
      </.tooltip>
      <div class="absolute right-2 flex flex-col justify-center gap-1 w-1 h-full">
        <div
          :for={tag <- @lesson.tags}
          class="flex-1 max-h-1.5 rounded-full"
          style={"background: #{tag.bg_color}"}
        />
      </div>
      <%!-- <div
            :if={!Enum.empty?(@lesson.subjects) || !Enum.empty?(@lesson.tags)}
            class="flex items-center gap-4 mt-2 font-sans text-xs"
          >
            <div :if={!Enum.empty?(@lesson.subjects)}>
              {@lesson.subjects |> Enum.map_join(", ", & &1.name)}
            </div>
            <div :if={!Enum.empty?(@lesson.tags)} class="flex gap-4">
              <div
                :for={tag <- @lesson.tags}
                class="flex items-center gap-1"
              >
                <.icon name="hero-tag-micro" class="w-4 h-4" style={"color: #{tag.bg_color}"} />
                {tag.name}
              </div>
            </div>
          </div>
        </div>
        <div class="flex flex-col items-stretch w-2">
          <div :for={tag <- @lesson.tags} class="flex-1" style={"background: #{tag.bg_color}"} />
        </div> --%>
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:moment, nil)
      |> assign(:lesson, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_moments()
    |> stream_lessons()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moments(socket) do
    moments =
      LearningContext.list_moments(strands_ids: [socket.assigns.strand_id])

    socket
    |> stream(:moments, moments)
    |> assign(:moments_ids, Enum.map(moments, & &1.id))
    |> assign(:moments, moments)
  end

  defp stream_lessons(socket) do
    # subjects_ids =
    #   case socket.assigns.subject_filter do
    #     %{id: id} -> [id]
    #     _ -> []
    #   end

    lessons =
      Lessons.list_lessons(
        strand_id: socket.assigns.strand_id,
        # subjects_ids: subjects_ids,
        preloads: [:subjects, :tags]
      )

    # group and stream lessons by moment
    moments_lessons_map = Enum.group_by(lessons, &Map.get(&1, :moment_id))

    socket
    |> stream_moments_lessons(moments_lessons_map)
    |> stream(:lessons, lessons)
    # we have a flat lessons ids list for security quick checks
    # (`id in socket.assigns.lessons_ids`) but we also have
    # a map of lessons ids per moment for sorting management
    |> assign(:lessons_ids, Enum.map(lessons, & &1.id))
    |> assign_moments_lessons_ids_map(moments_lessons_map)
  end

  defp stream_moments_lessons(socket, moments_lessons_map) do
    # stream unattached lessons first
    unattached_lessons =
      case moments_lessons_map[nil] do
        nil -> []
        lessons -> lessons
      end

    socket = stream(socket, :unattached_lessons, unattached_lessons)

    # then stream each moment lessons
    moments_lessons_map
    |> Map.delete(nil)
    |> Map.keys()
    |> Enum.reduce(socket, fn moment_id, socket ->
      moment_lessons =
        case moments_lessons_map[moment_id] do
          nil -> []
          moment_lessons -> moment_lessons
        end

      socket
      |> stream("moment_#{moment_id}_lessons", moment_lessons)
    end)
  end

  defp assign_moments_lessons_ids_map(socket, moments_lessons_map) do
    moments_lessons_ids_map =
      moments_lessons_map
      |> Enum.map(fn {moment_id, lessons} ->
        {moment_id, Enum.map(lessons, & &1.id)}
      end)
      |> Enum.into(%{})

    # moments without lessons will be missing from moments_lessons_map,
    # that's why we iterate socket.assigns.moments + nil for unattached
    all_moments_lessons_ids_map =
      [%{id: nil} | socket.assigns.moments]
      |> Enum.map(fn moment ->
        {moment.id, Map.get(moments_lessons_ids_map, moment.id, [])}
      end)
      |> Enum.into(%{})

    assign(socket, :moments_lessons_ids_map, all_moments_lessons_ids_map)
  end

  # event handlers

  @impl true
  def handle_event(
        "sortable_update",
        %{
          "from" => %{"sortableGroup" => "moments"},
          "oldIndex" => old_index,
          "newIndex" => new_index
        } =
          _payload,
        socket
      )
      when old_index != new_index do
    moments_ids = reorder(socket.assigns.moments_ids, old_index, new_index)

    # the inteface was already updated (optimistic update), just persist the new order
    LearningContext.update_moments_positions(moments_ids)

    {:noreply, assign(socket, :moments_ids, moments_ids)}
  end

  def handle_event(
        "sortable_update",
        %{
          "from" => %{"sortableGroup" => "lessons", "momentId" => from_moment_id},
          "to" => %{"momentId" => to_moment_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        } =
          _payload,
        socket
      )
      when from_moment_id != to_moment_id do
    from_moment_id =
      if from_moment_id == "unattached", do: nil, else: String.to_integer(from_moment_id)

    to_moment_id = if to_moment_id == "unattached", do: nil, else: String.to_integer(to_moment_id)

    # find and remove the lesson id from the origin moment
    {lesson_id, from_lessons_ids} =
      socket.assigns.moments_lessons_ids_map[from_moment_id]
      |> List.pop_at(old_index)

    # insert the lesson in target moment
    lessons_ids =
      socket.assigns.moments_lessons_ids_map[to_moment_id]
      |> List.insert_at(new_index, lesson_id)

    # the inteface was already updated (optimistic update), just persist the new order
    Lessons.update_lessons_positions(lessons_ids)

    # update lesson's moment_id
    lesson = Lessons.get_lesson!(lesson_id)
    Lessons.update_lesson(socket.assigns.current_scope, lesson, %{moment_id: to_moment_id})

    # and update ids list in assigns
    moments_lessons_ids_map =
      socket.assigns.moments_lessons_ids_map
      |> Map.put(from_moment_id, from_lessons_ids)
      |> Map.put(to_moment_id, lessons_ids)

    {:noreply, assign(socket, :moments_lessons_ids_map, moments_lessons_ids_map)}
  end

  def handle_event(
        "sortable_update",
        %{
          "from" => %{"sortableGroup" => "lessons", "momentId" => moment_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        } =
          _payload,
        socket
      )
      when old_index != new_index do
    moment_id = if moment_id == "unattached", do: nil, else: String.to_integer(moment_id)
    lessons_ids = reorder(socket.assigns.moments_lessons_ids_map[moment_id], old_index, new_index)

    # the inteface was already updated (optimistic update), just persist the new order
    Lessons.update_lessons_positions(lessons_ids)

    # and update ids list in assigns
    moments_lessons_ids_map =
      Map.put(
        socket.assigns.moments_lessons_ids_map,
        moment_id,
        lessons_ids
      )

    {:noreply, assign(socket, :moments_lessons_ids_map, moments_lessons_ids_map)}
  end

  def handle_event("sortable_update", _payload, socket), do: {:noreply, socket}
end
