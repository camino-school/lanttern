defmodule LantternWeb.StrandLive.LessonsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Lessons
  alias Lanttern.Lessons.Lesson

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [reorder: 3]

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent
  alias LantternWeb.Lessons.LessonFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.responsive_container class="pb-10">
        <.cover_image
          image_url={@cover_image_url}
          alt_text={gettext("Strand cover image")}
          empty_state_text={gettext("Edit strand to add a cover image")}
          size="sm"
        />
        <hgroup class="mt-10 font-display font-black">
          <h1 class="text-4xl sm:text-5xl">{@strand.name}</h1>
          <p :if={@strand.type} class="mt-2 text-xl sm:text-2xl">{@strand.type}</p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand.subjects} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name)}
          </.badge>
          <.badge :for={year <- @strand.years} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name)}
          </.badge>
        </div>
        <.markdown text={@strand.description} class="mt-10 line-clamp-3" strip_tags />
        <.button type="link" navigate={~p"/strands/#{@strand.id}/overview"} class="mt-4">
          {gettext("Full overview")}
        </.button>
        <section class="mt-20">
          <h2 class="font-display font-black text-2xl">{gettext("Strand lessons")}</h2>
          <div class="flex items-center gap-4 mt-6">
            <.button
              type="button"
              icon_name="hero-funnel-mini"
            >
              {gettext("All moments and lessons")}
            </.button>
            <div class="relative">
              <.button
                type="button"
                id="new-in-lesson-options-button"
                icon_name="hero-plus-mini"
                theme="primary"
              >
                {gettext("New")}
              </.button>
              <.dropdown_menu
                id="new-in-lesson-options"
                button_id="new-in-lesson-options-button"
                z_index="30"
              >
                <:item type="link" patch="?moment=new" text={gettext("Create new moment")} />
                <:item type="link" patch="?lesson=new" text={gettext("Create new lesson")} />
              </.dropdown_menu>
            </div>
          </div>
          <div
            id="unattached-strand-lessons"
            phx-update="stream"
            class="mt-8"
            phx-hook="Sortable"
            data-sortable-handle=".drag-handle"
            data-moment-id="unattached"
            data-sortable-group="lessons"
          >
            <.lesson_entry
              :for={{dom_id, lesson} <- @streams.unattached_lessons}
              class="mt-4"
              lesson={lesson}
              id={dom_id}
            />
          </div>
          <%= if @moments_ids == [] do %>
            <.card_base class="p-10">
              <.empty_state>{gettext("No moments for this strand yet")}</.empty_state>
            </.card_base>
          <% else %>
            <div
              id="strand-moments"
              phx-update="stream"
              phx-hook="Sortable"
              data-sortable-handle=".drag-handle"
              data-sortable-group="moments"
            >
              <div
                :for={{dom_id, moment} <- @streams.moments}
                class="mt-12"
                id={dom_id}
              >
                <%!-- moment --%>
                <div class="flex items-start gap-4">
                  <div class="py-3 hover:cursor-move drag-handle">
                    <hr class="w-6 h-1 border-0 rounded-full bg-ltrn-dark" />
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center gap-4">
                      <.link
                        navigate={~p"/strands/moment/#{moment.id}"}
                        class="font-display font-bold text-xl hover:text-ltrn-subtle"
                      >
                        {moment.name}
                      </.link>
                      <.action
                        type="link"
                        patch={"?moment=#{moment.id}"}
                        icon_name="hero-pencil-mini"
                        theme="subtle"
                      >
                        {gettext("Edit")}
                      </.action>
                    </div>
                    <.markdown text={moment.description} strip_tags class="mt-4 line-clamp-3" />
                  </div>
                </div>
                <%!-- lessons --%>
                <div
                  id={"moment-#{moment.id}-lessons"}
                  phx-hook="Sortable"
                  data-sortable-handle=".drag-handle"
                  phx-update="stream"
                  data-moment-id={moment.id}
                  data-sortable-group="lessons"
                >
                  <.lesson_entry
                    :for={{dom_id, lesson} <- @streams["moment_#{moment.id}_lessons"] || []}
                    class="mt-4"
                    lesson={lesson}
                    id={dom_id}
                  />
                  <.empty_state_simple
                    class="flex-1 p-4 mt-4 ml-10 hidden only:block"
                    id={"moment-#{moment.id}-lessons-empty"}
                  >
                    {gettext("No lessons for this moment yet")}
                  </.empty_state_simple>
                </div>
              </div>
            </div>
          <% end %>
        </section>
      </.responsive_container>
      <.slide_over
        :if={@moment}
        id="moment-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}")}
      >
        <:title>{@moment_overlay_title}</:title>
        <.live_component
          module={MomentFormComponent}
          id={:new}
          moment={@moment}
          strand_id={@strand.id}
          action={:new}
          navigate={fn _moment -> ~p"/strands/#{@strand}" end}
          notify_parent
        />
        <:actions_left>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_moment"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-form-overlay")}
          >
            {gettext("Cancel")}
          </.button>
          <.button type="submit" form="moment-form">
            {gettext("Save")}
          </.button>
        </:actions>
      </.slide_over>
      <.modal
        :if={@lesson}
        id="lesson-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}")}
      >
        <:title>{@lesson_overlay_title}</:title>
        <.live_component
          module={LessonFormComponent}
          id={:new}
          lesson={@lesson}
          moments={@moments}
          strand_id={@strand.id}
          action={:new}
          navigate={fn _lesson -> ~p"/strands/#{@strand}" end}
          on_cancel={JS.exec("data-cancel", to: "#lesson-form-overlay")}
        />
      </.modal>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :lesson, :map, required: true
  attr :class, :any, default: nil

  defp lesson_entry(assigns) do
    ~H"""
    <div
      class={["flex items-center gap-4", @class]}
      id={@id}
    >
      <div class="py-3 hover:cursor-move drag-handle">
        <hr class="w-6 h-0.5 border-0 rounded-full bg-ltrn-subtle" />
      </div>
      <.card_base class="flex-1 p-4">
        <div class="flex items-center gap-4">
          <h4 class="font-display font-bold text-base">{@lesson.name}</h4>
          <.action
            type="link"
            patch={"?lesson=#{@lesson.id}"}
            icon_name="hero-pencil-mini"
            theme="subtle"
          >
            {gettext("Edit")}
          </.action>
        </div>
      </.card_base>
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_moment()
      |> assign_lesson()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    strand = socket.assigns.strand

    socket
    |> assign(
      :cover_image_url,
      object_url_to_render_url(strand.cover_image_url, width: 1280, height: 640)
    )
    |> stream_moments()
    |> stream_lessons()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moments(socket) do
    moments =
      LearningContext.list_moments(strands_ids: [socket.assigns.strand.id])

    socket
    |> stream(:moments, moments)
    |> assign(:moments_ids, Enum.map(moments, &"#{&1.id}"))
    |> assign(:moments, moments)
  end

  defp stream_lessons(socket) do
    lessons =
      Lessons.list_lessons(strand_id: socket.assigns.strand.id, preloads: :moment)

    # group and stream lessons by moment
    moments_lessons_map = Enum.group_by(lessons, &Map.get(&1, :moment_id))

    socket
    |> stream_moments_lessons(moments_lessons_map)
    |> stream(:lessons, lessons)
    # we have a flat lessons ids list for security quick checks
    # (`id in socket.assigns.lessons_ids`) but we also have
    # a map of lessons ids per moment for sorting management
    |> assign(:lessons_ids, Enum.map(lessons, &"#{&1.id}"))
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

  defp assign_moment(%{assigns: %{params: %{"moment" => "new"}}} = socket) do
    moment = %Moment{strand_id: socket.assigns.strand.id, subjects: []}

    socket
    |> assign(:moment, moment)
    |> assign(:moment_overlay_title, gettext("New moment"))
  end

  defp assign_moment(%{assigns: %{params: %{"moment" => moment_id}}} = socket) do
    if moment_id in socket.assigns.moments_ids do
      moment = LearningContext.get_moment(moment_id, preloads: :subjects)

      socket
      |> assign(:moment, moment)
      |> assign(:moment_overlay_title, gettext("Edit moment"))
    else
      assign(socket, :moment, nil)
    end
  end

  defp assign_moment(socket), do: assign(socket, :moment, nil)

  defp assign_lesson(%{assigns: %{params: %{"lesson" => "new"}}} = socket) do
    lesson = %Lesson{strand_id: socket.assigns.strand.id}

    socket
    |> assign(:lesson, lesson)
    |> assign(:lesson_overlay_title, gettext("New lesson"))
  end

  defp assign_lesson(%{assigns: %{params: %{"lesson" => lesson_id}}} = socket) do
    if lesson_id in socket.assigns.lessons_ids do
      lesson = Lessons.get_lesson(lesson_id)

      socket
      |> assign(:lesson, lesson)
      |> assign(:lesson_overlay_title, gettext("Edit lesson"))
    else
      assign(socket, :lesson, nil)
    end
  end

  defp assign_lesson(socket), do: assign(socket, :lesson, nil)

  # event handlers

  @impl true
  def handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        socket =
          socket
          |> put_flash(:info, gettext("Moment deleted"))
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(
            :error,
            gettext("Moment has linked assessments. Deleting it would cause some data loss.")
          )
          |> push_patch(
            to: ~p"/strands/#{socket.assigns.strand}?moment=#{socket.assigns.moment.id}"
          )

        {:noreply, socket}
    end
  end

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
    Lessons.update_lesson(lesson, %{moment_id: to_moment_id})

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

  # defp

  # info handlers

  def handle_info({LessonFormComponent, {:saved, _lesson}}, socket) do
    # Refresh moments list when a lesson is created
    {:noreply, stream_moments(socket)}
  end
end
