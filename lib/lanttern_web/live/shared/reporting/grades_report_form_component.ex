defmodule LantternWeb.Reporting.GradesReportFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  alias LantternWeb.GradingHelpers
  alias LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="grade-report-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:info]}
          type="textarea"
          label={gettext("Info")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:school_cycle_id]}
          type="select"
          label="Parent cycle"
          options={@cycle_options}
          prompt="Select a cycle"
          class="mb-6"
        >
          <:description>
            <p>
              <%= gettext(
                "The parent cycle grade is calculated based on it's children cycles. E.g. 2024 grade is based on 2024 Q1, Q2, Q3, and Q4 grades."
              ) %>
            </p>
          </:description>
        </.input>
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
    cycle_options = SchoolsHelpers.generate_cycle_options()

    socket =
      socket
      |> assign(:class, nil)
      |> assign(:hide_submit, false)
      |> assign(:scale_options, scale_options)
      |> assign(:cycle_options, cycle_options)

    {:ok, socket}
  end

  @impl true
  def update(%{grades_report: grades_report} = assigns, socket) do
    changeset = Reporting.change_grades_report(grades_report)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"grades_report" => grades_report_params}, socket) do
    changeset =
      socket.assigns.grades_report
      |> Reporting.change_grades_report(grades_report_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"grades_report" => grades_report_params}, socket) do
    save_grades_report(socket, socket.assigns.grades_report.id, grades_report_params)
  end

  defp save_grades_report(socket, nil, grades_report_params) do
    case Reporting.create_grades_report(grades_report_params) do
      {:ok, grades_report} ->
        notify_parent(__MODULE__, {:saved, grades_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Grades report created successfully"))
          |> handle_navigation(grades_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_grades_report(socket, _grades_report_id, grades_report_params) do
    case Reporting.update_grades_report(socket.assigns.grades_report, grades_report_params) do
      {:ok, grades_report} ->
        notify_parent(__MODULE__, {:saved, grades_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Grades report updated successfully"))
          |> handle_navigation(grades_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
