defmodule LantternWeb.StudentsRecordsComponents do
  @moduledoc """
  Shared function components related to `StudentsRecords` context
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import LantternWeb.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]

  @doc """
  Renders a students records data grid.
  """

  attr :id, :string, required: true
  attr :stream, :any, required: true
  attr :show_empty_state_message, :boolean, required: true

  attr :row_click, :any,
    required: true,
    doc: "function to execute on row click. Will receive student record as arg"

  attr :is_students_filter_active, :boolean, required: true
  attr :on_students_filter, JS, required: true
  attr :is_classes_filter_active, :boolean, required: true
  attr :on_classes_filter, JS, required: true
  attr :is_type_filter_active, :boolean, required: true
  attr :on_type_filter, JS, required: true
  attr :is_status_filter_active, :boolean, required: true
  attr :on_status_filter, JS, required: true
  attr :current_user_or_cycle, :any, required: true

  def students_records_data_grid(assigns) do
    ~H"""
    <.data_grid
      id={@id}
      stream={@stream}
      row_click={@row_click}
      show_empty_state_message={
        if @show_empty_state_message,
          do: gettext("No students records found for selected filters.")
      }
    >
      <:col :let={student_record} label={gettext("Date")} template_col="max-content" class="text-sm">
        <div class="flex items-center gap-2">
          <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
          <%= Timex.format!(student_record.date, "{Mshort} {0D}, {YYYY}") %>
        </div>
        <div :if={student_record.time} class="flex items-center gap-2 mt-2">
          <.icon name="hero-clock-mini" class="w-5 h-5 text-ltrn-subtle" />
          <%= student_record.time %>
        </div>
      </:col>
      <:col
        :let={student_record}
        label={gettext("Students")}
        template_col="min-content"
        on_filter={@on_students_filter}
        filter_is_active={@is_students_filter_active}
      >
        <div class="flex flex-wrap gap-1">
          <.person_badge
            :for={student <- student_record.students}
            person={student}
            theme="cyan"
            truncate
          />
        </div>
      </:col>
      <:col
        :let={student_record}
        label={gettext("Classes")}
        template_col="min-content"
        on_filter={@on_classes_filter}
        filter_is_active={@is_classes_filter_active}
      >
        <%= if student_record.classes != [] do %>
          <div class="flex flex-wrap gap-1">
            <.badge :for={class <- student_record.classes}>
              <%= class_with_cycle(class, @current_user_or_cycle) %>
            </.badge>
          </div>
        <% else %>
          <.badge>
            —
          </.badge>
        <% end %>
      </:col>
      <:col :let={student_record} label={gettext("Record")}>
        <p :if={student_record.name} class="mb-4 font-display font-black">
          <%= student_record.name %>
        </p>
        <.markdown text={student_record.description} class="line-clamp-3" size="sm" />
      </:col>
      <:col
        :let={student_record}
        label={gettext("Type")}
        template_col="max-content"
        on_filter={@on_type_filter}
        filter_is_active={@is_type_filter_active}
      >
        <.badge color_map={student_record.type}>
          <%= student_record.type.name %>
        </.badge>
      </:col>
      <:col
        :let={student_record}
        label={gettext("Status")}
        template_col="max-content"
        on_filter={@on_status_filter}
        filter_is_active={@is_status_filter_active}
      >
        <.badge color_map={student_record.status}>
          <%= student_record.status.name %>
        </.badge>
      </:col>
    </.data_grid>
    """
  end
end
