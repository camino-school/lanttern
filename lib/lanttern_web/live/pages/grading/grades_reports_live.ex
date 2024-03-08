defmodule LantternWeb.GradesReportsLive do
  use LantternWeb, :live_view

  alias Lanttern.Reporting
  alias Lanttern.Reporting.GradesReport

  # local view components
  alias LantternWeb.ReportCardLive.GradesReportGridSetupOverlayComponent

  # live components
  alias LantternWeb.Reporting.GradesReportFormComponent

  # shared
  import LantternWeb.GradingComponents

  # function components

  attr :grades_report_id, :integer, required: true
  attr :grades_report_subjects, :list, required: true
  attr :grades_report_cycles, :list, required: true

  def grades_report_grid(assigns) do
    grid_template_columns_style =
      case length(assigns.grades_report_cycles) do
        n when n > 1 ->
          "grid-template-columns: 160px repeat(#{n}, minmax(0, 1fr))"

        _ ->
          "grid-template-columns: 160px minmax(0, 1fr)"
      end

    grid_column_style =
      case length(assigns.grades_report_cycles) do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:has_subjects, length(assigns.grades_report_subjects) > 0)
      |> assign(:has_cycles, length(assigns.grades_report_cycles) > 0)

    ~H"""
    <div class="grid gap-1 text-sm" style={@grid_template_columns_style}>
      <.button
        type="button"
        theme="ghost"
        icon_name="hero-cog-6-tooth-mini"
        phx-click={JS.patch(~p"/grading?is_editing_grid=#{@grades_report_id}")}
      >
        <%= gettext("Setup") %>
      </.button>
      <%= if @has_cycles do %>
        <div
          :for={grades_report_cycle <- @grades_report_cycles}
          id={"grid-header-cycle-#{grades_report_cycle.id}"}
          class="p-4 rounded text-center bg-white shadow-lg"
        >
          <%= grades_report_cycle.school_cycle.name %>
        </div>
      <% else %>
        <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
          <%= gettext("No cycles linked to this grades report") %>
        </div>
      <% end %>
      <%= if @has_subjects do %>
        <div
          :for={grades_report_subject <- @grades_report_subjects}
          id={"grade-report-subject-#{grades_report_subject.id}"}
          class="grid grid-cols-subgrid"
          style={@grid_column_style}
        >
          <div class="p-4 rounded bg-white shadow-lg">
            <%= grades_report_subject.subject.name %>
          </div>
          <%= if @has_cycles do %>
            <div
              :for={_grade_cycle <- @grades_report_cycles}
              class="rounded border border-ltrn-lighter bg-ltrn-lightest"
            >
            </div>
          <% else %>
            <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
          <% end %>
        </div>
      <% else %>
        <div class="grid grid-cols-subgrid" style={@grid_column_style}>
          <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
            <%= gettext("No subjects linked to this grades report") %>
          </div>
          <%= if @has_cycles do %>
            <div
              :for={_grade_cycle <- @grades_report_cycles}
              class="rounded border border-ltrn-lighter bg-ltrn-lightest"
            >
            </div>
          <% else %>
            <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def handle_params(params, _uri, socket) do
    grades_reports =
      Reporting.list_grades_reports(preloads: [:school_cycle, [scale: :ordinal_values]])

    socket =
      socket
      |> stream(:grades_reports, grades_reports)
      |> assign(:has_grades_reports, length(grades_reports) > 0)
      |> assign_show_grades_report_form(params)
      |> assign_show_grades_report_grid_editor(params)

    {:noreply, socket}
  end

  defp assign_show_grades_report_form(socket, %{"is_creating" => "true"}) do
    socket
    |> assign(:grades_report, %GradesReport{})
    |> assign(:form_overlay_title, gettext("Create grade report"))
    |> assign(:show_grades_report_form, true)
  end

  defp assign_show_grades_report_form(socket, %{"is_editing" => id}) do
    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case Reporting.get_grades_report(id) do
          %GradesReport{} = grades_report ->
            socket
            |> assign(:form_overlay_title, gettext("Edit grade report"))
            |> assign(:grades_report, grades_report)
            |> assign(:show_grades_report_form, true)

          _ ->
            assign(socket, :show_grades_report_form, false)
        end

      true ->
        assign(socket, :show_grades_report_form, false)
    end
  end

  defp assign_show_grades_report_form(socket, _),
    do: assign(socket, :show_grades_report_form, false)

  defp assign_show_grades_report_grid_editor(socket, %{"is_editing_grid" => id}) do
    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case Reporting.get_grades_report(id) do
          %GradesReport{} = grades_report ->
            socket
            # |> assign(:form_overlay_title, gettext("Edit grade report"))
            |> assign(:grades_report, grades_report)
            |> assign(:show_grades_report_grid_editor, true)

          _ ->
            assign(socket, :show_grades_report_grid_editor, false)
        end

      true ->
        assign(socket, :show_grades_report_grid_editor, false)
    end
  end

  defp assign_show_grades_report_grid_editor(socket, _),
    do: assign(socket, :show_grades_report_grid_editor, false)

  # event handlers

  @impl true
  def handle_event("delete_grades_report", _params, socket) do
    case Reporting.delete_grades_report(socket.assigns.grades_report) do
      {:ok, _grades_report} ->
        socket =
          socket
          |> put_flash(:info, gettext("Grade report deleted"))
          |> push_navigate(to: ~p"/grading")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting grade report"))

        {:noreply, socket}
    end
  end
end
