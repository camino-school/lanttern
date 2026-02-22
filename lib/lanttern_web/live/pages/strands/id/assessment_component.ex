defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.LearningContext

  import Lanttern.Utils, only: [reorder: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container class="py-10">
        <section id="assessment-info">
          <div class="flex items-center gap-2 mb-6">
            <h3 class="font-display font-bold text-2xl">
              {gettext("Assessment information")}
            </h3>
            <button>
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <.tooltip id="assessment-info-tooltip">
                {gettext(
                  "Use this area to share assessment information with students (e.g. grade composition)"
                )}
              </.tooltip>
            </button>
          </div>
          <.markdown
            :if={!@strand_form && @strand.assessment_info}
            text={@strand.assessment_info}
            class="mb-4"
          />
          <div :if={!@strand_form}>
            <.button
              :if={!@strand.assessment_info}
              phx-click="edit_assessment_info"
              phx-target={@myself}
              icon_name="hero-plus-mini"
              theme="primary"
            >
              {gettext("Add assessment info")}
            </.button>
            <.button
              :if={@strand.assessment_info}
              phx-click="edit_assessment_info"
              phx-target={@myself}
            >
              {gettext("Edit assessment info")}
            </.button>
          </div>
          <.form
            :if={@strand_form}
            for={@strand_form}
            phx-submit="save_assessment_info"
            phx-change="validate_assessment_info"
            phx-target={@myself}
            id="strand-assessment-info-form"
          >
            <.input
              field={@strand_form[:assessment_info]}
              type="markdown"
              label={gettext("Strand assessment info")}
              label_is_sr_only
              phx-debounce="1500"
            />
            <div class="flex justify-end gap-2 mt-2">
              <.button
                type="button"
                theme="ghost"
                phx-click="cancel_assessment_info_edit"
                phx-target={@myself}
              >
                {gettext("Cancel")}
              </.button>
              <.button type="submit" theme="primary">{gettext("Save")}</.button>
            </div>
          </.form>
        </section>
        <section id="assessment-points" class="mt-10">
          <h3 class="font-display font-bold text-2xl">
            {gettext("Assessment points")}
          </h3>
          <div class="flex items-center gap-4 mt-6">
            <div class="relative">
              <.button
                type="button"
                id="new-moment-assessment-button"
                icon_name="hero-plus-mini"
                theme="primary"
              >
                {gettext("New")}
              </.button>
              <.dropdown_menu
                id="new-moment-assessment"
                button_id="new-moment-assessment-button"
              >
                <:instructions>
                  {gettext("Select moment to create the assessment point in")}
                </:instructions>
                <:item
                  :for={moment <- @moments}
                  on_click={
                    JS.push("new_assessment_point",
                      value: %{"moment_id" => moment.id},
                      target: @myself
                    )
                  }
                  text={moment.name}
                />
              </.dropdown_menu>
            </div>
            <div class="relative">
              <.button
                type="button"
                id="marking-button"
                icon_name="hero-pencil-square-mini"
              >
                {gettext("Marking")}
              </.button>
              <.dropdown_menu
                id="marking"
                button_id="marking-button"
              >
                <:item
                  :for={moment <- @moments}
                  type="link"
                  navigate={~p"/strands/#{@strand}/assessment/marking/moment/#{moment}"}
                  text={moment.name}
                />
                <:item
                  type="link"
                  navigate={~p"/strands/#{@strand}/assessment/marking"}
                  text={gettext("Strand goals")}
                />
              </.dropdown_menu>
            </div>
          </div>
          <div class="mt-6 space-y-10">
            <%= for moment <- @moments do %>
              <div id={"moment-#{moment.id}-ap-group"}>
                <h4 class="font-display font-bold text-lg">{moment.name}</h4>
                <div
                  id={"moment-#{moment.id}-sortable-aps"}
                  phx-hook="Sortable"
                  phx-update="stream"
                  phx-target={@myself}
                  data-sortable-handle=".sortable-handle"
                  data-sortable-event="sortable_ap_update"
                  data-moment-id={moment.id}
                  data-sortable-group="assessment_points"
                >
                  <.assessment_point_card
                    :for={{dom_id, ap} <- @streams["moment_#{moment.id}_assessment_points"] || []}
                    id={dom_id}
                    assessment_point={ap}
                    class="mt-2"
                    on_edit={JS.push("edit_assessment_point", value: %{id: ap.id}, target: @myself)}
                  />
                  <.empty_state_simple
                    class="p-4 mt-4 hidden only:block"
                    id={"moment-#{moment.id}-assessment-empty"}
                  >
                    {gettext("No assessment points in this moment yet")}
                  </.empty_state_simple>
                </div>
              </div>
            <% end %>
            <div id="strand-ap-group">
              <h4 class="mb-4 font-display font-bold text-lg">{gettext("Goals assessment")}</h4>
              <p class="mb-4">
                {gettext("Goals assessment are defined by the strand curriculum.")}
                <.link
                  patch={~p"/strands/#{@strand}/overview#strand-curriculum"}
                  class="hover:text-ltrn-subtle"
                >
                  {gettext("You can manage curriculum items in the overview section.")}
                </.link>
              </p>
              <div
                id="strand-sortable-aps"
                phx-hook="Sortable"
                phx-update="stream"
                phx-target={@myself}
                data-sortable-handle=".sortable-handle"
                data-sortable-event="sortable_ap_update"
                data-moment-id="strand"
              >
                <.assessment_point_card
                  :for={{dom_id, ap} <- @streams.strand_assessment_points}
                  id={dom_id}
                  assessment_point={ap}
                  class="mb-2"
                  on_edit={JS.push("edit_assessment_point", value: %{id: ap.id}, target: @myself)}
                />
              </div>
            </div>
          </div>
        </section>
      </.responsive_container>
      <.live_component
        :if={@assessment_point}
        module={AssessmentPointFormOverlayComponent}
        id="assessment-point-form-overlay"
        assessment_point={@assessment_point}
        notify_component={@myself}
        title={@assessment_point_overlay_title}
        on_cancel={JS.push("close_assessment_point_form", target: @myself)}
        curriculum_from_strand_id={@strand.id}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :assessment_point, :map, required: true
  attr :on_edit, :any, required: true
  attr :class, :any, default: nil

  defp assessment_point_card(assigns) do
    ~H"""
    <.draggable_card id={@id} class={@class}>
      <div class="py-4 space-y-4">
        <button
          type="button"
          phx-click={@on_edit}
          class="flex-1 font-bold text-left text-ltrn-darkest hover:text-ltrn-subtle"
        >
          {if @assessment_point.moment_id,
            do: @assessment_point.name,
            else:
              "(#{@assessment_point.curriculum_item.curriculum_component.name}) #{@assessment_point.curriculum_item.name}"}
        </button>

        <.markdown
          :if={@assessment_point.report_info}
          text={@assessment_point.report_info}
          class="line-clamp-2"
        />
        <div class="flex items-center gap-2">
          <div :if={@assessment_point.rubric_id}>
            <.icon name="hero-view-columns" />
            <.tooltip id={"ap-#{@assessment_point.id}-rubric-tooltip"}>
              {gettext("Uses rubric in assessment")}
            </.tooltip>
          </div>
          <.badge :if={@assessment_point.is_differentiation} theme="diff" class="shrink-0">
            {gettext("Differentiation")}
          </.badge>
          <.badge class="shrink-0">{@assessment_point.scale.name}</.badge>
          <%!-- render curriculum only for moment assessment poiint --%>
          <div :if={@assessment_point.moment_id} class="flex-1 min-w-0">
            <p class="max-w-sm font-sans text-sm text-ltrn-subtle truncate">
              {@assessment_point.curriculum_item.name}
            </p>
            <.tooltip id={"ap-#{@assessment_point.id}-curriculum-tooltip"}>
              ({@assessment_point.curriculum_item.curriculum_component.name}) {@assessment_point.curriculum_item.name}
            </.tooltip>
          </div>
        </div>
      </div>
    </.draggable_card>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:strand_form, nil)
      |> assign(:assessment_point, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {AssessmentPointFormOverlayComponent, {:created, created_ap}}}, socket) do
    ap =
      Assessments.get_assessment_point!(created_ap.id,
        preloads: [:scale, curriculum_item: :curriculum_component]
      )

    stream_key = ap_stream_key(ap.moment_id)

    ap_ids = [
      ap.id | Map.get(socket.assigns.moments_assessment_points_ids_map, ap.moment_id, [])
    ]

    moments_map =
      Map.put(socket.assigns.moments_assessment_points_ids_map, ap.moment_id, ap_ids)

    socket =
      socket
      |> stream_insert(stream_key, ap)
      |> assign(:assessment_points_ids, [ap.id | socket.assigns.assessment_points_ids])
      |> assign(:moments_assessment_points_ids_map, moments_map)
      |> assign(:assessment_point, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Assessment point created")})

    {:ok, socket}
  end

  def update(%{action: {AssessmentPointFormOverlayComponent, {:updated, updated_ap}}}, socket) do
    ap =
      Assessments.get_assessment_point!(updated_ap.id,
        preloads: [:scale, curriculum_item: :curriculum_component]
      )

    socket =
      socket
      |> stream_insert(ap_stream_key(ap.moment_id), ap)
      |> assign(:assessment_point, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Assessment point updated")})

    {:ok, socket}
  end

  def update(
        %{action: {AssessmentPointFormOverlayComponent, {action, deleted_ap}}},
        socket
      )
      when action in [:deleted, :deleted_with_entries] do
    old_moment_id =
      Enum.find_value(socket.assigns.moments_assessment_points_ids_map, fn {moment_id, ids} ->
        if deleted_ap.id in ids, do: moment_id
      end)

    old_ids =
      List.delete(
        Map.get(socket.assigns.moments_assessment_points_ids_map, old_moment_id, []),
        deleted_ap.id
      )

    moments_map =
      Map.put(socket.assigns.moments_assessment_points_ids_map, old_moment_id, old_ids)

    socket =
      socket
      |> stream_delete(ap_stream_key(old_moment_id), deleted_ap)
      |> assign(
        :assessment_points_ids,
        List.delete(socket.assigns.assessment_points_ids, deleted_ap.id)
      )
      |> assign(:moments_assessment_points_ids_map, moments_map)
      |> assign(:assessment_point, nil)
      |> delegate_navigation(put_flash: {:info, gettext("Assessment point deleted")})

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> load_moments_and_assessment_points()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp load_moments_and_assessment_points(socket) do
    strand = socket.assigns.strand

    moments = LearningContext.list_moments(strands_ids: [strand.id])
    moments_ids = Enum.map(moments, & &1.id)

    preloads = [:scale, curriculum_item: :curriculum_component]

    # moment-linked APs have strand_id: nil, so we must query by moments_ids
    moment_aps =
      if moments_ids == [] do
        []
      else
        Assessments.list_assessment_points(moments_ids: moments_ids, preloads: preloads)
      end

    # strand-level APs have strand_id set and moment_id: nil
    strand_aps = Assessments.list_assessment_points(strand_id: strand.id, preloads: preloads)

    assessment_points = moment_aps ++ strand_aps
    grouped = Enum.group_by(assessment_points, & &1.moment_id)

    socket
    |> assign(:moments, moments)
    |> assign(:moments_ids, moments_ids)
    |> assign(:assessment_points_ids, Enum.map(assessment_points, & &1.id))
    |> stream_assessment_points_by_group(grouped, moments)
    |> assign_moments_assessment_points_ids_map(grouped, moments)
  end

  defp stream_assessment_points_by_group(socket, grouped, moments) do
    strand_aps = Map.get(grouped, nil, [])
    socket = stream(socket, :strand_assessment_points, strand_aps)

    Enum.reduce(moments, socket, fn moment, socket ->
      moment_aps = Map.get(grouped, moment.id, [])
      stream(socket, "moment_#{moment.id}_assessment_points", moment_aps)
    end)
  end

  defp assign_moments_assessment_points_ids_map(socket, grouped, moments) do
    ids_map =
      [nil | Enum.map(moments, & &1.id)]
      |> Enum.map(fn moment_id ->
        {moment_id, grouped |> Map.get(moment_id, []) |> Enum.map(& &1.id)}
      end)
      |> Enum.into(%{})

    assign(socket, :moments_assessment_points_ids_map, ids_map)
  end

  # event handlers

  @impl true

  # -- assessment info

  def handle_event("edit_assessment_info", _params, socket) do
    form =
      socket.assigns.strand
      |> LearningContext.change_strand()
      |> to_form()

    {:noreply, assign(socket, :strand_form, form)}
  end

  def handle_event("cancel_assessment_info_edit", _params, socket),
    do: {:noreply, assign(socket, :strand_form, nil)}

  def handle_event("validate_assessment_info", %{"strand" => params}, socket) do
    form =
      socket.assigns.strand
      |> LearningContext.change_strand(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :strand_form, form)}
  end

  def handle_event("save_assessment_info", %{"strand" => params}, socket) do
    case LearningContext.update_strand(socket.assigns.strand, params) do
      {:ok, strand} ->
        notify(__MODULE__, {:updated, strand}, socket.assigns)

        socket =
          socket
          |> assign(:strand, strand)
          |> assign(:strand_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :strand_form, to_form(changeset))}
    end
  end

  # -- assessment points

  def handle_event("new_assessment_point", %{"moment_id" => moment_id}, socket) do
    assessment_point = %AssessmentPoint{moment_id: moment_id}

    socket =
      socket
      |> assign(:assessment_point, assessment_point)
      |> assign(:assessment_point_overlay_title, gettext("New assessment point"))

    {:noreply, socket}
  end

  def handle_event("edit_assessment_point", %{"id" => ap_id}, socket) do
    socket =
      if ap_id in socket.assigns.assessment_points_ids do
        ap = Assessments.get_assessment_point!(ap_id)

        socket
        |> assign(:assessment_point, ap)
        |> assign(:assessment_point_overlay_title, gettext("Edit assessment point"))
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("close_assessment_point_form", _params, socket),
    do: {:noreply, assign(socket, :assessment_point, nil)}

  # -- sortable

  def handle_event(
        "sortable_ap_update",
        %{
          "from" => %{"momentId" => from_moment_id},
          "to" => %{"momentId" => to_moment_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        },
        socket
      )
      when from_moment_id != to_moment_id do
    from_key = parse_ap_moment_key(from_moment_id)
    to_key = parse_ap_moment_key(to_moment_id)

    {ap_id, from_ids} =
      socket.assigns.moments_assessment_points_ids_map[from_key]
      |> List.pop_at(old_index)

    to_ids =
      socket.assigns.moments_assessment_points_ids_map[to_key]
      |> List.insert_at(new_index, ap_id)

    # the interface was already updated (optimistic update), just persist the new order and moment
    Assessments.update_assessment_points_positions(to_ids)

    ap = Assessments.get_assessment_point!(ap_id)
    Assessments.update_assessment_point(ap, %{moment_id: to_key})

    moments_map =
      socket.assigns.moments_assessment_points_ids_map
      |> Map.put(from_key, from_ids)
      |> Map.put(to_key, to_ids)

    {:noreply, assign(socket, :moments_assessment_points_ids_map, moments_map)}
  end

  def handle_event(
        "sortable_ap_update",
        %{
          "from" => %{"momentId" => moment_id},
          "oldIndex" => old_index,
          "newIndex" => new_index
        },
        socket
      )
      when old_index != new_index do
    moment_key = parse_ap_moment_key(moment_id)

    ap_ids =
      reorder(socket.assigns.moments_assessment_points_ids_map[moment_key], old_index, new_index)

    # the interface was already updated (optimistic update), just persist the new order
    Assessments.update_assessment_points_positions(ap_ids)

    moments_map = Map.put(socket.assigns.moments_assessment_points_ids_map, moment_key, ap_ids)

    {:noreply, assign(socket, :moments_assessment_points_ids_map, moments_map)}
  end

  def handle_event("sortable_ap_update", _payload, socket), do: {:noreply, socket}

  # defp helpers

  defp ap_stream_key(nil), do: :strand_assessment_points
  defp ap_stream_key(moment_id), do: "moment_#{moment_id}_assessment_points"

  defp parse_ap_moment_key("strand"), do: nil
  defp parse_ap_moment_key(id), do: String.to_integer(id)
end
