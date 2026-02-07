defmodule LantternWeb.StrandLive.LessonsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Lessons
  alias Lanttern.Lessons.Lesson
  alias Lanttern.Taxonomy.Subject

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
        <section class="mt-20" id="lessons-section">
          <h2 class="font-display font-black text-2xl">{gettext("Strand lessons")}</h2>
          <div class="flex items-center gap-4 mt-6">
            <div class="relative">
              <.button
                type="button"
                icon_name="hero-funnel-mini"
                id="lesson-filter-options-button"
              >
                {if @subject_filter,
                  do: gettext("Subject: %{subject}", subject: @subject_filter.name),
                  else: gettext("All lessons")}
              </.button>
              <.dropdown_menu
                id="lesson-filter-options"
                button_id="lesson-filter-options-button"
                z_index="30"
              >
                <:item
                  type="link"
                  navigate={~p"/strands/#{@strand}/#lessons-section"}
                  text={gettext("All lessons")}
                />
                <:item
                  :for={subject <- @strand.subjects}
                  type="link"
                  navigate={"#{~p"/strands/#{@strand}"}?subject=#{subject.id}#lessons-section"}
                  text={subject.name}
                />
              </.dropdown_menu>
            </div>
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
                <:item
                  on_click={JS.push("new_moment", target: @myself)}
                  text={gettext("Create new moment")}
                />
                <:item
                  on_click={JS.push("new_lesson", target: @myself)}
                  text={gettext("Create new lesson")}
                />
              </.dropdown_menu>
            </div>
          </div>
          <div
            id="unattached-strand-lessons"
            phx-update="stream"
            class="mt-8"
            phx-hook="Sortable"
            data-sortable-handle=".drag-handle"
            data-sortable-event="sortable_update"
            data-moment-id="unattached"
            data-sortable-group="lessons"
          >
            <.lesson_entry
              :for={{dom_id, lesson} <- @streams.unattached_lessons}
              lesson={lesson}
              on_edit={JS.push("edit_lesson", value: %{id: lesson.id}, target: @myself)}
              id={dom_id}
              class="mt-4"
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
              data-sortable-event="sortable_update"
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
                        type="button"
                        phx-click={JS.push("edit_moment", value: %{id: moment.id}, target: @myself)}
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
                  data-sortable-event="sortable_update"
                  phx-update="stream"
                  data-moment-id={moment.id}
                  data-sortable-group="lessons"
                >
                  <.lesson_entry
                    :for={{dom_id, lesson} <- @streams["moment_#{moment.id}_lessons"] || []}
                    lesson={lesson}
                    on_edit={JS.push("edit_lesson", value: %{id: lesson.id}, target: @myself)}
                    id={dom_id}
                    class="mt-4"
                  />
                  <.empty_state_simple
                    class="p-4 mt-4 ml-10 hidden only:block"
                    id={"moment-#{moment.id}-lessons-empty"}
                  >
                    {if @subject_filter,
                      do: gettext("No lessons in %{subject}", subject: @subject_filter.name),
                      else: gettext("No lessons for this moment yet")}
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
        on_cancel={JS.push("close_moment_form", target: @myself)}
      >
        <:title>{@moment_overlay_title}</:title>
        <.live_component
          module={MomentFormComponent}
          id="moment-form"
          moment={@moment}
          strand_id={@strand.id}
          navigate={
            fn _moment ->
              if @subject_filter,
                do: ~p"/strands/#{@strand}?subject=#{@subject_filter.id}",
                else: ~p"/strands/#{@strand}"
            end
          }
        />
        <:actions_left :if={@moment.id}>
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
        on_cancel={JS.push("close_lesson_form", target: @myself)}
      >
        <:title>{@lesson_overlay_title}</:title>
        <.live_component
          module={LessonFormComponent}
          id="lesson-form"
          lesson={@lesson}
          moments={@moments}
          subjects={@strand.subjects}
          strand_id={@strand.id}
          current_scope={@current_scope}
          navigate={
            fn
              {:created, lesson} ->
                ~p"/strands/lesson/#{lesson}"

              {_updated_or_deleted, _lesson} ->
                if @subject_filter,
                  do: ~p"/strands/#{@strand}?subject=#{@subject_filter.id}",
                  else: ~p"/strands/#{@strand}"
            end
          }
          on_cancel={JS.exec("data-cancel", to: "#lesson-form-overlay")}
        />
      </.modal>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :lesson, :map, required: true
  attr :on_edit, :any, required: true
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
      <.card_base
        class="flex-1 flex items-stretch overflow-hidden"
        bg_class={if !@lesson.is_published, do: "bg-ltrn-lightest"}
        remove_shadow={!@lesson.is_published}
      >
        <div class="flex-1 p-4">
          
          <div class="flex items-center gap-4">
            <h4 class="flex-1 font-display font-bold text-base">
              <.link
                navigate={~p"/strands/lesson/#{@lesson.id}"}
                class="hover:text-ltrn-subtle"
              >
                {@lesson.name}
                <span :if={!@lesson.is_published} class="font-normal text-ltrn-subtle">
                  ({gettext("Draft")})
                </span>
              </.link>
            </h4>
            <.action
              type="button"
              phx-click={@on_edit}
              icon_name="hero-pencil-mini"
              theme="subtle"
            >
              {gettext("Edit")}
            </.action>
          </div>
          <div :if={@lesson.description} class="mt-2 text-xs">
            <.markdown text={@lesson.description} strip_tags class="mt-2 line-clamp-1" />
          </div>
          <div :if={!Enum.empty?(@lesson.subjects)} class="mt-2 text-xs">
            {@lesson.subjects |> Enum.map(& &1.name) |> Enum.join(", ")}
          </div>
        </div>
        <div class="flex flex-col items-stretch w-2">
          <div :for={tag <- @lesson.tags} class="flex-1" style={"background: #{tag.bg_color}"} />
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
      |> assign(:moment, nil)
      |> assign(:lesson, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {MomentFormComponent, {action, moment}}}, socket)
      when action in [:created, :updated] do
    message =
      case action do
        :created -> gettext("New moment created")
        :updated -> gettext("Moment updated")
      end

    socket =
      socket
      |> stream_insert(:moments, moment)
      |> assign(:moment, nil)
      |> delegate_navigation(put_flash: {:info, message})

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_subject_filter()
      |> initialize()

    {:ok, socket}
  end

  defp assign_subject_filter(%{assigns: %{params: %{"subject" => subject_id}}} = socket) do
    subject_filter =
      socket.assigns.strand.subjects
      |> Enum.find(&("#{&1.id}" == subject_id))

    assign(socket, :subject_filter, subject_filter)
  end

  defp assign_subject_filter(socket), do: assign(socket, :subject_filter, nil)

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
    |> assign(:moments_ids, Enum.map(moments, & &1.id))
    |> assign(:moments, moments)
  end

  defp stream_lessons(socket) do
    subjects_ids =
      case socket.assigns.subject_filter do
        %{id: id} -> [id]
        _ -> []
      end

    lessons =
      Lessons.list_lessons(
        strand_id: socket.assigns.strand.id,
        subjects_ids: subjects_ids,
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
  def handle_event("new_moment", _params, socket) do
    moment = %Moment{strand_id: socket.assigns.strand.id, subjects: []}

    socket =
      socket
      |> assign(:moment, moment)
      |> assign(:moment_overlay_title, gettext("New moment"))

    {:noreply, socket}
  end

  def handle_event("edit_moment", %{"id" => moment_id}, socket) do
    socket =
      if moment_id in socket.assigns.moments_ids do
        moment = LearningContext.get_moment(moment_id, preloads: [:subjects])

        socket
        |> assign(:moment, moment)
        |> assign(:moment_overlay_title, gettext("Edit moment"))
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("close_moment_form", _params, socket),
    do: {:noreply, assign(socket, :moment, nil)}

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

  def handle_event("new_lesson", _params, socket) do
    subjects =
      case socket.assigns.subject_filter do
        %Subject{} = subject -> [subject]
        _ -> []
      end

    lesson = %Lesson{strand_id: socket.assigns.strand.id, subjects: subjects}

    socket =
      socket
      |> assign(:lesson, lesson)
      |> assign(:lesson_overlay_title, gettext("New lesson"))

    {:noreply, socket}
  end

  def handle_event("edit_lesson", %{"id" => lesson_id}, socket) do
    socket =
      if lesson_id in socket.assigns.lessons_ids do
        lesson = Lessons.get_lesson(lesson_id, preloads: [:subjects, :tags])

        socket
        |> assign(:lesson, lesson)
        |> assign(:lesson_overlay_title, gettext("Edit lesson"))
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("close_lesson_form", _params, socket),
    do: {:noreply, assign(socket, :lesson, nil)}

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
