defmodule LantternWeb.StrandLive.ActivityTabs.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools

  alias LantternWeb.AssessmentPointLive.ActivityAssessmentPointFormComponent
  alias LantternWeb.AssessmentPointLive.EntryEditorComponent
  alias LantternWeb.SchoolLive.ClassFilterFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-10">
      <div class="container mx-auto lg:max-w-5xl">
        <div class="flex items-end justify-between gap-6">
          <%= if @classes do %>
            <p class="font-display font-bold text-2xl">
              Assessing
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-overlay")}
              >
                <%= @classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-overlay")}
              >
                Select a class
              </button>
              to assess students
            </p>
          <% end %>
          <div class="shrink-0 flex items-center gap-6">
            <.collection_action
              :if={@assessment_points_count > 1}
              type="button"
              phx-click={JS.exec("data-show", to: "#activity-assessment-points-order-overlay")}
              icon_name="hero-arrows-up-down"
            >
              Reorder
            </.collection_action>
            <.collection_action
              type="link"
              patch={~p"/strands/activity/#{@activity}/assessment_point/new"}
              icon_name="hero-plus-circle"
            >
              Create assessment point
            </.collection_action>
          </div>
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div :if={@assessment_points_count == 0} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state>No assessment points for this activity yet</.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={!@classes && @assessment_points_count > 0}
          class="p-10 mt-4 rounded shadow-xl bg-white"
        >
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <li
              :for={{dom_id, {assessment_point, i}} <- @streams.assessment_points}
              id={"no-class-#{dom_id}"}
            >
              <.link
                patch={~p"/strands/activity/#{@activity}/assessment_point/#{assessment_point}"}
                class="hover:underline"
              >
                <%= "#{i + 1}. #{assessment_point.name}" %>
              </.link>
            </li>
          </ol>
        </div>
      </div>
      <%!-- show entries only with class filter selected --%>
      <div
        :if={@classes && @assessment_points_count > 0}
        id="activity-assessment-points-slider"
        class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto"
        phx-hook="Slider"
      >
        <div class="sticky top-0 z-20 flex items-stretch gap-4 pr-6 mb-2 bg-white">
          <div class="sticky left-0 shrink-0 w-60 bg-white"></div>
          <div
            id="activity-assessment-points"
            phx-update="stream"
            class="shrink-0 flex gap-4 bg-white"
          >
            <.assessment_point
              :for={{dom_id, {ap, i}} <- @streams.assessment_points}
              assessment_point={ap}
              activity_id={@activity.id}
              index={i}
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
          />
        </div>
      </div>
      <.slide_over
        :if={@live_action in [:new_assessment_point, :edit_assessment_point]}
        id="assessment-point-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/activity/#{@activity}?tab=assessment")}
      >
        <:title>Assessment Point</:title>
        <.live_component
          module={ActivityAssessmentPointFormComponent}
          id={Map.get(@assessment_point, :id) || :new}
          activity_id={@activity.id}
          strand_id={@activity.strand_id}
          notify_component={@myself}
          assessment_point={@assessment_point}
          navigate={~p"/strands/activity/#{@activity}?tab=assessment"}
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
              data-confirm="Are you sure?"
              class="mt-4 font-display font-bold underline"
            >
              Understood. Delete anyway
            </button>
          </div>
          <button
            type="button"
            phx-click="dismiss_assessment_point_error"
            phx-target={@myself}
            class="shrink-0"
          >
            <span class="sr-only">dismiss</span>
            <.icon name="hero-x-mark" />
          </button>
        </div>
        <:actions_left :if={not is_nil(@assessment_point_id)}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_assessment_point"
            phx-target={@myself}
            data-confirm="Are you sure?"
          >
            Delete
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#assessment-point-form-overlay")}
          >
            Cancel
          </.button>
          <.button type="submit" form="activity-assessment-point-form" phx-disable-with="Saving...">
            Save
          </.button>
        </:actions>
      </.slide_over>
      <.slide_over id="classes-filter-overlay">
        <:title>Classes</:title>
        <.live_component
          module={ClassFilterFormComponent}
          id={:filter}
          current_user={@current_user}
          notify_component={@myself}
          classes_ids={@classes_ids}
          navigate={
            fn classes_ids ->
              url_params = %{tab: "assessment", classes_ids: classes_ids}
              ~p"/strands/activity/#{@activity}?#{url_params}"
            end
          }
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#classes-filter-overlay")}
          >
            Cancel
          </.button>
          <.button
            type="submit"
            form="class-filter-form"
            phx-click={JS.exec("data-cancel", to: "#classes-filter-overlay")}
          >
            Select
          </.button>
        </:actions>
      </.slide_over>
      <.slide_over :if={@assessment_points_count > 1} id="activity-assessment-points-order-overlay">
        <:title>Assessment Points Order</:title>
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
                sr_text="Move assessment point up"
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
                sr_text="Move assessment point down"
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
            phx-click={JS.exec("data-cancel", to: "#activity-assessment-points-order-overlay")}
          >
            Cancel
          </.button>
          <.button type="button" phx-click="save_order" phx-target={@myself}>
            Save
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # function components

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :activity_id, :integer, required: true
  attr :index, :integer, required: true

  def assessment_point(assigns) do
    ~H"""
    <div class="shrink-0 w-40 pt-6 pb-2" id={@id}>
      <.link
        patch={~p"/strands/activity/#{@activity_id}/assessment_point/#{@assessment_point}"}
        class="text-xs hover:underline line-clamp-2"
      >
        <%= "#{@index + 1}. #{@assessment_point.name}" %>
      </.link>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :student, Lanttern.Schools.Student, required: true
  attr :entries, :list, required: true

  def student_and_entries(assigns) do
    ~H"""
    <div class="flex items-stretch gap-4" id={@id}>
      <.icon_with_name
        class="sticky left-0 z-10 shrink-0 w-60 px-6 bg-white"
        profile_name={@student.name}
      />
      <%= for {entry, assessment_point} <- @entries do %>
        <div class="shrink-0 w-40 min-h-[4rem] py-1">
          <.live_component
            module={EntryEditorComponent}
            id={"student-#{@student.id}-entry-for-#{assessment_point.id}"}
            student={@student}
            assessment_point={assessment_point}
            entry={entry}
            class="w-full h-full"
            wrapper_class="w-full h-full"
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
    {:ok,
     socket
     |> stream_configure(
       :assessment_points,
       dom_id: fn
         {ap, _index} -> "assessment-point-#{ap.id}"
         _ -> ""
       end
     )
     |> stream_configure(
       :students_entries_assessment_points,
       dom_id: fn {student, _entries} -> "student-#{student.id}" end
     )
     |> assign(:delete_assessment_point_error, nil)
     |> assign(:classes, nil)
     |> assign(:classes_ids, [])}
  end

  @impl true
  def update(%{activity: activity, assessment_point_id: assessment_point_id} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_assessment_point(assessment_point_id)
     |> assign_classes(assigns.params)
     |> core_assigns(activity.id)}
  end

  def update(_assigns, socket), do: {:ok, socket}

  defp assign_assessment_point(socket, nil) do
    socket
    |> assign(:assessment_point, %AssessmentPoint{datetime: DateTime.utc_now()})
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
         _activity_id
       ),
       do: socket

  defp core_assigns(socket, activity_id) do
    assessment_points = Assessments.list_activity_assessment_points(activity_id)

    students_entries =
      Assessments.list_activity_students_entries(activity_id,
        classes_ids: socket.assigns.classes_ids
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
    |> stream(:assessment_points, Enum.with_index(assessment_points))
    |> stream(:students_entries_assessment_points, students_entries_assessment_points)
    |> assign(:assessment_points_count, length(assessment_points))
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
  end

  defp assign_classes(socket, %{"classes_ids" => classes_ids}) do
    socket
    |> assign(:classes_ids, classes_ids)
    |> assign(
      :classes,
      Schools.list_user_classes(
        socket.assigns.current_user,
        classes_ids: classes_ids
      )
    )
  end

  defp assign_classes(socket, _params), do: socket

  # event handlers

  @impl true
  def handle_event("delete_assessment_point", _params, socket) do
    case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
      {:ok, _assessment_point} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/activity/#{socket.assigns.activity}?tab=assessment")}

      {:error, _changeset} ->
        # we may have more error types, but for now we are handling only this one
        message =
          "This assessment point already have some entries. Deleting it will cause data loss."

        {:noreply, socket |> assign(:delete_assessment_point_error, message)}
    end
  end

  def handle_event("delete_assessment_point_and_entries", _, socket) do
    case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/activity/#{socket.assigns.activity}?tab=assessment")}

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

    case Assessments.update_activity_assessment_points_positions(
           socket.assigns.activity.id,
           assessment_points_ids
         ) do
      {:ok, _assessment_points} ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/strands/activity/#{socket.assigns.activity}?tab=assessment")}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  # helpers

  # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  defp swap(a, i1, i2) do
    e1 = Enum.at(a, i1)
    e2 = Enum.at(a, i2)

    a
    |> List.replace_at(i1, e2)
    |> List.replace_at(i2, e1)
  end
end
