defmodule LantternWeb.GradesReports.GradesReportGridConfigurationOverlayComponent do
  @moduledoc """
  Renders a `GradesReport` configuration overlay
  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Schools
  alias Lanttern.Taxonomy
  alias Lanttern.GradesReports.GradesReportCycle

  import Lanttern.Utils, only: [swap: 3]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title>
          <%= gettext("%{grades_report} grid configuration", grades_report: @grades_report.name) %>
        </:title>
        <h5 class="mb-4 font-display font-black text-lg"><%= gettext("Grid subcycles") %></h5>
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
        <%= if @grades_report_cycles == [] do %>
          <div class="p-4 rounded mt-4 text-ltrn-subtle bg-ltrn-lighter">
            <%= gettext("No subcycles linked") %>
          </div>
        <% else %>
          <div class="grid grid-cols-[1fr_min-content_min-content] gap-2">
            <div class="grid grid-cols-subgrid col-span-3 items-center px-4 py-2 rounded mt-4 text-sm text-ltrn-subtle bg-ltrn-lighter">
              <div><%= gettext("Subcycle") %></div>
              <div class="text-center"><%= gettext("Grading weight") %></div>
              <div class="group relative text-center">
                <.icon name="hero-eye" class="w-6 h-6" />
                <.tooltip h_pos="right"><%= gettext("Visibility in grades reports") %></.tooltip>
              </div>
            </div>
            <.grades_report_cycle_form
              :for={grades_report_cycle <- @grades_report_cycles}
              id={"grades-report-cycle-#{grades_report_cycle.id}"}
              grades_report_cycle={grades_report_cycle}
              myself={@myself}
            />
          </div>
        <% end %>
        <h5 class="mt-10 font-display font-black text-lg">
          <%= gettext("Final grades visibility") %>
        </h5>
        <.card_base class="flex items-center p-4 mt-4">
          <p class="flex-1">
            <%= @grades_report.school_cycle.name %>
          </p>
          <.icon_button
            name={if @grades_report.final_is_visible, do: "hero-eye", else: "hero-eye-slash"}
            sr_text={gettext("Parent cycle visibility")}
            rounded
            theme={if @grades_report.final_is_visible, do: "primary_light", else: "ghost"}
            phx-click={JS.push("toggle_final_grades_visibility", target: @myself)}
          />
        </.card_base>
        <h5 class="mt-10 mb-6 font-display font-black text-lg"><%= gettext("Grid subjects") %></h5>
        <div class="flex-1 flex flex-wrap gap-2">
          <.badge_button
            :for={subject <- @subjects}
            theme={if subject.id in @selected_subjects_ids, do: "primary", else: "default"}
            icon_name={
              if subject.id in @selected_subjects_ids,
                do: "hero-check-mini",
                else: "hero-plus-mini"
            }
            phx-click={JS.push("toggle_subject", value: %{"id" => subject.id}, target: @myself)}
          >
            <%= subject.name %>
          </.badge_button>
        </div>
        <%= if @sortable_grades_report_subjects == [] do %>
          <div class="p-4 rounded mt-4 text-ltrn-subtle bg-ltrn-lighter">
            <%= gettext("No subjects linked") %>
          </div>
        <% else %>
          <.sortable_card
            :for={{grades_report_subject, i} <- @sortable_grades_report_subjects}
            id={"sortable-grades-report-subject-#{grades_report_subject.id}"}
            class="mt-4"
            is_move_up_disabled={i == 0}
            on_move_up={
              JS.push("swap_grades_report_subjects_position",
                value: %{from: i, to: i - 1},
                target: @myself
              )
            }
            is_move_down_disabled={i + 1 == length(@sortable_grades_report_subjects)}
            on_move_down={
              JS.push("swap_grades_report_subjects_position",
                value: %{from: i, to: i + 1},
                target: @myself
              )
            }
          >
            <%= grades_report_subject.subject.name %>
          </.sortable_card>
        <% end %>
      </.slide_over>
    </div>
    """
  end

  # function components

  attr :id, :string, required: true
  attr :grades_report_cycle, GradesReportCycle, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def grades_report_cycle_form(assigns) do
    form =
      assigns.grades_report_cycle
      |> GradesReportCycle.changeset(%{})
      |> to_form(as: "grades_report_cycle_#{assigns.grades_report_cycle.id}")

    {visibility_icon, visibility_theme} =
      if assigns.grades_report_cycle.is_visible do
        {"hero-eye", "primary_light"}
      else
        {"hero-eye-slash", "ghost"}
      end

    # we use :as option to avoid using hidden id input (which is easy to "hack")

    assigns =
      assigns
      |> assign(:form, form)
      |> assign(:visibility_icon, visibility_icon)
      |> assign(:visibility_theme, visibility_theme)

    ~H"""
    <.form
      id={@id}
      for={@form}
      class="grid grid-cols-subgrid col-span-3 items-center p-4 rounded mt-1 bg-white shadow-lg"
      phx-change={JS.push("update_grades_report_cycle_weight", target: @myself)}
    >
      <%= @grades_report_cycle.school_cycle.name %>
      <input
        type="number"
        name={@form[:weight].name}
        value={@form[:weight].value}
        step="0.01"
        min="0"
        phx-debounce="1500"
        class="w-20 rounded-sm border-none text-right text-sm bg-ltrn-lightest"
      />
      <.icon_button
        name={@visibility_icon}
        sr_text={gettext("Cycle visibility")}
        rounded
        theme={@visibility_theme}
        phx-click={
          JS.push("toggle_grades_report_cycle_visibility",
            value: %{"id" => @grades_report_cycle.id},
            target: @myself
          )
        }
      />
    </.form>
    """
  end

  # lifecycle

  @impl true
  def update(assigns, socket) do
    %{grades_report: grades_report} = assigns

    cycles =
      Schools.list_cycles()
      |> Enum.filter(&(&1.id != grades_report.school_cycle_id))

    grades_report_cycles = GradesReports.list_grades_report_cycles(grades_report.id)
    selected_cycles_ids = grades_report_cycles |> Enum.map(& &1.school_cycle_id)

    subjects = Taxonomy.list_subjects()
    grades_report_subjects = GradesReports.list_grades_report_subjects(grades_report.id)
    selected_subjects_ids = grades_report_subjects |> Enum.map(& &1.subject.id)
    sortable_grades_report_subjects = grades_report_subjects |> Enum.with_index()

    socket =
      socket
      |> assign(assigns)
      |> assign(:cycles, cycles)
      |> assign(:grades_report_cycles, grades_report_cycles)
      |> assign(:selected_cycles_ids, selected_cycles_ids)
      |> assign(:subjects, subjects)
      |> assign(:selected_subjects_ids, selected_subjects_ids)
      |> assign(:sortable_grades_report_subjects, sortable_grades_report_subjects)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("toggle_cycle", %{"id" => cycle_id}, socket) do
    socket =
      case cycle_id in socket.assigns.selected_cycles_ids do
        true -> remove_grades_report_cycle(socket, cycle_id)
        false -> add_grades_report_cycle(socket, cycle_id)
      end

    {:noreply, socket}
  end

  def handle_event("toggle_subject", %{"id" => subject_id}, socket) do
    # get grades report subjects without index
    # (both functions — add and remove — will need it)
    grades_report_subjects =
      socket.assigns.sortable_grades_report_subjects
      |> Enum.map(fn {grades_report_subject, _i} -> grades_report_subject end)

    socket =
      case subject_id in socket.assigns.selected_subjects_ids do
        true -> remove_grades_report_subject(socket, grades_report_subjects, subject_id)
        false -> add_grades_report_subject(socket, grades_report_subjects, subject_id)
      end

    {:noreply, socket}
  end

  def handle_event("swap_grades_report_subjects_position", %{"from" => i, "to" => j}, socket) do
    sortable_grades_report_subjects =
      socket.assigns.sortable_grades_report_subjects
      |> Enum.map(fn {grade_subject, _i} -> grade_subject end)
      |> swap(i, j)
      |> Enum.with_index()

    sortable_grades_report_subjects
    |> Enum.map(fn {grade_subject, _i} -> grade_subject.id end)
    |> GradesReports.update_grades_report_subjects_positions()
    |> case do
      :ok ->
        socket =
          socket
          |> assign(:sortable_grades_report_subjects, sortable_grades_report_subjects)

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  def handle_event("update_grades_report_cycle_weight", params, socket) do
    # we use :as option to avoid using hidden id input (which is easy to "hack")
    # here we need to "extract" the id from params key — which we do with reduce
    {grades_report_cycle, weight} =
      Enum.reduce(params, fn
        {"grades_report_cycle_" <> id, %{"weight" => weight_str}}, _acc ->
          grades_report_cycle =
            socket.assigns.grades_report_cycles
            |> Enum.find(&("#{&1.id}" == id))

          weight =
            case Float.parse(weight_str) do
              :error -> grades_report_cycle.weight
              {weight, _} -> weight
            end

          {grades_report_cycle, weight}

        _, acc ->
          acc
      end)

    GradesReports.update_grades_report_cycle(grades_report_cycle, %{weight: weight})
    |> case do
      {:ok, _grades_report_cycle} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, gettext("Error updating grades report cycle weight"))}
    end
  end

  def handle_event("toggle_grades_report_cycle_visibility", %{"id" => id}, socket) do
    grades_report_cycle =
      socket.assigns.grades_report_cycles
      |> Enum.find(&(&1.id == id))

    GradesReports.update_grades_report_cycle(grades_report_cycle, %{
      is_visible: !grades_report_cycle.is_visible
    })
    |> case do
      {:ok, updated_grades_report_cycle} ->
        grades_report_cycles =
          socket.assigns.grades_report_cycles
          |> Enum.map(fn
            %{id: ^id} -> updated_grades_report_cycle
            grc -> grc
          end)

        socket =
          socket
          |> assign(:grades_report_cycles, grades_report_cycles)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, gettext("Error updating grades report cycle visibility"))}
    end
  end

  def handle_event("toggle_final_grades_visibility", _params, socket) do
    GradesReports.update_grades_report(socket.assigns.grades_report, %{
      final_is_visible: !socket.assigns.grades_report.final_is_visible
    })
    |> case do
      {:ok, updated_grades_report} ->
        {:noreply, assign(socket, :grades_report, updated_grades_report)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Error updating final grades visibility"))}
    end
  end

  defp add_grades_report_cycle(socket, cycle_id) do
    %{
      grades_report_id: socket.assigns.grades_report.id,
      school_cycle_id: cycle_id
    }
    |> GradesReports.add_cycle_to_grades_report()
    |> case do
      {:ok, _grades_report_cycle} ->
        grades_report_cycles =
          GradesReports.list_grades_report_cycles(socket.assigns.grades_report.id)

        selected_cycles_ids = grades_report_cycles |> Enum.map(& &1.school_cycle_id)

        socket
        |> assign(:grades_report_cycles, grades_report_cycles)
        |> assign(:selected_cycles_ids, selected_cycles_ids)

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error adding cycle to grades report"))
    end
  end

  defp remove_grades_report_cycle(socket, cycle_id) do
    socket.assigns.grades_report_cycles
    |> Enum.find(&(&1.school_cycle_id == cycle_id))
    |> GradesReports.delete_grades_report_cycle()
    |> case do
      {:ok, _grades_report_cycle} ->
        grades_report_cycles =
          socket.assigns.grades_report_cycles
          |> Enum.filter(&(&1.school_cycle_id != cycle_id))

        selected_cycles_ids =
          socket.assigns.selected_cycles_ids
          |> Enum.filter(&(&1 != cycle_id))

        socket
        |> assign(:grades_report_cycles, grades_report_cycles)
        |> assign(:selected_cycles_ids, selected_cycles_ids)

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error removing cycle from grades report"))
    end
  end

  defp add_grades_report_subject(socket, grades_report_subjects, subject_id) do
    %{
      grades_report_id: socket.assigns.grades_report.id,
      subject_id: subject_id
    }
    |> GradesReports.add_subject_to_grades_report()
    |> case do
      {:ok, grades_report_subject} ->
        sortable_grades_report_subjects =
          (grades_report_subjects ++ [grades_report_subject])
          |> Enum.with_index()

        selected_subjects_ids =
          [grades_report_subject.subject_id | socket.assigns.selected_subjects_ids]

        socket
        |> assign(:sortable_grades_report_subjects, sortable_grades_report_subjects)
        |> assign(:selected_subjects_ids, selected_subjects_ids)

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error adding subject to grades report"))
    end
  end

  defp remove_grades_report_subject(socket, grades_report_subjects, subject_id) do
    grades_report_subjects
    |> Enum.find(&(&1.subject_id == subject_id))
    |> GradesReports.delete_grades_report_subject()
    |> case do
      {:ok, grades_report_subject} ->
        sortable_grades_report_subjects =
          grades_report_subjects
          |> Enum.filter(&(&1.id != grades_report_subject.id))
          |> Enum.with_index()

        selected_subjects_ids =
          sortable_grades_report_subjects
          |> Enum.map(fn {grs, _i} -> grs.subject_id end)

        socket
        |> assign(:sortable_grades_report_subjects, sortable_grades_report_subjects)
        |> assign(:selected_subjects_ids, selected_subjects_ids)

      {:error, _changeset} ->
        put_flash(socket, :error, gettext("Error removing subject from grades report"))
    end
  end
end
