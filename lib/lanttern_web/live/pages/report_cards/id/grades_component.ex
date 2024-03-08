defmodule LantternWeb.ReportCardLive.GradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  import Lanttern.Utils, only: [swap: 3]

  # shared
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <div class="container mx-auto lg:max-w-5xl">
        <div class="p-4 rounded mt-4 bg-white shadow-lg">
          <%= if @grades_report do %>
            <h3 class="mb-4 font-display font-bold text-2xl">
              <%= gettext("Grades report grid") %>: <%= @grades_report.name %>
            </h3>
            <.grades_report_grid grades_report={@grades_report} />
          <% else %>
            <h3 class="mb-4 font-display font-bold text-2xl">
              <%= gettext("Grades report grid") %>
            </h3>
            <.empty_state>
              <%= gettext("No grades report linked to this report card.") %>
            </.empty_state>
          <% end %>
        </div>
        <p class="mt-4">
          <%= gettext("Select subjects and cycles to build the grades report grid.") %>
        </p>
        <div class="flex items-start gap-6 mt-6">
          <div class="flex-1 flex flex-wrap gap-2">
            <.badge_button
              :for={subject <- @subjects}
              theme={if subject.id in @selected_subjects_ids, do: "primary", else: "default"}
              icon_name={
                if subject.id in @selected_subjects_ids, do: "hero-check-mini", else: "hero-plus-mini"
              }
              phx-click={JS.push("toggle_subject", value: %{"id" => subject.id}, target: @myself)}
            >
              <%= subject.name %>
            </.badge_button>
          </div>
          <div class="flex-1 flex flex-wrap gap-2">
            <.badge_button
              :for={cycle <- @cycles}
              theme={if cycle.id in @selected_cycles_ids, do: "primary", else: "default"}
              icon_name={
                if cycle.id in @selected_cycles_ids, do: "hero-check-mini", else: "hero-plus-mini"
              }
              phx-click={JS.push("toggle_cycle", value: %{"id" => cycle.id}, target: @myself)}
            >
              <%= cycle.name %>
            </.badge_button>
          </div>
        </div>
        <div class="p-4 rounded mt-10 bg-white shadow-lg">
          <.grades_grid
            sortable_grades_subjects={@sortable_grades_subjects}
            grades_cycles={@grades_cycles}
            myself={@myself}
          />
        </div>
      </div>
    </div>
    """
  end

  # function components

  attr :sortable_grades_subjects, :list, required: true
  attr :grades_cycles, :list, required: true
  attr :myself, :any, required: true

  def grades_grid(assigns) do
    grid_template_columns_style =
      case length(assigns.grades_cycles) do
        n when n > 1 ->
          "grid-template-columns: 160px repeat(#{n}, minmax(0, 1fr))"

        _ ->
          "grid-template-columns: 160px minmax(0, 1fr)"
      end

    grid_column_style =
      case length(assigns.grades_cycles) do
        0 -> "grid-column: span 2 / span 2"
        n -> "grid-column: span #{n + 1} / span #{n + 1}"
      end

    assigns =
      assigns
      |> assign(:grid_template_columns_style, grid_template_columns_style)
      |> assign(:grid_column_style, grid_column_style)
      |> assign(:has_subjects, length(assigns.sortable_grades_subjects) > 0)
      |> assign(:has_cycles, length(assigns.grades_cycles) > 0)

    ~H"""
    <div class="grid gap-1 text-sm" style={@grid_template_columns_style}>
      <div></div>
      <%= if @has_cycles do %>
        <div
          :for={grade_cycle <- @grades_cycles}
          id={"grid-header-cycle-#{grade_cycle.id}"}
          class="p-4 rounded text-center bg-white shadow-lg"
        >
          <%= grade_cycle.school_cycle.name %>
        </div>
      <% else %>
        <div class="p-4 rounded text-ltrn-subtle bg-ltrn-lightest">
          <%= gettext("Use the buttons above to add cycles to this grid") %>
        </div>
      <% end %>
      <%= if @has_subjects do %>
        <div
          :for={{grade_subject, i} <- @sortable_grades_subjects}
          id={"sortable-grade-subject-#{grade_subject.id}"}
          class="grid grid-cols-subgrid"
          style={@grid_column_style}
        >
          <.sortable_card
            is_move_up_disabled={i == 0}
            on_move_up={
              JS.push("swap_grades_subjects_position",
                value: %{from: i, to: i - 1},
                target: @myself
              )
            }
            is_move_down_disabled={i + 1 == length(@sortable_grades_subjects)}
            on_move_down={
              JS.push("swap_grades_subjects_position",
                value: %{from: i, to: i + 1},
                target: @myself
              )
            }
          >
            <%= grade_subject.subject.name %>
          </.sortable_card>
          <%= if @has_cycles do %>
            <div
              :for={_grade_cycle <- @grades_cycles}
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
            <%= gettext("Use the buttons above to add subjects to this grid") %>
          </div>
          <%= if @has_cycles do %>
            <div
              :for={_grade_cycle <- @grades_cycles}
              class="rounded border border-ltrn-lighter bg-ltrn-lightest"
            >
            </div>
          <% else %>
            <div class="rounded border border-ltrn-lighter bg-ltrn-lightest"></div>
          <% end %>
        </div>
      <% end %>
      <%!-- <p>Subjects</p>
      <div :for={grade_subject <- @grades_subjects}>
        <%= grade_subject.subject.name %>
      </div>

      <p>Cycles</p>
      <div :for={grade_cycle <- @grades_cycles}>
        <%= grade_cycle.school_cycle.name %>
      </div> --%>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:subjects, Taxonomy.list_subjects())
      |> assign(:cycles, Schools.list_cycles())
      |> assign(:has_grades_subjects_order_change, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:grades_report, fn %{report_card: report_card} ->
        case report_card.grades_report_id do
          nil -> nil
          id -> Reporting.get_grades_report(id, load_grid: true)
        end
      end)
      |> assign_new(:sortable_grades_subjects, fn %{report_card: report_card} ->
        Reporting.list_report_card_grades_subjects(report_card.id)
        |> Enum.with_index()
      end)
      |> assign_new(:selected_subjects_ids, fn %{
                                                 sortable_grades_subjects:
                                                   sortable_grades_subjects
                                               } ->
        Enum.map(sortable_grades_subjects, fn {grade_subject, _i} -> grade_subject.subject.id end)
      end)
      |> assign_new(:grades_cycles, fn %{report_card: report_card} ->
        Reporting.list_report_card_grades_cycles(report_card.id)
      end)
      |> assign_new(:selected_cycles_ids, fn %{grades_cycles: grades_cycles} ->
        Enum.map(grades_cycles, & &1.school_cycle.id)
      end)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("toggle_subject", %{"id" => subject_id}, socket) do
    socket =
      case subject_id in socket.assigns.selected_subjects_ids do
        true -> remove_subject_grade_report(socket, subject_id)
        false -> add_subject_grade_report(socket, subject_id)
      end

    {:noreply, socket}
  end

  def handle_event("toggle_cycle", %{"id" => cycle_id}, socket) do
    socket =
      case cycle_id in socket.assigns.selected_cycles_ids do
        true -> remove_cycle_grade_report(socket, cycle_id)
        false -> add_cycle_grade_report(socket, cycle_id)
      end

    {:noreply, socket}
  end

  def handle_event("swap_grades_subjects_position", %{"from" => i, "to" => j}, socket) do
    sortable_grades_subjects =
      socket.assigns.sortable_grades_subjects
      |> Enum.map(fn {grade_subject, _i} -> grade_subject end)
      |> swap(i, j)
      |> Enum.with_index()

    sortable_grades_subjects
    |> Enum.map(fn {grade_subject, _i} -> grade_subject.id end)
    |> Reporting.update_report_card_grades_subjects_positions()
    |> case do
      :ok ->
        socket =
          socket
          |> assign(:sortable_grades_subjects, sortable_grades_subjects)

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  defp add_subject_grade_report(socket, subject_id) do
    %{
      report_card_id: socket.assigns.report_card.id,
      subject_id: subject_id
    }
    |> Reporting.add_subject_to_report_card_grades()
    |> case do
      {:ok, _report_card_grade_subject} ->
        push_navigate(socket, to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error adding subject to report card grades"))
    end
  end

  defp remove_subject_grade_report(socket, subject_id) do
    socket.assigns.sortable_grades_subjects
    |> Enum.map(fn {grade_subject, _i} -> grade_subject end)
    |> Enum.find(&(&1.subject_id == subject_id))
    |> Reporting.delete_report_card_grade_subject()
    |> case do
      {:ok, _report_card_grade_subject} ->
        push_navigate(socket, to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error removing subject from report card grades"))
    end
  end

  defp add_cycle_grade_report(socket, cycle_id) do
    %{
      report_card_id: socket.assigns.report_card.id,
      school_cycle_id: cycle_id
    }
    |> Reporting.add_cycle_to_report_card_grades()
    |> case do
      {:ok, _report_card_grade_cycle} ->
        push_navigate(socket, to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error adding cycle to report card grades"))
    end
  end

  defp remove_cycle_grade_report(socket, cycle_id) do
    socket.assigns.grades_cycles
    |> Enum.find(&(&1.school_cycle_id == cycle_id))
    |> Reporting.delete_report_card_grade_cycle()
    |> case do
      {:ok, _report_card_grade_cycle} ->
        push_navigate(socket, to: ~p"/report_cards/#{socket.assigns.report_card}?tab=grades")

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error removing cycle from report card grades"))
    end
  end
end
