defmodule LantternWeb.StrandReportLive.StrandReportOverviewComponent do
  @moduledoc """
  Renders the overview content of a `StrandReport`.

  ### Required attrs

  - `strand_report` - `%StrandReport{}`
  - `student_id`

  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.Lessons

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.scroll_to_top id="strand-report-overview-scroll-top" />
      <.responsive_container class="px-2" no_default_padding>
        <.cover_image
          :if={@strand_report.cover_image_url || @strand_report.strand.cover_image_url}
          context_image_url={@strand_report.cover_image_url}
          image_url={@strand_report.strand.cover_image_url}
          alt_text={gettext("Strand cover image")}
          size="sm"
          class="mb-10"
        />
        <hgroup>
          <h1 class="font-display font-black text-ltrn-darkest text-4xl sm:text-5xl">
            {@strand_report.strand.name}
          </h1>
          <p :if={@strand_report.strand.type} class="mt-2 font-bold text-xl sm:text-2xl">
            {@strand_report.strand.type}
          </p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand_report.strand.subjects} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name)}
          </.badge>
          <.badge :for={year <- @strand_report.strand.years} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name)}
          </.badge>
        </div>
        <.markdown text={@strand_report.strand.description} class="mt-10 line-clamp-3" strip_tags />
        <.button type="link" navigate={"#{@base_path}/overview"} class="mt-4">
          {gettext("Read the full overview")}
        </.button>
        <section class="mt-20" id="lessons-section">
          <div
            id="unattached-strand-lessons"
            phx-update="stream"
            class="mt-8"
          >
            <.lesson_entry
              :for={{dom_id, lesson} <- @streams.unattached_lessons}
              lesson={lesson}
              base_path={@base_path}
              id={dom_id}
              class="mt-4"
            />
          </div>
          <%= if @moments_ids == [] do %>
            <.card_base class="p-10">
              <.empty_state>{gettext("No moments for this strand yet")}</.empty_state>
            </.card_base>
          <% else %>
            <div id="strand-moments" phx-update="stream">
              <div
                :for={{dom_id, moment} <- @streams.moments}
                class="mt-12"
                id={dom_id}
              >
                <%!-- moment --%>
                <div class="flex items-start gap-4">
                  <div class="py-3">
                    <hr class="w-4 sm:w-6 h-1 border-0 rounded-full bg-ltrn-dark" />
                  </div>
                  <div class="flex-1">
                    <button
                      type="button"
                      phx-click={
                        JS.push("view_moment_details", value: %{id: moment.id}, target: @myself)
                      }
                      class="font-display font-bold text-xl hover:text-ltrn-subtle"
                    >
                      {moment.name}
                    </button>
                    <button
                      type="button"
                      phx-click={
                        JS.push("view_moment_details", value: %{id: moment.id}, target: @myself)
                      }
                      class="block mt-4 text-left"
                    >
                      <.markdown
                        text={moment.description}
                        strip_tags
                        class="hover:text-ltrn-subtle line-clamp-3"
                      />
                    </button>
                  </div>
                </div>
                <%!-- lessons --%>
                <div id={"moment-#{moment.id}-lessons"} phx-update="stream">
                  <.lesson_entry
                    :for={{dom_id, lesson} <- @streams["moment_#{moment.id}_lessons"] || []}
                    lesson={lesson}
                    base_path={@base_path}
                    id={dom_id}
                    class="mt-4"
                  />
                </div>
              </div>
            </div>
          <% end %>
        </section>
      </.responsive_container>
      <.modal
        :if={@live_action == :overview_full}
        id="overview-full-overlay"
        show={true}
        on_cancel={JS.patch(@base_path)}
      >
        <h1 class="font-display font-black text-2xl">{@strand_report.strand.name}</h1>
        <.markdown text={@strand_report.strand.description} class="mt-10" />
      </.modal>
      <.modal
        :if={@moment}
        id="moment-details-overlay"
        show={true}
        on_cancel={JS.push("close_moment_details", target: @myself)}
      >
        <h1 class="font-display font-black text-2xl">{@moment.name}</h1>
        <.markdown text={@moment.description} class="mt-10" />
      </.modal>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :lesson, :map, required: true
  attr :base_path, :string, required: true
  attr :class, :any, default: nil

  defp lesson_entry(assigns) do
    ~H"""
    <div
      class={["flex items-center gap-4", @class]}
      id={@id}
    >
      <hr class="w-4 sm:w-6 h-0.5 border-0 rounded-full bg-ltrn-subtle" />
      <.card_base class="flex-1 flex items-stretch overflow-hidden">
        <div class="flex-1 p-4">
          <h4 class="flex-1 font-display font-bold text-base">
            <.link
              navigate={"#{@base_path}/lesson/#{@lesson.id}"}
              class="text-ltrn-dark hover:text-ltrn-subtle"
            >
              {@lesson.name}
            </.link>
          </h4>
          <.markdown
            :if={@lesson.description}
            text={@lesson.description}
            strip_tags
            class="mt-2 text-ltrn-subtle line-clamp-1"
          />
          <div
            :if={!Enum.empty?(@lesson.subjects) || !Enum.empty?(@lesson.tags)}
            class="flex items-center gap-4 mt-2 font-sans text-sm text-ltrn-subtle"
          >
            <div :if={!Enum.empty?(@lesson.subjects)}>
              {@lesson.subjects |> Enum.map_join(", ", & &1.name)}
            </div>
            <div :if={!Enum.empty?(@lesson.tags)} class="flex gap-4">
              <div
                :for={tag <- @lesson.tags}
                class="flex items-center gap-1"
              >
                <.icon name="hero-tag-micro" style={"color: #{tag.bg_color}"} />
                {tag.name}
              </div>
            </div>
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
      |> assign(:class, nil)
      |> assign(:moment, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_description()
      |> stream_moments()
      |> stream_lessons()

    {:ok, socket}
  end

  defp assign_description(socket) do
    # we try to use the strand report description
    # and we fall back to the strand description

    description =
      case socket.assigns.strand_report do
        %{description: strand_report_desc} when is_binary(strand_report_desc) ->
          strand_report_desc

        %{strand: %{description: strand_desc}} when is_binary(strand_desc) ->
          strand_desc

        _ ->
          nil
      end

    assign(socket, :description, description)
  end

  defp stream_moments(socket) do
    moments =
      LearningContext.list_moments(strands_ids: [socket.assigns.strand_report.strand_id])

    socket
    |> stream(:moments, moments)
    |> assign(:moments_ids, Enum.map(moments, & &1.id))
    |> assign(:moments, moments)
  end

  defp stream_lessons(socket) do
    lessons =
      Lessons.list_lessons(
        strand_id: socket.assigns.strand_report.strand_id,
        is_published: true,
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
  def handle_event("view_moment_details", %{"id" => moment_id}, socket) do
    socket =
      if moment_id in socket.assigns.moments_ids do
        moment = LearningContext.get_moment(moment_id)
        assign(socket, :moment, moment)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("close_moment_details", _params, socket) do
    {:noreply, assign(socket, :moment, nil)}
  end
end
