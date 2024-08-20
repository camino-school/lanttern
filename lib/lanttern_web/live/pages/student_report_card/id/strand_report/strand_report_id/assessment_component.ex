defmodule LantternWeb.StudentStrandReportLive.AssessmentComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <div class="flex items-center gap-2">
          <span class="text-sm font-bold">
            <%= gettext("Information level") %>
          </span>
          <.badge_button
            theme={if @info_level == "full", do: "primary"}
            phx-click={JS.push("set_info_level", value: %{"level" => "full"}, target: @myself)}
          >
            <%= gettext("Full") %>
          </.badge_button>
          <.badge_button
            theme={if @info_level == "simplified", do: "primary"}
            phx-click={JS.push("set_info_level", value: %{"level" => "simplified"}, target: @myself)}
          >
            <%= gettext("Simplified") %>
          </.badge_button>
        </div>
        <div class="mt-4">
          <div
            :for={
              {%AssessmentPoint{
                 is_differentiation: is_diff,
                 curriculum_item: curriculum_item,
                 scale: scale,
                 rubric: rubric,
                 report_info: report_info
               },
               entry} <-
                @strand_goals_student_entries
            }
            class="rounded mt-4 bg-white shadow"
          >
            <div class="pt-6 px-6">
              <%= if @info_level == "simplified" do %>
                <p class="text-sm">
                  <span class="inline-block mr-1 font-display font-bold text-ltrn-subtle">
                    <%= curriculum_item.curriculum_component.name %>
                  </span>
                  <%= curriculum_item.name %>
                </p>
              <% else %>
                <p class="mb-2 font-display font-bold text-sm">
                  <%= curriculum_item.curriculum_component.name %>
                </p>
                <p class="text-base">
                  <%= curriculum_item.name %>
                </p>
              <% end %>
              <div
                :if={
                  @info_level == "full" &&
                    (curriculum_item.code || curriculum_item.subjects != [])
                }
                class="flex flex-wrap items-center gap-2 mt-4"
              >
                <.badge :if={curriculum_item.code} theme="dark">
                  <%= curriculum_item.code %>
                </.badge>
                <.badge :if={is_diff} theme="diff">
                  <%= gettext("Curriculum differentiation") %>
                </.badge>
                <.badge :if={rubric && length(rubric.differentiation_rubrics) > 0} theme="diff">
                  <%= gettext("Differentiation rubric") %>
                </.badge>
                <.badge :for={subject <- curriculum_item.subjects}>
                  <%= subject.name %>
                </.badge>
              </div>
            </div>
            <div class="p-6 overflow-x-auto">
              <.report_scale
                scale={scale}
                entry={entry}
                rubric={
                  case rubric && rubric.differentiation_rubrics do
                    [diff_rubric] -> diff_rubric
                    _ -> rubric
                  end
                }
                class="float-left"
              />
              <%!-- fix for padding right. we need the float-left above and this emtpy div below --%>
              <div class="w-6"></div>
            </div>
            <div
              :if={entry && entry.report_note && @info_level == "full"}
              class="sm:pt-6 sm:px-6 last:sm:pb-6"
            >
              <div class="p-4 sm:rounded bg-ltrn-teacher-lightest">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-teacher-accent" />
                  <span class="text-ltrn-teacher-dark"><%= gettext("Teacher comment") %></span>
                </div>
                <.markdown text={entry.report_note} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
            <div
              :if={entry && entry.student_report_note && @info_level == "full"}
              class="sm:pt-6 sm:px-6 last:sm:pb-6"
            >
              <div class="p-4 sm:rounded bg-ltrn-student-lightest">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-student-accent" />
                  <span class="text-ltrn-student-dark">
                    <%= gettext("%{student} comment", student: @student.name) %>
                  </span>
                </div>
                <.markdown text={entry.student_report_note} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
            <div :if={report_info && @info_level == "full"} class="sm:pt-6 sm:px-6 last:sm:pb-6">
              <div class="p-4 sm:rounded bg-ltrn-mesh-cyan">
                <div class="flex items-center gap-2 font-bold text-sm">
                  <.icon name="hero-information-circle" class="w-6 h-6 text-ltrn-subtle" />
                  <%= gettext("About this assessment") %>
                </div>
                <.markdown text={report_info} size="sm" class="max-w-none mt-4" />
              </div>
            </div>
          </div>
        </div>
      </.responsive_container>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:info_level, "full")

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    strand_goals_student_entries =
      Assessments.list_strand_goals_student_entries(
        assigns.student.id,
        assigns.strand_id
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:strand_goals_student_entries, strand_goals_student_entries)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("set_info_level", %{"level" => level}, socket) do
    {:noreply, assign(socket, :info_level, level)}
  end
end
