defmodule LantternWeb.MomentLive.AssessmentComponent do
  alias Lanttern.Identity.User
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  import LantternWeb.AssessmentsHelpers, only: [save_entry_editor_component_changes: 2]
  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 4]
  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.EntryEditorComponent
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
      <div class="px-6 mt-6">
        <div
          :if={@selected_classes != [] && @assessment_points_count > 0}
          class="relative w-full max-h-[calc(100vh-4rem)] pb-6 rounded shadow-xl bg-white overflow-x-auto"
        >
          <div class="sticky top-0 z-20 flex items-stretch gap-4 pr-6 mb-2 bg-white">
            <div class="sticky left-0 shrink-0 w-60 bg-white"></div>
            <div
              id="moment-assessment-points"
              phx-update="stream"
              class="shrink-0 flex gap-4 bg-white"
            >
              <.assessment_point
                :for={{dom_id, assessment_point} <- @streams.assessment_points}
                assessment_point={assessment_point}
                moment_id={@moment.id}
                id={dom_id}
              />
            </div>
            <div class="shrink-0 w-2"></div>
          </div>
          <div phx-update="stream" id="students-entries">
            <.student_and_entries
              :for={{dom_id, {student, entries}} <- @streams.students_entries_assessment_points}
              student={student}
              entries={entries}
              id={dom_id}
              myself={@myself}
              current_user={@current_user}
            />
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

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :moment_id, :integer, required: true

  def assessment_point(assigns) do
    ~H"""
    <div class="shrink-0 w-60 pt-6 pb-2" id={@id}>
      <.link
        patch={~p"/strands/moment/#{@moment_id}/assessment_point/#{@assessment_point}"}
        class="text-sm font-bold hover:underline"
      >
        <%= @assessment_point.name %>
      </.link>
      <div class="flex gap-2 my-2">
        <.badge><%= @assessment_point.curriculum_item.curriculum_component.name %></.badge>
        <.badge :if={@assessment_point.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
      </div>
      <p class="text-sm line-clamp-2" title={@assessment_point.curriculum_item.name}>
        <%= @assessment_point.curriculum_item.name %>
      </p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :student, Lanttern.Schools.Student, required: true
  attr :entries, :list, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true
  attr :current_user, User, required: true

  def student_and_entries(assigns) do
    ~H"""
    <div class="flex items-stretch gap-4" id={@id}>
      <.profile_icon_with_name
        class="sticky left-0 z-10 shrink-0 w-60 px-6 bg-white"
        profile_name={@student.name}
        extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
      />
      <%= for {entry, assessment_point} <- @entries do %>
        <div class="shrink-0 w-60 min-h-[4rem] py-1">
          <.live_component
            module={EntryEditorComponent}
            id={"student-#{@student.id}-entry-for-#{assessment_point.id}"}
            student={@student}
            assessment_point={assessment_point}
            entry={entry}
            class="w-full h-full"
            wrapper_class="w-full h-full"
            notify_component={@myself}
            current_user={@current_user}
          >
            <:marking_input class="w-full h-full" />
          </.live_component>
        </div>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :students_entries_assessment_points,
        dom_id: fn {student, _entries} -> "student-#{student.id}" end
      )
      |> assign(:delete_assessment_point_error, nil)
      |> assign(:classes, nil)
      |> assign(:classes_ids, [])
      |> assign(:entries_changes_map, %{})

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {EntryEditorComponent, {:change, :cancel, composite_id, _, _}}},
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
        %{action: {EntryEditorComponent, {:change, type, composite_id, entry_id, params}}},
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

  def update(%{moment: moment, assessment_point_id: assessment_point_id} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_assessment_point(assessment_point_id)
      |> assign_user_filters([:classes], assigns.current_user, strand_id: moment.strand_id)
      |> core_assigns(moment.id)

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

  defp core_assigns(
         %{assigns: %{assessment_points_count: _}} = socket,
         _moment_id
       ),
       do: socket

  defp core_assigns(socket, moment_id) do
    assessment_points =
      Assessments.list_assessment_points(
        moments_ids: [moment_id],
        preloads: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )

    students_entries =
      Assessments.list_moment_students_entries(moment_id,
        classes_ids: socket.assigns.selected_classes_ids
      )

    # zip assessment points with entries
    students_entries_assessment_points =
      students_entries
      |> Enum.map(fn {student, entries} ->
        {
          student,
          Enum.zip(entries, assessment_points)
        }
      end)

    socket
    |> stream(:assessment_points, assessment_points)
    |> stream(:students_entries_assessment_points, students_entries_assessment_points)
    |> assign(:assessment_points_count, length(assessment_points))
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
  end

  # event handlers

  @impl true
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
end
