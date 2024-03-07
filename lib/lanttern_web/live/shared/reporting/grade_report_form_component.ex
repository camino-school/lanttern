defmodule LantternWeb.Reporting.GradeReportFormComponent do
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
          label="Cycle"
          options={@cycle_options}
          prompt="Select a cycle"
          class="mb-6"
        />
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
  def update(%{grade_report: grade_report} = assigns, socket) do
    changeset = Reporting.change_grade_report(grade_report)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"grade_report" => grade_report_params}, socket) do
    changeset =
      socket.assigns.grade_report
      |> Reporting.change_grade_report(grade_report_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"grade_report" => grade_report_params}, socket) do
    save_grade_report(socket, socket.assigns.grade_report.id, grade_report_params)
  end

  defp save_grade_report(socket, nil, grade_report_params) do
    case Reporting.create_grade_report(grade_report_params) do
      {:ok, grade_report} ->
        notify_parent(__MODULE__, {:saved, grade_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Grade report created successfully")
          |> handle_navigation(grade_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_grade_report(socket, _grade_report_id, grade_report_params) do
    case Reporting.update_grade_report(socket.assigns.grade_report, grade_report_params) do
      {:ok, grade_report} ->
        notify_parent(__MODULE__, {:saved, grade_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Grade report updated successfully")
          |> handle_navigation(grade_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
