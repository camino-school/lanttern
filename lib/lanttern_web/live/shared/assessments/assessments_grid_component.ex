defmodule LantternWeb.Assessments.AssessmentsGridComponent do
  @moduledoc """
  This component handles the loading and rendering of the assessment
  points and its entries in the context of a strand or a moment.

  The component also handles the entries update process, including
  the entry details view (with comments and evidences).

  #### Expected external assigns

      attr :current_user, User
      attr :current_scope, Scope
      attr :current_assessment_view, :string
      attr :classes_ids, :list, doc: "list of classes_ids to filter results"
      attr :strand_id, :integer, doc: "defines a strand grid view"
      attr :class, :any
      attr :navigate, :string, doc: "defines push_navigate target"
      attr :url_params, :map, doc: "URL-based filter params to preserve in navigation", default: %{}
      attr :filter_assessment_points_ids, :list, default: nil, doc: "when set, restricts displayed assessment points to these IDs"

  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Identity.Scope
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Student

  import LantternWeb.GradingComponents

  # shared components
  alias LantternWeb.Assessments.EntryCellComponent
  alias LantternWeb.Assessments.EntryDetailsOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <%!-- if no class filter is selected, ask user to select one --%>
        <div :if={@classes_ids == []} class="p-10 rounded-sm shadow-xl bg-white">
          <p class="flex items-center gap-2">
            <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
            {gettext("Assign at least one class to the strand to view the assessment grid")}
          </p>
          {render_slot(@no_class_action)}
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div
          :if={@classes_ids != [] && !@has_assessment_points}
          class="p-10 mt-4 rounded-sm shadow-xl bg-white"
        >
          <.empty_state>{gettext("No assessment points for this strand yet")}</.empty_state>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div :if={@classes_ids != [] && @has_assessment_points}>
        <div class={[
          "relative w-full max-h-screen border rounded-sm shadow-xl #{@view_bg} overflow-x-auto",
          if(@current_assessment_view == "student",
            do: "border-ltrn-student-accent",
            else: "border-transparent"
          )
        ]}>
          <div
            class={["relative grid", if(@entries_changes_map != %{}, do: "pb-20", else: "pb-4")]}
            style={"grid-template-columns: 15rem #{@assessment_points_columns_grid}"}
          >
            <div
              class={"sticky top-0 z-20 grid grid-cols-subgrid pt-4 #{@view_bg}"}
              style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
            >
              <div class={["sticky left-0 z-20 #{@view_bg}", "row-span-2"]}></div>
              <div
                id="grid-assessment-point-headers"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point_header
                  :for={{dom_id, ap_header} <- @streams.assessment_point_headers}
                  id={dom_id}
                  ap_header={ap_header}
                  assessment_view={@current_assessment_view}
                />
              </div>
              <div
                id="grid-assessment-points"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point
                  :for={{dom_id, assessment_point} <- @streams.assessment_points}
                  id={dom_id}
                  assessment_point={assessment_point}
                  assessment_view={@current_assessment_view}
                  url_params={@url_params}
                  myself={@myself}
                />
              </div>
            </div>
            <div
              id="grid-student-entries"
              phx-update="stream"
              class="grid grid-cols-subgrid"
              style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
            >
              <.student_entries
                :for={{dom_id, {student, entries}} <- @streams.students_entries}
                id={dom_id}
                current_scope={@current_scope}
                student={student}
                entries={entries}
                myself={@myself}
                current_assessment_view={@current_assessment_view}
                view_bg={@view_bg}
                current_user={@current_user}
              />
            </div>
          </div>
        </div>
      </div>
      <.fixed_bar :if={@entries_changes_map != %{}} class="flex items-center gap-6">
        <div class="flex-1 flex items-center gap-4">
          <p class="text-white text-nowrap">
            {ngettext("1 change", "%{count} changes", map_size(@entries_changes_map))}
          </p>
          <p
            :if={MapSet.size(@invalid_changes_set) > 0}
            class="flex items-center gap-2 font-sans text-sm text-ltrn-alert-lighter"
          >
            <.icon name="hero-exclamation-circle-mini" />
            {gettext("Some values are out of range")}
          </p>
          <p
            :if={@current_assessment_view == "student" && MapSet.size(@invalid_changes_set) == 0}
            class="flex items-center gap-2 font-sans text-sm text-ltrn-student-accent"
          >
            <.icon name="hero-information-circle-mini" />
            {gettext("You are registering students self-assessments")}
          </p>
        </div>
        <.button
          phx-click={JS.navigate(@navigate)}
          theme="white_outline"
          data-confirm={gettext("Are you sure?")}
        >
          {gettext("Discard")}
        </.button>
        <.button
          type="button"
          phx-click="save_changes"
          phx-target={@myself}
          theme={if @current_assessment_view == "student", do: "student", else: "white"}
          disabled={MapSet.size(@invalid_changes_set) > 0}
          class="disabled:opacity-40"
        >
          {if @current_assessment_view == "student",
            do: gettext("Save self-assessments"),
            else: gettext("Save")}
        </.button>
      </.fixed_bar>
      <.live_component
        :if={@assessment_point_entry}
        module={EntryDetailsOverlayComponent}
        id={"#{@id}-entry-details-overlay"}
        entry={@assessment_point_entry}
        current_user={@current_user}
        on_cancel={JS.push("close_entry_details_overlay", target: @myself)}
        notify_component={@myself}
      />
    </div>
    """
  end

  # function components

  attr :id, :string, required: true
  attr :ap_header, :any, required: true
  attr :assessment_view, :string, required: true

  def assessment_point_header(assigns) do
    {header_struct, assessment_points_count} = assigns.ap_header

    grid_column_span_style =
      "grid-column: span #{assessment_points_count} / span #{assessment_points_count}"

    assigns =
      assigns
      |> assign(:header_struct, header_struct)
      |> assign(:grid_column_span_style, grid_column_span_style)

    ~H"""
    <div id={@id} class="group pt-2 px-2" style={@grid_column_span_style}>
      <div class="h-full pb-2 border-b border-ltrn-light" style={@grid_column_span_style}>
        <span class="flex items-center w-full text-sm font-display font-bold truncate">
          <%= if match?(%Moment{}, @header_struct) do %>
            {@header_struct.name}
          <% else %>
            {gettext("Goals assessment")}
          <% end %>
        </span>
      </div>
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true
  attr :assessment_view, :string, required: true
  attr :url_params, :map, required: true
  attr :id, :string, required: true
  attr :myself, :any, required: true

  def assessment_point(assigns) do
    display_name =
      assigns.assessment_point.name || assigns.assessment_point.curriculum_item.name

    tooltip_name =
      if assigns.assessment_point.name do
        assigns.assessment_point.name
      else
        ci = assigns.assessment_point.curriculum_item
        "#{ci.curriculum_component.name}: #{ci.name}"
      end

    assigns =
      assigns
      |> assign(:display_name, display_name)
      |> assign(:tooltip_name, tooltip_name)

    ~H"""
    <div id={@id} class="flex flex-col p-1">
      <div class="flex flex-1 gap-1">
        <.link
          patch={"?#{URI.encode_query(Map.put(@url_params, "edit_assessment_point", @assessment_point.id))}"}
          class="flex flex-1 gap-2 p-1 rounded-sm hover:bg-ltrn-lightest"
        >
          <div class="flex flex-col flex-1">
            <div class={if(@assessment_point.is_hidden, do: "opacity-50")}>
              <div class="flex items-center gap-2 mb-1">
                <%= if @assessment_point.scale.type == "numeric" do %>
                  <.badge>{@assessment_point.scale.max_score}</.badge>
                <% else %>
                  <.ordinal_scale_range scale={@assessment_point.scale} />
                <% end %>
              </div>
              <p class="flex-1 font-sans text-sm line-clamp-2">
                {@display_name}
              </p>
            </div>
          </div>
          <div class="shrink-0 flex flex-col gap-1 text-ltrn-light">
            <.icon
              name="hero-view-columns-micro"
              class={["size-3", if(@assessment_point.rubric_id, do: "text-ltrn-primary")]}
            />
            <.icon
              name="hero-light-bulb-micro"
              class={["size-3", if(@assessment_point.is_differentiation, do: "text-ltrn-diff-accent")]}
            />
            <.icon
              name="hero-calculator-micro"
              class={["size-3", if(@assessment_point.composition_type, do: "text-ltrn-primary")]}
            />
          </div>
        </.link>
        <.tooltip id={"assessment-point-#{@assessment_point.id}-tooltip"}>
          <p>{@tooltip_name}</p>
          <p class="mt-2">
            <%= if @assessment_point.scale.type == "numeric" do %>
              {gettext("Max score: %{max}", max: @assessment_point.scale.max_score)}
            <% else %>
              {@assessment_point.scale.name}
            <% end %>
          </p>
          <p :if={@assessment_point.rubric_id} class="mt-2">{gettext("Uses rubric")}</p>
          <p :if={@assessment_point.is_differentiation} class="mt-2">
            {gettext("Differentiation assessment")}
          </p>
          <p :if={@assessment_point.composition_type == :sum} class="mt-2">
            {gettext("Sum-based grade composition")}
          </p>
          <p :if={@assessment_point.composition_type == :avg} class="mt-2">
            {gettext("Average-based grade composition")}
          </p>
          <.markdown
            :if={@assessment_point.report_info}
            text={@assessment_point.report_info}
            invert
            strip_tags
            size="sm"
            class="mt-2"
          />
        </.tooltip>
      </div>
      <div class="relative mt-2">
        <%= if @assessment_point.is_hidden do %>
          <.button
            type="button"
            size="xs"
            theme="primary"
            icon_name="hero-eye-slash-micro"
            class="w-full"
            phx-click="toggle_hidden"
            phx-value-id={@assessment_point.id}
            phx-target={@myself}
          >
            {gettext("Hidden")}
          </.button>
          <.tooltip id={"assessment-point-#{@assessment_point.id}-hide-flag-tooltip"}>
            {gettext("Students won't see marking results for this assessment point.")}
          </.tooltip>
        <% else %>
          <.button
            type="button"
            size="xs"
            theme="ghost"
            icon_name="hero-eye-micro"
            class="w-full"
            phx-click="toggle_hidden"
            phx-value-id={@assessment_point.id}
            phx-target={@myself}
          >
            {gettext("Hide")}
          </.button>
          <.tooltip id={"assessment-point-#{@assessment_point.id}-hide-flag-tooltip"}>
            {gettext(
              "When hidden, students won't see marking results for this assessment point. Use this while marking is in progress."
            )}
          </.tooltip>
        <% end %>
      </div>
      <.compare_header :if={@assessment_view == "compare"} />
    </div>
    """
  end

  def compare_header(assigns) do
    ~H"""
    <div class="flex gap-1 w-full mt-2 font-sans text-xs">
      <div class="flex-1 pb-1 border-b-2 border-ltrn-staff-accent text-center text-ltrn-staff-dark">
        {gettext("Teacher")}
      </div>
      <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-center text-ltrn-student-dark">
        {gettext("Student")}
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :current_scope, Scope, required: true
  attr :student, Student, required: true
  attr :entries, :list, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :current_assessment_view, :string, required: true
  attr :view_bg, :string, required: true
  attr :current_user, User, required: true

  def student_entries(assigns) do
    ~H"""
    <div
      id={@id}
      data-grid-row
      class="grid grid-cols-subgrid"
      style={"grid-column: span #{length(@entries) + 1} / span #{length(@entries) + 1}"}
    >
      <div class={"sticky left-0 z-10 pl-6 py-2 pr-2 #{@view_bg}"}>
        <.profile_picture_with_name
          profile_name={@student.name}
          picture_url={@student.profile_picture_url}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
          navigate={~p"/school/students/#{@student}"}
        />
      </div>
      <div :for={entry <- @entries} data-grid-cell class="p-2">
        <.live_component
          module={EntryCellComponent}
          current_scope={@current_scope}
          id={"student-#{@student.id}-entry-for-#{entry.assessment_point_id}"}
          class="w-full h-full"
          entry={entry}
          view={@current_assessment_view}
          allow_edit={true}
          notify_component={@myself}
        />
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:classes_ids, [])
      |> assign(:strand_id, nil)
      |> assign(:entries_changes_map, %{})
      |> assign(:invalid_changes_set, MapSet.new())
      |> assign(:assessment_point_entry, nil)
      |> assign(:has_entry_details_change, false)
      |> assign(:has_assessment_points, false)
      |> assign(:assessment_points_count, 0)
      |> assign(:assessment_points_columns_grid, "")
      |> assign(:url_params, %{})
      |> assign(:filter_assessment_points_ids, nil)
      |> stream_configure(
        :assessment_point_headers,
        dom_id: fn
          {%Moment{} = moment, _count} -> "ap-group-moment-#{moment.id}"
          {%Strand{} = strand, _count} -> "ap-group-strand-#{strand.id}"
        end
      )
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {EntryCellComponent, {:change, :cancel, composite_id, _, _}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, &Map.drop(&1, [composite_id]))
      |> update(:invalid_changes_set, &MapSet.delete(&1, composite_id))

    {:ok, socket}
  end

  def update(
        %{action: {EntryCellComponent, {:change, change_type, composite_id, _entry_id, params}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, &Map.put(&1, composite_id, params))
      |> update(:invalid_changes_set, fn set ->
        if change_type == :invalid,
          do: MapSet.put(set, composite_id),
          else: MapSet.delete(set, composite_id)
      end)

    {:ok, socket}
  end

  def update(
        %{action: {EntryCellComponent, {:view_details, entry}}},
        socket
      ) do
    socket =
      socket
      |> assign(:assessment_point_entry, entry)

    {:ok, socket}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, {msg_type, _}}},
        socket
      )
      when msg_type in [:created_entry, :change, :created_attachment, :deleted_attachment] do
    {:ok, assign(socket, :has_entry_details_change, true)}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, {:delete, _entry}}},
        socket
      ) do
    socket =
      socket
      |> assign(:assessment_point_entry, nil)
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:has_entry_details_change, false)

    {:ok, socket}
  end

  def update(
        %{action: {EntryDetailsOverlayComponent, _}},
        socket
      ),
      do: {:ok, socket}

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:no_class_action, fn -> [] end)
      |> assign_view_bg()

    socket =
      if socket.assigns.classes_ids == [] do
        socket
      else
        socket
        |> stream_assessment_points()
        |> stream_students_entries()
      end

    {:ok, socket}
  end

  defp assign_view_bg(socket) do
    view_bg =
      case socket.assigns.current_assessment_view do
        "student" -> "bg-ltrn-student-lightest"
        _ -> "bg-white"
      end

    assign(socket, :view_bg, view_bg)
  end

  defp stream_assessment_points(socket) do
    {all_headers, all_assessment_points} =
      Assessments.list_strand_assessment_points(socket.assigns.strand_id)

    {assessment_point_headers, assessment_points} =
      case socket.assigns.filter_assessment_points_ids do
        nil ->
          {all_headers, all_assessment_points}

        filter_ids ->
          filtered_aps = Enum.filter(all_assessment_points, &(&1.id in filter_ids))
          {recompute_headers(all_headers, filtered_aps), filtered_aps}
      end

    assessment_points_count = length(assessment_points)

    socket
    |> stream(:assessment_points, assessment_points, reset: true)
    |> stream(:assessment_point_headers, assessment_point_headers, reset: true)
    |> assign(:assessment_points_count, assessment_points_count)
    |> assign(:assessment_points_columns_grid, "repeat(#{assessment_points_count}, 12rem)")
    |> assign(:has_assessment_points, assessment_points != [])
  end

  defp recompute_headers(all_headers, filtered_aps) do
    filtered_count_map =
      filtered_aps
      |> Enum.group_by(& &1.moment_id)
      |> Map.new(fn {moment_id, aps} -> {moment_id, length(aps)} end)

    all_headers
    |> Enum.map(fn {struct, _} ->
      key =
        case struct do
          %Moment{} -> struct.id
          _ -> nil
        end

      {struct, Map.get(filtered_count_map, key, 0)}
    end)
    |> Enum.reject(fn {_, count} -> count == 0 end)
  end

  defp stream_students_entries(socket) do
    students_entries =
      Assessments.list_strand_students_entries(
        socket.assigns.strand_id,
        classes_ids: socket.assigns.classes_ids,
        load_profile_picture_from_cycle_id:
          socket.assigns.current_user.current_profile.current_school_cycle.id,
        active_students_only: true,
        check_if_has_evidences: true
      )

    students_entries =
      case socket.assigns.filter_assessment_points_ids do
        nil ->
          students_entries

        filter_ids ->
          Enum.map(students_entries, fn {student, entries} ->
            {student, Enum.filter(entries, &(&1.assessment_point_id in filter_ids))}
          end)
      end

    socket
    |> stream(:students_entries, students_entries, reset: true)
  end

  # event handlers

  @impl true
  def handle_event("save_changes", _params, socket) do
    if MapSet.size(socket.assigns.invalid_changes_set) > 0 do
      {:noreply, socket}
    else
      %{
        entries_changes_map: entries_changes_map,
        current_user: current_user
      } = socket.assigns

      changes = Map.values(entries_changes_map)

      socket =
        case Assessments.save_assessment_point_entries(changes,
               log_profile_id: current_user.current_profile_id
             ) do
          {:ok, count} ->
            msg = ngettext("1 entry updated", "%{count} entries updated", count)
            put_flash(socket, :info, msg)

          {:error, _changeset} ->
            msg = gettext("Error updating assessment point entries")
            put_flash(socket, :error, msg)
        end
        |> push_navigate(to: socket.assigns.navigate)

      {:noreply, socket}
    end
  end

  def handle_event("toggle_hidden", %{"id" => id}, socket) do
    ap =
      Assessments.get_assessment_point!(
        String.to_integer(id),
        preloads: [curriculum_item: :curriculum_component, scale: :ordinal_values]
      )

    socket =
      case Assessments.update_assessment_point(ap, %{is_hidden: !ap.is_hidden}) do
        {:ok, updated_ap} ->
          stream_insert(socket, :assessment_points, updated_ap)

        {:error, _changeset} ->
          put_flash(socket, :error, gettext("Error updating assessment point"))
      end

    {:noreply, socket}
  end

  def handle_event("close_entry_details_overlay", _, socket) do
    socket =
      socket
      |> assign(:assessment_point_entry, nil)

    socket =
      if socket.assigns.has_entry_details_change do
        socket
        |> stream_assessment_points()
        |> stream_students_entries()
        |> assign(:has_entry_details_change, false)
      else
        socket
      end

    {:noreply, socket}
  end
end
