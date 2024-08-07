defmodule LantternWeb.MomentLive.AssessmentComponent do
  alias Lanttern.Identity.User
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Filters
  alias Lanttern.Schools.Student

  import LantternWeb.AssessmentsHelpers, only: [save_entry_editor_component_changes: 2]
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3, assign_user_filters: 4]
  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.EntryDetailsComponent
  alias LantternWeb.Assessments.EntryCellComponent
  alias LantternWeb.Assessments.AssessmentPointFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pt-10 pb-20">
      <.responsive_container>
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <%= gettext("Assessing") %>
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= gettext("Select a class") %>
              </button>
              <%= gettext("to assess students") %>
            </p>
          <% end %>
          <div class="shrink-0 flex items-center gap-6">
            <.collection_action
              :if={@assessment_points_count > 1}
              type="button"
              phx-click={JS.exec("data-show", to: "#moment-assessment-points-order-overlay")}
              icon_name="hero-arrows-up-down"
            >
              <%= gettext("Reorder") %>
            </.collection_action>
            <.collection_action
              type="link"
              patch={~p"/strands/moment/#{@moment}/assessment_point/new"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Create assessment point") %>
            </.collection_action>
          </div>
        </div>
        <div class="flex mt-6">
          <.assessment_view_dropdow
            current_assessment_view={@current_assessment_view}
            myself={@myself}
          />
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div :if={@assessment_points_count == 0} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No assessment points for this moment yet") %></.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={@selected_classes == [] && @assessment_points_count > 0}
          class="p-10 mt-4 rounded shadow-xl bg-white"
        >
          <p class="mb-6 font-bold text-ltrn-subtle"><%= gettext("Current assessment points") %></p>
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <li :for={{dom_id, assessment_point} <- @streams.assessment_points} id={dom_id}>
              <.link
                patch={~p"/strands/moment/#{@moment}/assessment_point/#{assessment_point}"}
                class="hover:underline"
              >
                <%= assessment_point.name %>
              </.link>
            </li>
          </ol>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div :if={@selected_classes != [] && @assessment_points_count > 0} class="px-6 mt-6">
        <div class={[
          "relative w-full max-h-[calc(100vh-4rem)] border mt-6 rounded shadow-xl #{@view_bg} overflow-x-auto",
          if(@current_assessment_view == "student",
            do: "border-ltrn-student-accent",
            else: "border-transparent"
          )
        ]}>
          <div
            class="relative grid pb-4"
            style={"grid-template-columns: 15rem #{@assessment_points_columns_grid}"}
          >
            <div
              class={"sticky top-0 z-20 grid grid-cols-subgrid pt-4 #{@view_bg}"}
              style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
            >
              <div class={"sticky left-0 row-span-2 #{@view_bg}"}></div>
              <div
                id="grid-assessment-points-names"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point_name
                  :for={{dom_id, assessment_point} <- @streams.assessment_points}
                  id={dom_id}
                  assessment_point={assessment_point}
                  moment_id={@moment.id}
                />
              </div>
              <div
                id="grid-assessment-points"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point_curriculum
                  :for={{dom_id, assessment_point} <- @streams.assessment_points}
                  id={dom_id}
                  assessment_point={assessment_point}
                  assessment_view={@current_assessment_view}
                  moment_id={@moment.id}
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
              />
            </div>
          </div>
        </div>
      </div>
      <.slide_over
        :if={@live_action in [:new_assessment_point, :edit_assessment_point]}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/moment/#{@moment}?tab=assessment")}
      >
        <:title><%= gettext("Assessment Point") %></:title>
        <.live_component
          module={AssessmentPointFormComponent}
          id={Map.get(@assessment_point, :id) || :new}
          curriculum_from_strand_id={@moment.strand_id}
          notify_component={@myself}
          assessment_point={@assessment_point}
          navigate={~p"/strands/moment/#{@moment}?tab=assessment"}
        />
        <div
          :if={@delete_assessment_point_error}
          class="flex items-start gap-4 p-4 rounded-sm text-sm text-rose-600 bg-rose-100"
        >
          <div>
            <p><%= @delete_assessment_point_error %></p>
            <button
              type="button"
              phx-click="delete_assessment_point_and_entries"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
              class="mt-4 font-display font-bold underline"
            >
              <%= gettext("Understood. Delete anyway") %>
            </button>
          </div>
          <button
            type="button"
            phx-click="dismiss_assessment_point_error"
            phx-target={@myself}
            class="shrink-0"
          >
            <span class="sr-only"><%= gettext("dismiss") %></span>
            <.icon name="hero-x-mark" />
          </button>
        </div>
        <:actions_left :if={not is_nil(@assessment_point_id)}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_assessment_point"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#assessment-point-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="assessment-point-form" phx-disable-with="Saving...">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.live_component
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        filter_type={:classes}
        filter_opts={[strand_id: @moment.strand_id]}
        navigate={~p"/strands/moment/#{@moment}?tab=assessment"}
      />
      <.slide_over :if={@assessment_points_count > 1} id="moment-assessment-points-order-overlay">
        <:title><%= gettext("Assessment Points Order") %></:title>
        <ol>
          <li
            :for={{assessment_point, i} <- @sortable_assessment_points}
            id={"sortable-assessment-point-#{assessment_point.id}"}
            class="flex items-center gap-4 mb-4"
          >
            <div class="flex-1 flex items-start p-4 rounded bg-white shadow-lg">
              <%= "#{i + 1}. #{assessment_point.name}" %>
            </div>
            <div class="shrink-0 flex flex-col gap-2">
              <.icon_button
                type="button"
                sr_text={gettext("Move assessment point up")}
                name="hero-chevron-up-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i == 0}
                phx-click={JS.push("assessment_point_position", value: %{from: i, to: i - 1})}
                phx-target={@myself}
              />
              <.icon_button
                type="button"
                sr_text={gettext("Move assessment point down")}
                name="hero-chevron-down-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i + 1 == @assessment_points_count}
                phx-click={JS.push("assessment_point_position", value: %{from: i, to: i + 1})}
                phx-target={@myself}
              />
            </div>
          </li>
        </ol>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-assessment-points-order-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="button" phx-click="save_order" phx-target={@myself}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.slide_over
        :if={@assessment_point_entry}
        id="entry-details-overlay"
        show={true}
        on_cancel={JS.push("close_entry_details_overlay", target: @myself)}
      >
        <:title><%= gettext("Assessment point entry details") %></:title>
        <.live_component
          module={EntryDetailsComponent}
          id={@assessment_point_entry.id}
          entry={@assessment_point_entry}
          current_user={@current_user}
          notify_component={@myself}
        />
      </.slide_over>
      <.fixed_bar :if={@entries_changes_map != %{}} class="flex items-center gap-6">
        <p class="flex-1 text-sm text-white">
          <%= ngettext("1 change", "%{count} changes", map_size(@entries_changes_map)) %>
        </p>
        <.button
          phx-click={JS.navigate(~p"/strands/moment/#{@moment}?tab=assessment")}
          theme="ghost"
          data-confirm={gettext("Are you sure?")}
        >
          <%= gettext("Discard") %>
        </.button>
        <.button type="button" phx-click="save_changes" phx-target={@myself}>
          <%= gettext("Save") %>
        </.button>
      </.fixed_bar>
    </div>
    """
  end

  # function components

  attr :current_assessment_view, :string, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def assessment_view_dropdow(assigns) do
    {theme, text} =
      case assigns.current_assessment_view do
        "teacher" -> {"teacher", gettext("Assessed by teacher")}
        "student" -> {"student", gettext("Assessed by students")}
        "compare" -> {"primary", gettext("Compare teacher/students")}
      end

    assigns =
      assigns
      |> assign(:theme, theme)
      |> assign(:text, text)

    ~H"""
    <div class="relative">
      <.badge_button id="view-dropdown-button" icon_name="hero-chevron-down-mini" theme={@theme}>
        <%= @text %>
      </.badge_button>
      <.dropdown_menu id="view-dropdown" button_id="view-dropdown-button" z_index="30">
        <:item
          text={gettext("Assessed by teacher")}
          on_click={JS.push("change_view", value: %{"view" => "teacher"}, target: @myself)}
        />
        <:item
          text={gettext("Assessed by students")}
          on_click={JS.push("change_view", value: %{"view" => "student"}, target: @myself)}
        />
        <:item
          text={gettext("Compare teacher and students assessments")}
          on_click={JS.push("change_view", value: %{"view" => "compare"}, target: @myself)}
        />
      </.dropdown_menu>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :moment_id, :integer, required: true

  def assessment_point_name(assigns) do
    ~H"""
    <div class="flex flex-col p-2" id={"name-#{@id}"}>
      <.link
        patch={~p"/strands/moment/#{@moment_id}/assessment_point/#{@assessment_point}"}
        class="flex-1 p-1 rounded text-sm font-bold line-clamp-2 hover:bg-ltrn-mesh-cyan"
        title={@assessment_point.name}
      >
        <%= @assessment_point.name %>
      </.link>
      <hr class="h-px mt-2 bg-ltrn-light" />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :moment_id, :integer, required: true
  attr :assessment_view, :string, required: true

  def assessment_point_curriculum(assigns) do
    ~H"""
    <div class="flex flex-col px-2 pb-2" id={@id}>
      <div class="flex gap-2">
        <.badge class="truncate">
          <%= @assessment_point.curriculum_item.curriculum_component.name %>
        </.badge>
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
      </div>
      <p class="flex-1 mt-1 text-sm line-clamp-2" title={@assessment_point.curriculum_item.name}>
        <%= @assessment_point.curriculum_item.name %>
      </p>
      <div :if={@assessment_view == "compare"} class="flex gap-1 w-full mt-2">
        <div class="flex-1 pb-1 border-b-2 border-ltrn-teacher-accent text-xs text-center text-ltrn-teacher-dark">
          <%= gettext("Teacher") %>
        </div>
        <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-xs text-center text-ltrn-student-dark">
          <%= gettext("Student") %>
        </div>
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

  def student_entries(assigns) do
    ~H"""
    <div
      id={@id}
      class="grid grid-cols-subgrid"
      style={"grid-column: span #{length(@entries) + 1} / span #{length(@entries) + 1}"}
    >
      <div class={"sticky left-0 z-10 pl-6 py-2 pr-2 #{@view_bg}"}>
        <.profile_icon_with_name
          profile_name={@student.name}
          extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
        />
      </div>
      <div :for={entry <- @entries} class="p-2">
        <.live_component
          module={EntryCellComponent}
          id={"student-#{@student.id}-entry-for-#{entry.assessment_point_id}"}
          class="w-full h-full"
          entry={entry}
          view={@current_assessment_view}
          allow_edit
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
      |> stream_configure(
        :students_entries,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )
      |> assign(:delete_assessment_point_error, nil)
      |> assign(:classes, nil)
      |> assign(:classes_ids, [])
      |> assign(:entries_changes_map, %{})
      |> assign(:assessment_point_entry, nil)
      |> assign(:has_entry_details_change, false)

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
        %{action: {EntryCellComponent, {:change, type, composite_id, entry_id, params}}},
        socket
      ) do
    socket =
      socket
      |> update(:entries_changes_map, fn entries_changes_map ->
        entries_changes_map
        |> Map.put(composite_id, {type, entry_id, params})
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
        %{action: {EntryDetailsComponent, {msg_type, _}}},
        socket
      )
      when msg_type in [:change, :created_attachment, :deleted_attachment] do
    {:ok, assign(socket, :has_entry_details_change, true)}
  end

  def update(
        %{action: {EntryDetailsComponent, {:delete, _entry}}},
        socket
      ) do
    socket =
      socket
      |> assign(:assessment_point_entry, nil)
      |> assign(:has_entry_details_change, true)
      |> stream_assessment_points()
      |> stream_students_entries()
      |> assign(:has_entry_details_change, false)

    {:ok, socket}
  end

  def update(%{moment: moment, assessment_point_id: assessment_point_id} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point(assessment_point_id)
      |> assign_user_filters([:classes], assigns.current_user, strand_id: moment.strand_id)
      |> assign_user_filters([:assessment_view], assigns.current_user)
      |> assign_view_bg()
      |> stream_assessment_points()
      |> stream_students_entries()

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

  defp assign_assessment_point(socket, nil) do
    socket
    |> assign(:assessment_point, %AssessmentPoint{
      moment_id: socket.assigns.moment.id,
      datetime: DateTime.utc_now()
    })
  end

  defp assign_assessment_point(socket, assessment_point_id) do
    case Assessments.get_assessment_point(assessment_point_id) do
      nil ->
        socket
        |> assign(:assessment_point, %AssessmentPoint{datetime: DateTime.utc_now()})

      assessment_point ->
        socket
        |> assign(:assessment_point, assessment_point)
    end
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
    assessment_points =
      Assessments.list_assessment_points(
        moments_ids: [socket.assigns.moment.id],
        preloads: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )

    assessment_points_count = length(assessment_points)

    assessment_points_columns_grid =
      case socket.assigns.current_assessment_view do
        "compare" ->
          "repeat(#{assessment_points_count}, 12rem)"

        _ ->
          "repeat(#{assessment_points_count}, 15rem)"
      end

    socket
    |> stream(:assessment_points, assessment_points)
    |> assign(:assessment_points_count, assessment_points_count)
    |> assign(:assessment_points_columns_grid, assessment_points_columns_grid)
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
  end

  defp stream_students_entries(socket) do
    students_entries =
      Assessments.list_moment_students_entries(
        socket.assigns.moment.id,
        classes_ids: socket.assigns.selected_classes_ids,
        check_if_has_evidences: true
      )

    stream(socket, :students_entries, students_entries)
  end

  # event handlers

  @impl true
  def handle_event(
        "change_view",
        %{"view" => view},
        %{assigns: %{current_assessment_view: current_assessment_view}} = socket
      )
      when view == current_assessment_view,
      do: {:noreply, socket}

  def handle_event("change_view", %{"view" => view}, socket) do
    # TODO
    # before applying the view change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_view, view)
          |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment.id}?tab=assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

  def handle_event("save_changes", _params, socket) do
    %{
      entries_changes_map: entries_changes_map,
      current_user: current_user
    } = socket.assigns

    socket =
      case save_entry_editor_component_changes(
             entries_changes_map,
             current_user.current_profile_id
           ) do
        {:ok, msg} -> put_flash(socket, :info, msg)
        {:error, msg} -> put_flash(socket, :error, msg)
      end
      |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")

    {:noreply, socket}
  end

  def handle_event("delete_assessment_point", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

      {:error, _changeset} ->
        # we may have more error types, but for now we are handling only this one
        message =
          gettext(
            "This assessment point already have some entries. Deleting it will cause data loss."
          )

        {:noreply, socket |> assign(:delete_assessment_point_error, message)}
    end
  end

  def handle_event("delete_assessment_point_and_entries", _, socket) do
    case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("dismiss_assessment_point_error", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_assessment_point_error, nil)}
  end

  def handle_event("assessment_point_position", %{"from" => i, "to" => j}, socket) do
    sortable_assessment_points =
      socket.assigns.sortable_assessment_points
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_assessment_points, sortable_assessment_points)}
  end

  def handle_event("save_order", _, socket) do
    assessment_points_ids =
      socket.assigns.sortable_assessment_points
      |> Enum.map(fn {ap, _i} -> ap.id end)

    case Assessments.update_assessment_points_positions(assessment_points_ids) do
      {:ok, _assessment_points} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/moment/#{socket.assigns.moment}?tab=assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
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
