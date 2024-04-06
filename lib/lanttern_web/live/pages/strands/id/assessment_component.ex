defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  import LantternWeb.PersonalizationHelpers, only: [assign_user_filters: 4]

  # shared components
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
        <%!-- if no assessment points, render empty state --%>
        <div :if={@assessment_points_count == 0} class="p-10 mt-4 rounded shadow-xl bg-white">
          <.empty_state><%= gettext("No assessment points for this strand yet") %></.empty_state>
        </div>
        <%!-- if no class filter is select, just render assessment points --%>
        <div
          :if={@selected_classes == [] && @assessment_points_count > 0}
          class="p-10 mt-4 rounded shadow-xl bg-white"
        >
          <p class="mb-6 font-bold text-ltrn-subtle"><%= gettext("Current assessment points") %></p>
          <ol phx-update="stream" id="assessment-points-no-class" class="flex flex-col gap-4">
            <li
              :for={{dom_id, {assessment_point, i}} <- @streams.assessment_points}
              id={"no-class-#{dom_id}"}
            >
              <%= "#{i + 1}. #{assessment_point.name}" %>
            </li>
          </ol>
        </div>
      </.responsive_container>
      <%!-- show entries only with class filter selected --%>
      <div class="px-6">
        <div
          :if={@selected_classes != [] && @assessment_points_count > 0}
          class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto"
        >
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
      </div>
      <.live_component
        module={StrandRubricsComponent}
        id={:strand_rubrics}
        strand={@strand}
        live_action={@live_action}
        selected_classes_ids={@selected_classes_ids}
      />
      <.live_component
        module={LantternWeb.Personalization.FiltersOverlayComponent}
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

  attr :id, :string, required: true
  attr :assessment_point, AssessmentPoint, required: true
  attr :strand_id, :integer, required: true
  attr :index, :integer, required: true

  def assessment_point(assigns) do
    ~H"""
    <div class="shrink-0 w-14 pt-6 pb-2 truncate" id={@id}>
      <.link
        navigate={~p"/strands/moment/#{@assessment_point.moment_id}?tab=assessment"}
        class="text-xs hover:underline"
      >
        <%= "#{@index + 1}. #{@assessment_point.name}" %>
      </.link>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :student, Lanttern.Schools.Student, required: true
  attr :entries, :list, required: true
  attr :scale_ov_map, :map, required: true

  def student_and_entries(assigns) do
    ~H"""
    <div class="flex items-stretch gap-4" id={@id}>
      <.profile_icon_with_name
        class="sticky left-0 z-10 shrink-0 w-60 px-6 bg-white"
        profile_name={@student.name}
        extra_info={@student.classes |> Enum.map(& &1.name) |> Enum.join(", ")}
      />
      <%= for entry <- @entries do %>
        <div
          class={[
            "shrink-0 flex items-center justify-center w-14 h-14 rounded-full text-sm",
            if(
              not is_nil(entry),
              do: "text-ltrn-dark bg-white shadow-md",
              else: "text-ltrn-subtle bg-ltrn-lighter"
            )
          ]}
          style={get_colors_style(entry, @scale_ov_map)}
        >
          <%= get_entry_value(entry, @scale_ov_map) %>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_entry_value(nil, _),
    do: "—"

  defp get_entry_value(%{scale_type: "ordinal", ordinal_value_id: nil}, _),
    do: "—"

  defp get_entry_value(
         %{scale_type: "ordinal", ordinal_value_id: ov_id} = entry,
         scale_ov_map
       ) do
    scale_ov_map[entry.scale_id][ov_id].name
    |> String.slice(0..2)
  end

  defp get_entry_value(%{scale_type: "numeric", score: nil}, _),
    do: "—"

  defp get_entry_value(%{scale_type: "numeric", score: score}, _),
    do: score

  defp get_colors_style(
         %{scale_type: "ordinal", ordinal_value_id: ov_id} = entry,
         scale_ov_map
       )
       when not is_nil(ov_id) do
    scale_ov_map[entry.scale_id][ov_id].style
  end

  defp get_colors_style(_, _), do: ""

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :assessment_points,
        dom_id: fn
          {ap, _index} -> "assessment-point-#{ap.id}"
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
      |> core_assigns(strand.id)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

  defp core_assigns(
         %{assigns: %{assessment_points_count: _}} = socket,
         _strand_id
       ),
       do: socket

  defp core_assigns(socket, strand_id) do
    assessment_points =
      Assessments.list_assessment_points(
        moments_from_strand_id: strand_id,
        preloads: [scale: :ordinal_values]
      )

    scale_ov_map =
      assessment_points
      |> Enum.map(& &1.scale)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(fn scale ->
        {
          scale.id,
          scale.ordinal_values
          |> Enum.map(fn ov ->
            {
              ov.id,
              %{
                name: ov.name,
                style: "background-color: #{ov.bg_color}; color: #{ov.text_color}"
              }
            }
          end)
          |> Enum.into(%{})
        }
      end)
      |> Enum.into(%{})

    students_entries =
      Assessments.list_strand_students_entries(strand_id,
        classes_ids: socket.assigns.selected_classes_ids
      )

    socket
    |> stream(:assessment_points, Enum.with_index(assessment_points))
    |> stream(:students_entries, students_entries)
    |> assign(:assessment_points_count, length(assessment_points))
    |> assign(:sortable_assessment_points, Enum.with_index(assessment_points))
    |> assign(:scale_ov_map, scale_ov_map)
  end
end
