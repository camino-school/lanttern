defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Filters
  alias Lanttern.Identity.User
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools.Student

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 4, assign_user_filters: 3]

  # shared components
  alias LantternWeb.Assessments.EntryCellComponent
  alias LantternWeb.StrandLive.StrandRubricsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <%= gettext("Viewing") %>
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
              <%= gettext("to view students assessments") %>
            </p>
          <% end %>
        </div>
        <div class="flex items-center gap-4 mt-6 text-sm">
          <.assessment_group_by_dropdow
            current_assessment_group_by={@current_assessment_group_by}
            myself={@myself}
          />
          <.assessment_view_dropdow
            current_assessment_view={@current_assessment_view}
            myself={@myself}
          />
        </div>
        <%!-- if no assessment points, render empty state --%>
        <div :if={!@has_assessment_points} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No assessment points for this strand yet") %></.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={@selected_classes == [] && @has_assessment_points}
          class="p-10 mt-4 rounded shadow-xl bg-white"
        >
          <p class="mb-6 font-bold text-ltrn-subtle"><%= gettext("Current assessment points") %></p>
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <.no_class_assessment_points_group
              :for={{_dom_id, assessment_points_group} <- @streams.assessment_points}
              assessment_points_group={assessment_points_group}
            />
          </ol>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div :if={@selected_classes != [] && @has_assessment_points} class="px-6">
        <div class={[
          "relative w-full max-h-[calc(100vh-4rem)] border mt-6 rounded shadow-xl #{@view_bg} overflow-x-auto",
          if(@current_assessment_view == "student",
            do: "border-ltrn-student-accent",
            else: "border-transparent"
          )
        ]}>
          <div
            class="relative grid w-max"
            style={"grid-template-columns: 240px repeat(#{@assessment_points_count}, minmax(240px, 1fr))"}
          >
            <div
              class={"sticky top-0 z-20 grid grid-cols-subgrid #{@view_bg}"}
              style={"grid-column: span #{@assessment_points_count + 1} / span #{@assessment_points_count + 1}"}
            >
              <div class={"sticky left-0 #{@view_bg}"}></div>
              <div
                id="grid-assessment-points"
                phx-update="stream"
                class="grid grid-cols-subgrid"
                style={"grid-column: span #{@assessment_points_count} / span #{@assessment_points_count}"}
              >
                <.assessment_point_group
                  :for={{dom_id, ap_group} <- @streams.assessment_points}
                  id={dom_id}
                  ap_group={ap_group}
                  assessment_view={@current_assessment_view}
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
      <%!-- <div :if={@selected_classes != [] && @assessment_points_count > 0} class="px-6">
        <div class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto">
          <div class="sticky top-0 z-20 flex items-stretch gap-4 pr-6 mb-2 bg-white">
            <div class="sticky left-0 shrink-0 w-60 bg-white"></div>
            <div
              id="strand-assessment-points"
              phx-update="stream"
              class="shrink-0 flex gap-4 bg-white"
            >
              <.assessment_point
                :for={{dom_id, {ap, i}} <- @streams.assessment_points}
                assessment_point={ap}
                strand_id={@strand.id}
                index={i}
                id={dom_id}
              />
            </div>
            <div class="shrink-0 w-2"></div>
          </div>
          <div phx-update="stream" id="students-entries" class="flex flex-col gap-4">
            <.student_and_entries
              :for={{dom_id, {student, entries}} <- @streams.students_entries}
              student={student}
              entries={entries}
              scale_ov_map={@scale_ov_map}
              id={dom_id}
            />
          </div>
        </div>
      </div> --%>
      <.live_component
        module={StrandRubricsComponent}
        id={:strand_rubrics}
        strand={@strand}
        live_action={@live_action}
        selected_classes_ids={@selected_classes_ids}
      />
      <.live_component
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        filter_type={:classes}
        filter_opts={[strand_id: @strand.id]}
        navigate={~p"/strands/#{@strand}?tab=assessment"}
      />
    </div>
    """
  end

  # function components

  attr :current_assessment_group_by, :string, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def assessment_group_by_dropdow(assigns) do
    text =
      case assigns.current_assessment_group_by do
        "curriculum" -> gettext("Show all, grouped by curriculum")
        "moment" -> gettext("Show all, grouped by moment")
        _ -> gettext("Show only final assessents")
      end

    assigns = assign(assigns, :text, text)

    ~H"""
    <div class="relative">
      <.badge_button id="group-by-dropdown-button" icon_name="hero-chevron-down-mini">
        <%= @text %>
      </.badge_button>
      <.dropdown_menu id="group-by-dropdown" button_id="group-by-dropdown-button" z_index="30">
        <:item
          text={gettext("Show only final assessments")}
          on_click={JS.push("change_group_by", value: %{"group_by" => nil}, target: @myself)}
        />
        <:item
          text={gettext("Show all, grouped by curriculum")}
          on_click={JS.push("change_group_by", value: %{"group_by" => "curriculum"}, target: @myself)}
        />
        <:item
          text={gettext("Show all, grouped by moment")}
          on_click={JS.push("change_group_by", value: %{"group_by" => "moment"}, target: @myself)}
        />
      </.dropdown_menu>
    </div>
    """
  end

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

  attr :assessment_points_group, :any, required: true

  def no_class_assessment_points_group(assigns) do
    {_group_by_struct, assessment_points} = assigns.assessment_points_group
    assigns = assign(assigns, :assessment_points, assessment_points)

    ~H"""
    <li :for={assessment_point <- @assessment_points} id={"no-class-#{assessment_point.id}"}>
      <%= assessment_point.name %>
    </li>
    """
  end

  attr :id, :string, required: true
  attr :ap_group, :any, required: true
  attr :assessment_view, :string, required: true

  def assessment_point_group(assigns) do
    {group_by_struct, assessment_points} = assigns.ap_group

    # handles grid-column span "calculation"
    assessment_points_count = length(assessment_points)

    grid_column_span_style =
      "grid-column: span #{assessment_points_count} / span #{assessment_points_count}"

    assigns =
      assigns
      |> assign(:group_by_struct, group_by_struct)
      |> assign(:assessment_points, assessment_points)
      |> assign(:grid_column_span_style, grid_column_span_style)

    ~H"""
    <div id={@id} class="grid grid-cols-subgrid" style={@grid_column_span_style}>
      <div style={@grid_column_span_style}>
        <.assessment_point_group_header group_by_struct={@group_by_struct} />
      </div>
      <div
        :for={assessment_point <- @assessment_points}
        id={"assessment-point-#{assessment_point.id}"}
        class="flex flex-col gap-2 max-w-80 pt-6 px-2 pb-2 text-sm"
      >
        <.assessment_point assessment_point={assessment_point} />
        <div :if={@assessment_view == "compare"} class="flex gap-1 w-full">
          <div class="flex-1 pb-1 border-b-2 border-ltrn-teacher-accent text-xs text-center text-ltrn-teacher-dark">
            <%= gettext("Teacher") %>
          </div>
          <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-xs text-center text-ltrn-student-dark">
            <%= gettext("Student") %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :group_by_struct, :any, required: true, doc: "moment, strand, or curriculum item"

  def assessment_point_group_header(%{group_by_struct: %Moment{}} = assigns) do
    ~H"""
    <.link navigate={~p"/strands/moment/#{@group_by_struct.id}?tab=assessment"}>
      <%= @group_by_struct.name %>
    </.link>
    """
  end

  def assessment_point_group_header(%{group_by_struct: %CurriculumItem{}} = assigns) do
    ~H"""
    <div class="max-w-80">
      <div class="flex items-center gap-2">
        <.badge>
          <%= @group_by_struct.curriculum_component.name %>
        </.badge>
        <.badge :if={@group_by_struct.is_differentiation} theme="diff">
          <%= gettext("Diff") %>
        </.badge>
      </div>
      <p class="flex-1 line-clamp-3" title={@group_by_struct.name}>
        <%= @group_by_struct.name %>
      </p>
    </div>
    """
  end

  def assessment_point_group_header(%{group_by_struct: %Strand{}} = assigns) do
    ~H"""
    <%= gettext("Final assessment") %>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true

  def assessment_point(%{assessment_point: %{curriculum_item: %CurriculumItem{}}} = assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <.badge>
        <%= @assessment_point.curriculum_item.curriculum_component.name %>
      </.badge>
      <.badge :if={@assessment_point.is_differentiation} theme="diff">
        <%= gettext("Diff") %>
      </.badge>
    </div>
    <p class="flex-1 line-clamp-3" title={@assessment_point.curriculum_item.name}>
      <%= @assessment_point.curriculum_item.name %>
    </p>
    """
  end

  def assessment_point(%{assessment_point: %{moment: %Moment{}}} = assigns) do
    ~H"""
    <.link
      class="line-clamp-3"
      title={@assessment_point.moment.name}
      navigate={~p"/strands/moment/#{@assessment_point.moment.id}?tab=assessment"}
    >
      <%= @assessment_point.moment.name %>
    </.link>
    """
  end

  def assessment_point(%{assessment_point: %{strand_id: strand_id}} = assigns)
      when not is_nil(strand_id) do
    ~H"""
    <p>
      <%= gettext("Final assessment") %>
    </p>
    """
  end

  # def assessment_point(assigns) do
  #   ~H"""
  #   <div id={@id} class="flex flex-col gap-2 max-w-80 pt-6 px-2 pb-2 text-sm">
  #     <div class="flex items-center gap-2">
  #       <.badge>
  #         <%= @assessment_point.curriculum_item.curriculum_component.name %>
  #       </.badge>
  #       <.badge :if={@assessment_point.is_differentiation} theme="diff">
  #         <%= gettext("Diff") %>
  #       </.badge>
  #     </div>
  #     <p class="flex-1 line-clamp-3" title={@assessment_point.curriculum_item.name}>
  #       <%= @assessment_point.curriculum_item.name %>
  #     </p>
  #     <div :if={@assessment_view == "compare"} class="flex gap-1 w-full">
  #       <div class="flex-1 pb-1 border-b-2 border-ltrn-teacher-accent text-xs text-center text-ltrn-teacher-dark">
  #         <%= gettext("Teacher") %>
  #       </div>
  #       <div class="flex-1 pb-1 border-b-2 border-ltrn-student-accent text-xs text-center text-ltrn-student-dark">
  #         <%= gettext("Student") %>
  #       </div>
  #     </div>
  #   </div>
  #   """
  # end

  # attr :id, :string, required: true
  # attr :assessment_point, AssessmentPoint, required: true
  # attr :strand_id, :integer, required: true
  # attr :index, :integer, required: true

  # def assessment_point(assigns) do
  #   ~H"""
  #   <div class="shrink-0 w-14 pt-6 pb-2 truncate" id={@id}>
  #     <.link
  #       navigate={~p"/strands/moment/#{@assessment_point.moment_id}?tab=assessment"}
  #       class="text-xs hover:underline"
  #     >
  #       <%= "#{@index + 1}. #{@assessment_point.name}" %>
  #     </.link>
  #   </div>
  #   """
  # end

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
      <div :for={entry <- @entries} class="max-w-80 p-2">
        <.live_component
          module={EntryCellComponent}
          id={"student-#{@student.id}-entry-for-#{entry.assessment_point_id}"}
          class="w-full h-full"
          entry={entry}
          view={@current_assessment_view}
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
        :assessment_points,
        dom_id: fn
          {%CurriculumItem{} = ci, _assessment_points} -> "ap-group-curriculum-item-#{ci.id}"
          {%Moment{} = moment, _assessment_points} -> "ap-group-moment-#{moment.id}"
          {%Strand{} = strand, _assessment_points} -> "ap-group-strand-#{strand.id}"
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
  def update(%{strand: strand} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters([:classes], assigns.current_user, strand_id: strand.id)
      |> assign_user_filters([:assessment_view], assigns.current_user)
      |> assign_user_filters([:assessment_group_by], assigns.current_user)
      |> assign_view_bg()
      |> stream_assessment_points()
      |> stream_students_entries()

    # |> core_assigns(strand.id)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

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
      Assessments.list_strand_assessment_points(
        socket.assigns.strand.id,
        socket.assigns.current_assessment_group_by
      )

    assessment_points_count =
      assessment_points
      |> Enum.flat_map(fn {_, ap_list} -> ap_list end)
      |> length()

    socket
    |> stream(:assessment_points, assessment_points)
    |> assign(:assessment_points_count, assessment_points_count)
    |> assign(:has_assessment_points, assessment_points != [])
  end

  defp stream_students_entries(socket) do
    students_entries =
      Assessments.list_strand_students_entries(
        socket.assigns.strand.id,
        socket.assigns.current_assessment_group_by,
        classes_ids: socket.assigns.selected_classes_ids
      )

    socket
    |> stream(:students_entries, students_entries)
  end

  # defp core_assigns(
  #        %{assigns: %{assessment_points_count: _}} = socket,
  #        _strand_id
  #      ),
  #      do: socket

  # defp core_assigns(socket, strand_id) do
  #   assessment_points =
  #     Assessments.list_assessment_points(
  #       moments_from_strand_id: strand_id,
  #       preloads: [scale: :ordinal_values]
  #     )

  #   scale_ov_map =
  #     assessment_points
  #     |> Enum.map(& &1.scale)
  #     |> Enum.uniq_by(& &1.id)
  #     |> Enum.map(fn scale ->
  #       {
  #         scale.id,
  #         scale.ordinal_values
  #         |> Enum.map(fn ov ->
  #           {
  #             ov.id,
  #             %{
  #               name: ov.name,
  #               style: "background-color: #{ov.bg_color}; color: #{ov.text_color}"
  #             }
  #           }
  #         end)
  #         |> Enum.into(%{})
  #       }
  #     end)
  #     |> Enum.into(%{})

  #   students_entries =
  #     Assessments.list_strand_students_entries(strand_id,
  #       classes_ids: socket.assigns.selected_classes_ids
  #     )

  #   socket
  #   |> stream(:assessment_points, Enum.with_index(assessment_points))
  #   |> stream(:students_entries, students_entries)
  #   |> assign(:assessment_points_count, length(assessment_points))
  #   |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
  #   |> assign(:scale_ov_map, scale_ov_map)
  # end

  # event handlers

  @impl true
  def handle_event(
        "change_group_by",
        %{"group_by" => group_by},
        %{assigns: %{current_assessment_group_by: current_assessment_group_by}} = socket
      )
      when group_by == current_assessment_group_by,
      do: {:noreply, socket}

  def handle_event("change_group_by", %{"group_by" => group_by}, socket) do
    # TODO
    # before applying the group_by change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_group_by: group_by}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_group_by, group_by)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

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
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end
end
