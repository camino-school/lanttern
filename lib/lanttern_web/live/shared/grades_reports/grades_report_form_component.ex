defmodule LantternWeb.GradesReports.GradesReportFormComponent do
  @moduledoc """
  Renders a `GradesReport` form
  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  alias LantternWeb.GradingHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="grades-report-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error_block>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:info]}
          type="markdown"
          label={gettext("Info")}
          phx-debounce="1500"
          class="mb-6"
          show_optional
        />
        <div class="mb-6">
          <.label><%= gettext("Parent cycle") %></.label>
          <p class="my-2">
            <%= gettext(
              "The parent cycle grade is calculated based on it's children cycles. E.g. 2024 grade is based on 2024 Q1, Q2, Q3, and Q4 grades."
            ) %>
          </p>
          <.badge_button_picker
            id="grades-report-cycle-select"
            on_select={
              &(JS.push("select_cycle", value: %{"id" => &1}, target: @myself)
                |> JS.dispatch("change", to: "#grades-report-form"))
            }
            items={@cycles}
            selected_ids={[@selected_cycle_id]}
          />
          <div :if={@form.source.action in [:insert, :update]}>
            <.error :for={{msg, _} <- @form[:school_cycle_id].errors}><%= msg %></.error>
          </div>
        </div>
        <div class="mb-6">
          <.label><%= gettext("Year") %></.label>
          <.badge_button_picker
            id="grades-report-year-select"
            on_select={
              &(JS.push("select_year", value: %{"id" => &1}, target: @myself)
                |> JS.dispatch("change", to: "#class-form"))
            }
            items={@years}
            selected_ids={[@selected_year_id]}
          />
          <div :if={@form.source.action in [:insert, :update]}>
            <.error :for={{msg, _} <- @form[:year_id].errors}><%= msg %></.error>
          </div>
        </div>
        <.input
          field={@form[:scale_id]}
          type="select"
          label="Scale"
          options={@scale_options}
          prompt="Select a scale"
          class={if !@hide_submit, do: "mb-6"}
        />
        <.button :if={!@hide_submit} phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save grade report") %>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    scale_options = GradingHelpers.generate_scale_options()

    socket =
      socket
      |> assign(:class, nil)
      |> assign(:hide_submit, false)
      |> assign(:scale_options, scale_options)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_cycles()
    |> assign_years()
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_cycles(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    cycles = Schools.list_cycles(schools_ids: [school_id], parent_cycles_only: true)
    assign(socket, :cycles, cycles)
  end

  defp assign_years(socket) do
    years = Taxonomy.list_years()
    assign(socket, :years, years)
  end

  defp assign_form(socket) do
    grades_report = socket.assigns.grades_report
    changeset = GradesReports.change_grades_report(grades_report)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_cycle_id, grades_report.school_cycle_id)
    |> assign(:selected_year_id, grades_report.year_id)
  end

  @impl true
  def handle_event("select_cycle", %{"id" => id}, socket) do
    selected_cycle_id =
      if socket.assigns.selected_cycle_id == id, do: nil, else: id

    socket =
      socket
      |> assign(:selected_cycle_id, selected_cycle_id)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_year", %{"id" => id}, socket) do
    selected_year_id =
      if socket.assigns.selected_year_id == id, do: nil, else: id

    socket =
      socket
      |> assign(:selected_year_id, selected_year_id)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("validate", %{"grades_report" => grades_report_params}, socket),
    do: {:noreply, assign_validated_form(socket, grades_report_params)}

  def handle_event("save", %{"grades_report" => grades_report_params}, socket) do
    grades_report_params = inject_extra_params(socket, grades_report_params)
    save_grades_report(socket, socket.assigns.grades_report.id, grades_report_params)
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.grades_report
      |> GradesReports.change_grades_report(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_cycle_id", socket.assigns.selected_cycle_id)
    |> Map.put("year_id", socket.assigns.selected_year_id)
  end

  defp save_grades_report(socket, nil, grades_report_params) do
    case GradesReports.create_grades_report(grades_report_params) do
      {:ok, grades_report} ->
        notify_parent(__MODULE__, {:saved, grades_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Grades report created successfully"))
          |> handle_navigation(grades_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_grades_report(socket, _grades_report_id, grades_report_params) do
    case GradesReports.update_grades_report(socket.assigns.grades_report, grades_report_params) do
      {:ok, grades_report} ->
        notify_parent(__MODULE__, {:saved, grades_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Grades report updated successfully"))
          |> handle_navigation(grades_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
