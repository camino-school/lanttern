defmodule LantternWeb.GradesReports.GradeDetailsOverlayComponent do
  @moduledoc """
  Renders a grade details overlay component.

  #### Expected external assigns

      attr :student_grade_report_entry_id, :integer
      attr :on_cancel, JS

  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports

  # shared components
  import LantternWeb.GradingComponents, only: [apply_style_from_ordinal_value: 1]
  import LantternWeb.GradesReportsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Grade details") %></:title>
        <div class="flex items-center gap-6 mb-10">
          <div
            :if={@student_grade_report_entry.ordinal_value}
            class="self-stretch flex items-center p-6 rounded"
            {apply_style_from_ordinal_value(@student_grade_report_entry.ordinal_value)}
          >
            <%= @student_grade_report_entry.ordinal_value.name %>
          </div>
          <div
            :if={@student_grade_report_entry.score}
            class="self-stretch flex items-center p-6 border border-ltrn-lighter rounded font-mono font-bold bg-ltrn-lightes"
          >
            <%= @student_grade_report_entry.score %>
          </div>
          <div class="flex-1">
            <.metadata class="mb-4" icon_name="hero-bookmark">
              <span class="font-bold"><%= gettext("Subject") %>:</span>
              <%= Gettext.dgettext(
                LantternWeb.Gettext,
                "taxonomy",
                @student_grade_report_entry.grades_report_subject.subject.name
              ) %>
            </.metadata>
            <.metadata icon_name="hero-calendar">
              <span class="font-bold"><%= gettext("Cycle") %>:</span>
              <%= @student_grade_report_entry.grades_report_cycle.school_cycle.name %>
            </.metadata>
          </div>
        </div>

        <div
          :if={
            @student_grade_report_entry.pre_retake_ordinal_value ||
              @student_grade_report_entry.pre_retake_score
          }
          class="flex items-center gap-4 p-4 rounded mb-10 bg-ltrn-lightest"
        >
          <div
            :if={@student_grade_report_entry.pre_retake_ordinal_value}
            class="self-stretch flex items-center px-4 py-2 rounded text-sm opacity-70"
            {apply_style_from_ordinal_value(@student_grade_report_entry.pre_retake_ordinal_value)}
          >
            <%= @student_grade_report_entry.pre_retake_ordinal_value.name %>
          </div>
          <div
            :if={@student_grade_report_entry.pre_retake_score}
            class="self-stretch flex items-center px-4 py-2 rounded font-mono font-bold text-sm opacity-70"
          >
            <%= @student_grade_report_entry.pre_retake_score %>
          </div>
          <p class="text-sm text-ltrn-subtle"><%= gettext("Grade before retake process") %></p>
        </div>
        <%= if @student_grade_report_entry.comment do %>
          <h6 class="mb-4 font-display font-bold"><%= gettext("Comment") %></h6>
          <.markdown text={@student_grade_report_entry.comment} size="sm" class="mb-10" />
        <% end %>
        <h6 class="mb-4 font-display font-bold"><%= gettext("Grade composition") %></h6>
        <.grade_composition_table student_grade_report_entry={@student_grade_report_entry} />
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  @impl true
  def update(assigns, socket) do
    sgre =
      GradesReports.get_student_grade_report_entry!(
        assigns.student_grade_report_entry_id,
        preloads: [
          :composition_ordinal_value,
          :pre_retake_ordinal_value,
          :ordinal_value,
          grades_report_subject: :subject,
          grades_report_cycle: :school_cycle
        ]
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:student_grade_report_entry, sgre)

    {:ok, socket}
  end
end
