defmodule LantternWeb.Assessments.AssessmentsGridComponent do
  @moduledoc """
  This component handles the loading and rendering of the assessment
  points and its entries in the context of a strand or a moment.

  The component also handles the entries update process, including
  the entry details view (with comments and evidences).

  #### Expected external assigns

      attr :current_user, User
      attr :current_assessment_group_by, :string
      attr :current_assessment_view, :string
      attr :classes_ids, :list, doc: "list of classes_ids to filter results"
      attr :strand_id, :integer, doc: "defines a strand grid view"
      attr :moment_id, :integer, doc: "defines a moment grid view. will override the strand id"
      attr :class, :any
      attr :navigate, :string, doc: "defines push_navigate target"

  """

  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.Assessments.EntryCellComponent
  alias LantternWeb.Assessments.EntryDetailsOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <%!-- if no assessment points, render empty state --%>
        <div :if={!@has_assessment_points} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No assessment points for this strand yet") %></.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={@classes_ids == [] && @has_assessment_points}
          class="p-10 rounded shadow-xl bg-white"
        >
          <p class="mb-6 font-bold text-ltrn-subtle"><%= gettext("Current assessment points") %></p>
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <.no_class_assessment_point
              :for={{_dom_id, assessment_point} <- @streams.assessment_points}
              assessment_point={assessment_point}
            />
          </ol>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div :if={@classes_ids != [] && @has_assessment_points}>
        <div class={[
          "relative w-full max-h-screen border rounded shadow-xl #{@view_bg} overflow-x-auto",
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
              <div class={[
                "sticky left-0 #{@view_bg}",
                if(@moment_id || !is_nil(@current_assessment_group_by), do: "row-span-2")
              ]}>
              </div>
              <div
                :if={@moment_id || !is_nil(@current_assessment_group_by)}
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
                  is_moment={@moment_id != nil}
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
                student={student}
                entries={entries}
                myself={@myself}
                current_assessment_view={@current_assessment_view}
                view_bg={@view_bg}
                current_user={@current_user}
                is_moment={@moment_id != nil}
              />
            </div>
          </div>
        </div>
      </div>
      <.fixed_bar :if={@entries_changes_map != %{}} class="flex items-center gap-6">
        <div class="flex-1 flex items-center gap-4 text-sm">
          <p class="text-white text-nowrap">
            <%= ngettext("1 change", "%{count} changes", map_size(@entries_changes_map)) %>
          </p>
          <p
            :if={@current_assessment_view == "student"}
            class="flex items-center gap-2 font-bold text-ltrn-student-accent"
          >
            <.icon name="hero-information-circle" class="w-6 h-6" />
            <%= gettext("You are registering students self-assessments") %>
          </p>
        </div>
        <.button
          phx-click={JS.navigate(@navigate)}
          theme="ghost"
          data-confirm={gettext("Are you sure?")}
        >
          <%= gettext("Discard") %>
        </.button>
        <.button
          type="button"
          phx-click="save_changes"
          phx-target={@myself}
          theme={if @current_assessment_view == "student", do: "student"}
        >
          <%= if @current_assessment_view == "student",
            do: gettext("Save self-assessments"),
            else: gettext("Save") %>
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

  attr :assessment_point, :any, required: true

  def no_class_assessment_point(assigns) do
    assessment_points =
      case assigns.assessment_point do
        {_group_by_struct, assessment_points} -> assessment_points
        %AssessmentPoint{} = assessment_point -> [assessment_point]
      end

    assigns = assign(assigns, :assessment_points, assessment_points)

    ~H"""
    <li :for={assessment_point <- @assessment_points} id={"no-class-#{assessment_point.id}"}>
      <%= case assessment_point do
        %{name: name} when not is_nil(name) ->
          name

        %{curriculum_item: %CurriculumItem{} = curriculum_item} ->
          gettext("Strand final assessment for %{item}", item: curriculum_item.name)

        _final_assessment_without_curriculum_preload ->
          gettext("Strand final assessment for curriculum item")
      end %>
    </li>
    """
  end

  attr :id, :string, required: true
  attr :ap_header, :any, required: true
  attr :assessment_view, :string, required: true

  def assessment_point_header(%{ap_header: %AssessmentPoint{}} = assigns) do
    # when in a moment grid, the header is the assessment point

    # TODO: make the patch dynamic (allow parent control via attrs)
    ~H"""
    <div class="flex flex-col p-2" id={@id}>
      <.link
        patch={
          ~p"/strands/moment/#{@ap_header.moment_id}/assessment?edit_assessment_point=#{@ap_header.id}"
        }
        class="flex-1 p-1 rounded text-sm font-bold line-clamp-2 hover:bg-ltrn-mesh-cyan"
        title={@ap_header.name}
      >
        <%= @ap_header.name %>
      </.link>
      <hr class="h-px mt-2 bg-ltrn-light" />
    </div>
    """
  end

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
        <.assessment_point_header_struct header_struct={@header_struct} />
      </div>
    </div>
    """
  end

  attr :header_struct, :any, required: true, doc: "moment, strand, or curriculum item"

  def assessment_point_header_struct(%{header_struct: %Moment{}} = assigns) do
    ~H"""
    <.link
      class="flex items-center w-full h-full p-1 rounded text-sm font-display font-bold truncate hover:bg-ltrn-mesh-cyan"
      navigate={~p"/strands/moment/#{@header_struct.id}/assessment"}
    >
      <%= @header_struct.name %>
    </.link>
    """
  end

  def assessment_point_header_struct(%{header_struct: %CurriculumItem{}} = assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <.badge class="truncate">
        <%= @header_struct.curriculum_component.name %>
      </.badge>
      <.badge :if={@header_struct.is_differentiation} theme="diff">
        <%= gettext("Diff") %>
      </.badge>
    </div>
    <p class="mt-1 text-sm line-clamp-2" title={@header_struct.name}>
      <%= @header_struct.name %>
    </p>
    """
  end

  def assessment_point_header_struct(%{header_struct: %Strand{}} = assigns) do
    ~H"""
    <p class="flex items-center h-full text-sm font-display font-bold">
      <%= gettext("Goals assessment") %>
    </p>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true
  attr :assessment_view, :string, required: true
  attr :id, :string, required: true
  attr :is_moment, :boolean, required: true

  def assessment_point(assigns) do
    ~H"""
    <div id={@id} class="flex flex-col p-2">
      <div class="flex-1">
        <.assessment_point_struct assessment_point={@assessment_point} is_moment={@is_moment} />
      </div>
      <.compare_header :if={@assessment_view == "compare"} />
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true
  attr :is_moment, :boolean, required: true

  def assessment_point_struct(
        %{
          assessment_point: %{curriculum_item: %CurriculumItem{}, moment_id: moment_id},
          is_moment: false
        } = assigns
      )
      when not is_nil(moment_id) do
    tooltip =
      """
      #{assigns.assessment_point.name}

      (#{assigns.assessment_point.curriculum_item.curriculum_component.name}) #{assigns.assessment_point.curriculum_item.name}
      """

    assigns = assign(assigns, :tooltip, tooltip)

    ~H"""
    <div class="flex flex-col">
      <div :if={@assessment_point.is_differentiation} class="mb-1">
        <.badge theme="diff"><%= gettext("Diff") %></.badge>
      </div>
      <p
        class={[
          "flex-1 text-sm",
          if(@assessment_point.is_differentiation, do: "line-clamp-2", else: "line-clamp-3")
        ]}
        title={@tooltip}
      >
        <%= @assessment_point.name %>
      </p>
    </div>
    """
  end

  def assessment_point_struct(
        %{assessment_point: %{curriculum_item: %CurriculumItem{}}, is_moment: false} = assigns
      ) do
    ~H"""
    <.link
      patch={
        ~p"/strands/#{@assessment_point.strand_id}/assessment?edit_assessment_point=#{@assessment_point.id}"
      }
      class="flex flex-col p-1 rounded hover:bg-ltrn-mesh-cyan"
    >
      <div class="flex items-center gap-2">
        <.badge class="truncate">
          <%= @assessment_point.curriculum_item.curriculum_component.name %>
        </.badge>
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
        <.icon :if={@assessment_point.rubric_id} name="hero-view-columns-micro" class="w-4 h-4" />
      </div>
      <p class="flex-1 mt-1 text-sm line-clamp-2" title={@assessment_point.curriculum_item.name}>
        <%= @assessment_point.curriculum_item.name %>
      </p>
    </.link>
    """
  end

  def assessment_point_struct(
        %{assessment_point: %{curriculum_item: %CurriculumItem{}}} = assigns
      ) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex items-center gap-2">
        <.badge class="truncate">
          <%= @assessment_point.curriculum_item.curriculum_component.name %>
        </.badge>
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
        <.icon :if={@assessment_point.rubric_id} name="hero-view-columns-micro" class="w-4 h-4" />
      </div>
      <p class="flex-1 mt-1 text-sm line-clamp-2" title={@assessment_point.curriculum_item.name}>
        <%= @assessment_point.curriculum_item.name %>
      </p>
    </div>
    """
  end

  def assessment_point_struct(%{assessment_point: %{moment: %Moment{}}} = assigns) do
    ~H"""
    <div class="text-sm whitespace-nowrap">
      <.link
        class="block w-full p-1 rounded overflow-hidden hover:bg-ltrn-mesh-cyan"
        title={"#{@assessment_point.moment.name}\n\n#{@assessment_point.name}"}
        navigate={~p"/strands/moment/#{@assessment_point.moment.id}/assessment"}
      >
        <div class="flex items-center gap-2">
          <.icon :if={@assessment_point.rubric_id} name="hero-view-columns-micro" class="w-4 h-4" />
          <span class="font-bold"><%= @assessment_point.moment.name %></span> <br />
        </div>
        <span class="text-xs"><%= @assessment_point.name %></span>
      </.link>
    </div>
    """
  end

  def assessment_point_struct(%{assessment_point: %{strand_id: strand_id}} = assigns)
      when not is_nil(strand_id) do
    ~H"""
    <.link
      patch={
        ~p"/strands/#{@assessment_point.strand_id}/assessment?edit_assessment_point=#{@assessment_point.id}"
      }
      class="flex flex-col p-1 rounded hover:bg-ltrn-mesh-cyan"
    >
      <div class="whitespace-nowrap overflow-hidden">
        <div class="flex items-center gap-2">
          <.icon :if={@assessment_point.rubric_id} name="hero-view-columns-micro" class="w-4 h-4" />
          <span class="font-bold"><%= gettext("Goal assessment") %></span>
        </div>
        <span class="text-xs"><%= gettext("(Strand final assessment)") %></span>
      </div>
    </.link>
    """
  end

  def compare_header(assigns) do
    ~H"""
    <div class="flex gap-1 w-full mt-2">
      <div class="flex-1 pb-1 border-b-2 border-ltrn-staff-accent text-xs text-center text-ltrn-staff-dark">
        <%= gettext("Teacher") %>
      </div>
      <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-xs text-center text-ltrn-student-dark">
        <%= gettext("Student") %>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :student, Student, required: true
  attr :entries, :list, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :current_assessment_view, :string, required: true
  attr :view_bg, :string, required: true
  attr :current_user, User, required: true
  attr :is_moment, :boolean, required: true

  def student_entries(assigns) do
    ~H"""
    <div
      id={@id}
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
      <div :for={entry <- @entries} class="p-2">
        <.live_component
          module={EntryCellComponent}
          id={"student-#{@student.id}-entry-for-#{entry.assessment_point_id}"}
          class="w-full h-full"
          entry={entry}
          view={@current_assessment_view}
          allow_edit={@is_moment || entry.is_strand_entry}
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
      |> assign(:moment_id, nil)
      |> assign(:strand_id, nil)
      |> assign(:entries_changes_map, %{})
      |> assign(:assessment_point_entry, nil)
      |> assign(:has_entry_details_change, false)
      |> stream_configure(
        :assessment_point_headers,
        dom_id: fn
          {%CurriculumItem{} = ci, _count} -> "ap-group-curriculum-item-#{ci.id}"
          {%Moment{} = moment, _count} -> "ap-group-moment-#{moment.id}"
          {%Strand{} = strand, _count} -> "ap-group-strand-#{strand.id}"
          %AssessmentPoint{} = assessment_point -> "header-#{assessment_point.id}"
          _ -> ""
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
      |> update(:entries_changes_map, fn entries_changes_map ->
        entries_changes_map
        |> Map.drop([composite_id])
      end)

    {:ok, socket}
  end

  def update(
        %{action: {EntryCellComponent, {:change, _type, composite_id, _entry_id, params}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, fn entries_changes_map ->
        entries_changes_map
        |> Map.put(composite_id, params)
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
      |> assign_view_bg()
      |> stream_assessment_points()
      |> stream_students_entries()

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
    {assessment_point_headers, assessment_points} =
      case socket.assigns do
        %{moment_id: moment_id} when not is_nil(moment_id) ->
          assessment_points =
            Assessments.list_assessment_points(
              moments_ids: [moment_id],
              preloads: [scale: :ordinal_values, curriculum_item: :curriculum_component]
            )

          # when in moment view, we use the assessment point as headers
          {assessment_points, assessment_points}

        %{strand_id: strand_id} ->
          Assessments.list_strand_assessment_points(
            strand_id,
            socket.assigns.current_assessment_group_by
          )
      end

    assessment_points_count = length(assessment_points)

    assessment_points_columns_grid =
      case socket.assigns do
        %{current_assessment_view: "compare"} ->
          "repeat(#{assessment_points_count}, 12rem)"

        %{moment_id: moment_id} when moment_id != nil ->
          "repeat(#{assessment_points_count}, 15rem)"

        _ ->
          assessment_points
          |> Enum.map_join(" ", fn
            %{strand_id: id} when not is_nil(id) -> "15rem"
            _ -> "6rem"
          end)
      end

    socket
    |> stream(:assessment_points, assessment_points)
    |> stream(:assessment_point_headers, assessment_point_headers)
    |> assign(:assessment_points_count, length(assessment_points))
    |> assign(:assessment_points_columns_grid, assessment_points_columns_grid)
    |> assign(:has_assessment_points, assessment_points != [])
  end

  defp stream_students_entries(socket) do
    students_entries =
      case socket.assigns do
        %{moment_id: moment_id} when moment_id != nil ->
          Assessments.list_moment_students_entries(
            moment_id,
            classes_ids: socket.assigns.classes_ids,
            load_profile_picture_from_cycle_id:
              socket.assigns.current_user.current_profile.current_school_cycle.id,
            active_students_only: true,
            check_if_has_evidences: true
          )

        _ ->
          Assessments.list_strand_students_entries(
            socket.assigns.strand_id,
            socket.assigns.current_assessment_group_by,
            classes_ids: socket.assigns.classes_ids,
            load_profile_picture_from_cycle_id:
              socket.assigns.current_user.current_profile.current_school_cycle.id,
            active_students_only: true,
            check_if_has_evidences: true
          )
      end

    socket
    |> stream(:students_entries, students_entries)
  end

  # event handlers

  @impl true
  def handle_event("save_changes", _params, socket) do
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
