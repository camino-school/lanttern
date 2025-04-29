defmodule LantternWeb.StudentsRecordsComponents do
  @moduledoc """
  Shared function components related to `StudentsRecords` context
  """

  use Phoenix.Component

  use Gettext, backend: Lanttern.Gettext
  import LantternWeb.CoreComponents
  import LantternWeb.SchoolsHelpers, only: [class_with_cycle: 2]
  import LantternWeb.DateTimeHelpers

  alias Lanttern.StudentsRecords.StudentRecordStatus

  @doc """
  Renders a students records list.
  """

  attr :id, :string, required: true
  attr :class, :any, default: nil

  attr :stream, :any,
    required: true,
    doc:
      "stream of students records. Requires `students`, `status`, `type`, `created_by_staff_member`, `assignees` preloads"

  attr :show_empty_state_message, :boolean, required: true

  attr :student_navigate, :any,
    required: true,
    doc: "function, will receive student as arg. Should return route for navigate"

  attr :staff_navigate, :any,
    required: true,
    doc: "function, will receive staff member id as arg. Should return route for navigate"

  attr :details_patch, :any,
    required: true,
    doc: "function, will receive student record as arg. Should return route for patch"

  attr :current_user_or_cycle, :any, required: true

  def students_records_list(%{show_empty_state_message: true} = assigns) do
    ~H"""
    <div class={@class}>
      <.empty_state><%= gettext("No student records found for selected filters.") %></.empty_state>
    </div>
    """
  end

  def students_records_list(assigns) do
    ~H"""
    <div id={@id} class={@class} phx-update="stream">
      <.card_base :for={{dom_id, student_record} <- @stream} id={dom_id} class="mt-4 first:mt-0">
        <div class="p-6 md:flex md:items-start md:gap-6">
          <div class="md:w-48 md:shrink-0">
            <div class="flex items-center gap-4 md:block">
              <div class="flex items-center gap-2 text-xs font-bold text-ltrn-subtle">
                <.icon name="hero-hashtag-mini" class="w-5 h-5" />
                <%= student_record.id %>
              </div>
              <div class="flex items-center gap-2 text-xs md:mt-2">
                <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
                <%= Timex.format!(student_record.date, "{Mshort} {0D}, {YYYY}") %>
              </div>
              <div :if={student_record.time} class="flex items-center gap-2 text-xs md:mt-2">
                <.icon name="hero-clock-mini" class="w-5 h-5 text-ltrn-subtle" />
                <%= student_record.time %>
              </div>
            </div>
            <div class="flex flex-wrap gap-2 w-full mt-4">
              <.status_badge status={student_record.status} class="max-w-full" />
              <.badge :for={tag <- student_record.tags} color_map={tag} class="max-w-full">
                <%= tag.name %>
              </.badge>
              <%= if is_list(student_record.students_tags) do %>
                <.badge
                  :for={student_tag <- student_record.students_tags}
                  color_map={student_tag}
                  class="max-w-full"
                >
                  <%= student_tag.name %>
                </.badge>
              <% end %>
              <.badge :for={class <- student_record.classes}>
                <%= class_with_cycle(class, @current_user_or_cycle) %>
              </.badge>
            </div>
          </div>
          <div class="mt-6 md:mt-0 md:flex-1">
            <div class="flex flex-wrap gap-1">
              <.person_badge
                :for={student <- student_record.students}
                person={student}
                theme="cyan"
                truncate
                navigate={@student_navigate.(student)}
              />
            </div>
            <.link
              :if={student_record.name}
              class="block mt-4 font-display font-black hover:text-ltrn-subtle"
              patch={@details_patch.(student_record)}
            >
              <%= student_record.name %>
            </.link>
            <.markdown text={student_record.description} class="mt-4 line-clamp-5" />
            <div
              :if={student_record.internal_notes}
              class="p-4 rounded-xs mt-4 bg-ltrn-staff-lightest"
            >
              <h6 class="mb-2 font-bold text-ltrn-staff-dark"><%= gettext("Internal notes") %></h6>
              <.markdown text={student_record.internal_notes} class="line-clamp-3" />
            </div>
            <.action
              type="link"
              icon_name="hero-arrow-up-right-mini"
              patch={@details_patch.(student_record)}
              class="mt-4"
            >
              <%= gettext("View more") %>
            </.action>
          </div>
        </div>
        <div class="px-2 pb-2">
          <div class="flex items-center justify-between gap-4 p-2 rounded-xs bg-ltrn-staff-lightest">
            <div class="md:flex items-center gap-4">
              <div class="flex items-center gap-2">
                <span class="text-xs text-ltrn-subtle"><%= gettext("Created by") %></span>
                <.person_badge
                  person={student_record.created_by_staff_member}
                  theme="staff"
                  navigate={@staff_navigate.(student_record.created_by_staff_member.id)}
                  truncate
                />
              </div>
              <div :if={student_record.assignees != []} class="flex items-center gap-2 mt-2 md:mt-0">
                <span class="text-xs text-ltrn-subtle"><%= gettext("Assigned to") %></span>
                <div class="flex flex-wrap items-center gap-2">
                  <.person_badge
                    :for={assignee <- student_record.assignees}
                    person={assignee}
                    theme="staff"
                    navigate={@staff_navigate.(assignee.id)}
                    truncate
                  />
                </div>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <div
                :if={student_record.status.is_closed && !student_record.closed_at}
                class="group relative"
              >
                <div
                  class="flex items-center justify-center p-0.5 rounded-full"
                  style={create_color_map_style(student_record.status)}
                >
                  <.icon name="hero-check-circle-mini" />
                </div>
                <.tooltip h_pos="right"><%= gettext("Closed on creation") %></.tooltip>
              </div>
              <div
                :if={student_record.status.is_closed && student_record.closed_at}
                class="group relative"
              >
                <div
                  class="flex items-center justify-center gap-1 p-0.5 rounded-full"
                  style={create_color_map_style(student_record.status)}
                >
                  <p class="pl-1">
                    <%= days_and_hours_between(student_record.inserted_at, student_record.closed_at) %>
                  </p>
                  <.icon name="hero-check-circle-mini" />
                </div>
                <.tooltip h_pos="right">
                  <%= gettext("Closed at %{datetime}",
                    datetime: format_local!(student_record.closed_at)
                  ) %>
                </.tooltip>
              </div>
              <div :if={!student_record.status.is_closed} class="group relative">
                <div
                  class="flex items-center justify-center gap-1 p-0.5 rounded-full"
                  style={create_color_map_style(student_record.status)}
                >
                  <p class="pl-1">
                    <%= days_and_hours_between(student_record.inserted_at, DateTime.utc_now()) %>
                  </p>
                  <.icon name="hero-clock-mini" />
                </div>
                <.tooltip h_pos="right"><%= gettext("Duration since creation") %></.tooltip>
              </div>
              <div :if={student_record.shared_with_school} class="group relative">
                <.icon name="hero-globe-americas" class="w-6 h-6 text-ltrn-staff-accent" />
                <.tooltip h_pos="right"><%= gettext("Visible to all school staff") %></.tooltip>
              </div>
            </div>
          </div>
        </div>
      </.card_base>
    </div>
    """
  end

  @doc """
  A specialized version of `<.badge>` component.

  Handles `color_map` and `icon_name` attributes.
  """
  attr :status, StudentRecordStatus, required: true
  attr :class, :any, default: nil

  def status_badge(assigns) do
    ~H"""
    <.badge
      color_map={@status}
      icon_name={if(@status.is_closed, do: "hero-check-circle-mini")}
      class={@class}
    >
      <%= @status.name %>
    </.badge>
    """
  end
end
